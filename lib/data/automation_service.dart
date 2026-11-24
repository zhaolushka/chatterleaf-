import 'dart:async';

import '../logic/status.dart';
import 'data.dart';

/// M4: automatic mode. Watches the user's beds; for beds in "auto" mode it
/// switches devices by itself using the thresholds from settings (M7):
///   soil < soilMin            → watering on for irrigationMinutes
///   temperature > tempMax     → window open;  back to normal → close
///   temperature < tempMin     → heater on;    back to normal → off
///   daytime and too dark      → light on (by schedule)
/// It runs inside the app, so it also reacts to values changed by hand in the database console.
class AutomationService {
  AutomationService(this.uid);
  final String uid;

  StreamSubscription<List<Greenhouse>>? _bedsSub;
  final Map<String, StreamSubscription<List<Device>>> _deviceSubs = {};
  final Map<String, Map<String, Device>> _devices = {};
  final Map<String, Timer> _wateringTimers = {};
  final Set<String> _pending = {}; // "bedId/deviceId" commands in flight

  void start() {
    _bedsSub = greenhouseRepository.watchMyGreenhouses(uid).listen(_onBeds);
  }

  void dispose() {
    _bedsSub?.cancel();
    for (final s in _deviceSubs.values) {
      s.cancel();
    }
    for (final t in _wateringTimers.values) {
      t.cancel();
    }
  }

  void _onBeds(List<Greenhouse> beds) {
    for (final b in beds) {
      _deviceSubs.putIfAbsent(
        b.id,
        () => greenhouseRepository.watchDevices(b.id).listen((list) => _devices[b.id] = {for (final d in list) d.id: d}),
      );
      if (b.isAuto && !isStale(b.current)) _apply(b);
    }
  }

  bool _isOn(String bedId, String deviceId) => _devices[bedId]?[deviceId]?.isOn ?? false;
  String _by(String bedId, String deviceId) => _devices[bedId]?[deviceId]?.changedBy ?? 'user';

  Future<void> _set(String bedId, String deviceId, bool on, {String by = 'auto'}) async {
    final key = '$bedId/$deviceId';
    if (_pending.contains(key) || _devices[bedId] == null || _isOn(bedId, deviceId) == on) return;
    _pending.add(key);
    try {
      await greenhouseRepository.setDevice(bedId, deviceId, on, by: by, byName: 'Auto mode');
    } finally {
      _pending.remove(key);
    }
  }

  void _apply(Greenhouse b) {
    final r = b.current, s = b.settings;

    // Watering: on when the soil is dry, off after irrigationMinutes or when wet enough.
    if (r.soilMoisture < s.soilMin && !_isOn(b.id, 'irrigation')) {
      _set(b.id, 'irrigation', true);
      _wateringTimers[b.id]?.cancel();
      _wateringTimers[b.id] = Timer(Duration(minutes: s.irrigationMinutes), () => _set(b.id, 'irrigation', false));
    } else if (_isOn(b.id, 'irrigation') && _by(b.id, 'irrigation') == 'auto' && r.soilMoisture >= s.soilMin + 30) {
      _wateringTimers[b.id]?.cancel();
      _set(b.id, 'irrigation', false);
    }

    // Window: open when hot, close when 2 °C below the limit (only if automation opened it).
    if (r.airTemp > s.tempMax) {
      _set(b.id, 'window', true);
    } else if (r.airTemp < s.tempMax - 2 && _isOn(b.id, 'window') && _by(b.id, 'window') == 'auto') {
      _set(b.id, 'window', false);
    }

    // Heater: on when cold, off when 2 °C above the minimum.
    if (r.airTemp < s.tempMin) {
      _set(b.id, 'heater', true);
    } else if (r.airTemp > s.tempMin + 2 && _isOn(b.id, 'heater') && _by(b.id, 'heater') == 'auto') {
      _set(b.id, 'heater', false);
    }

    // Light schedule: on between lightOnAt and lightOffAt when it is too dark.
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    int parse(String hhmm) => int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3, 5));
    final inSchedule = minutes >= parse(s.lightOnAt) && minutes < parse(s.lightOffAt);
    if (inSchedule && r.light < s.lightMin) {
      _set(b.id, 'light', true, by: 'schedule');
    } else if (!inSchedule && _isOn(b.id, 'light') && _by(b.id, 'light') == 'schedule') {
      _set(b.id, 'light', false, by: 'schedule');
    }
  }
}
