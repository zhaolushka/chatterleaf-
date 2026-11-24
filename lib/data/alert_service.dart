import 'dart:async';

import '../logic/plant_talk.dart';
import '../logic/status.dart';
import 'data.dart';

/// M5: alerts. When a value leaves its allowed range, the plant writes an alert
/// in its own voice. The same problem is not repeated more often than every 30 minutes.
/// The app shell shows new alerts as an in-app banner (see HomeShell).
class AlertService {
  AlertService(this.uid);
  final String uid;

  static const repeatAfter = Duration(minutes: 30);

  StreamSubscription<List<Greenhouse>>? _sub;
  final Map<String, DateTime> _lastSent = {}; // "bedId/param" → time

  void start() {
    _sub = greenhouseRepository.watchMyGreenhouses(uid).listen(_check);
  }

  void dispose() => _sub?.cancel();

  void _check(List<Greenhouse> beds) {
    if (!connectivity.online) return;
    final now = DateTime.now();
    for (final b in beds) {
      if (isStale(b.current)) continue;
      for (final p in findProblems(b.current, b.settings)) {
        if (p.param == 'light' || p.param == 'airHumidity') continue; // only the important ones
        final key = '${b.id}/${p.param}';
        final last = _lastSent[key];
        if (last != null && now.difference(last) < repeatAfter) continue;
        _lastSent[key] = now;
        final value = p.param == 'airTemp' ? b.current.airTemp : b.current.soilMoisture;
        greenhouseRepository.addAlert(
          uid: uid,
          greenhouse: b,
          param: p.param,
          value: value,
          message: PlantTalk(greenhouse: b).alertLine(p),
        );
      }
    }
  }
}
