import 'dart:async';
import 'dart:math';

import 'models.dart';
import 'repositories.dart';
import 'sim_model.dart';

// ---------------------------------------------------------------------------
// DEMO MODE: an in-memory database + a tiny greenhouse simulator.
// The app runs out of the box (no Firebase project, no keys).
// Start with --dart-define=USE_FIREBASE=true to use the real Firebase instead.
// ---------------------------------------------------------------------------

/// Demo accounts (test values for this app only).
const demoAccounts = {
  'aigul@tamyr.app': ('teacher-12', 'Aigul Nurlanovna'),
  'school5@tamyr.app': ('school-5', 'School No. 5'),
};
const demoPassword = 'password123';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() => Stream<AppUser?>.multi((c) {
        c.add(_user);
        final sub = _controller.stream.listen(c.add);
        c.onCancel = sub.cancel;
      });

  @override
  Future<void> signIn(String email, String password) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || password.isEmpty) throw const AuthFailure('Enter your email and password');
    if (!e.contains('@')) throw const AuthFailure('That email doesn’t look right');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final account = demoAccounts[e];
    if (account == null || password != demoPassword) throw const AuthFailure('Wrong email or password');
    _user = AppUser(uid: account.$1, email: e, displayName: account.$2);
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}

class _AlertRow {
  final String uid;
  AlertItem item;
  _AlertRow(this.uid, this.item);
}

class MockGreenhouseRepository implements GreenhouseRepository {
  MockGreenhouseRepository(this._connectivity) {
    reset();
    _timer = Timer.periodic(tick, (_) => _tick());
    _connectivity.addListener(_onConnectivity);
  }

  /// How often the demo simulator writes new readings.
  static const tick = Duration(seconds: 5);

  final ConnectivityService _connectivity;
  final _changes = StreamController<void>.broadcast();
  final _rnd = Random(7);
  late final Timer _timer;
  int _ticks = 0;

  final Map<String, Greenhouse> _beds = {};
  final Map<String, Map<String, Device>> _devices = {};
  final Map<String, List<HistoryPoint>> _history = {};
  final Map<String, List<DeviceEvent>> _events = {};
  final List<_AlertRow> _alerts = [];
  final List<void Function()> _pendingOffline = [];
  int _nextId = 1;

  void dispose() {
    _timer.cancel();
    _connectivity.removeListener(_onConnectivity);
    _changes.close();
  }

  void _notify() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) => Stream<T>.multi((c) {
        c.add(read());
        final sub = _changes.stream.listen((_) => c.add(read()));
        c.onCancel = sub.cancel;
      });

  // ---------------- seed data ----------------

  /// Recreates all demo data: 4 beds of School No. 12 and 1 bed of School No. 5.
  void reset() {
    _beds.clear();
    _devices.clear();
    _history.clear();
    _events.clear();
    _alerts.clear();
    final now = DateTime.now();
    DateTime at(int daysAgo, double hour) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
      return day.add(Duration(minutes: (hour * 60).round()));
    }

    bool inside(DateTime t, DateTime a, DateTime b) => !t.isBefore(a) && !t.isAfter(b);
    final heatA = at(1, 13.5), heatB = at(1, 15.5);
    final coldA = at(2, 2), coldB = at(2, 5.5);
    final dryA = at(4, 9), dryB = at(3, 7.5);

    void bed({
      required String id,
      required String owner,
      required String name,
      required String plant,
      required String crop,
      required String personality,
      required String place,
      required String mode,
      required GreenhouseSettings settings,
      required DayProfile profile,
      SimReading Function(DateTime, SimReading)? scenario,
      double? soilNow,
    }) {
      final pts = <HistoryPoint>[];
      final start = now.subtract(const Duration(days: 7));
      for (var t = start; !t.isAfter(now); t = t.add(const Duration(minutes: 30))) {
        var r = normalReading(t, profile, _rnd);
        if (scenario != null) r = scenario(t, r);
        pts.add(HistoryPoint(ts: t, airTemp: r.airTemp, airHumidity: r.airHumidity, soilMoisture: r.soilMoisture, light: r.light));
      }
      _history[id] = pts;
      final cur = normalReading(now, profile, _rnd);
      _beds[id] = Greenhouse(
        id: id,
        ownerId: owner,
        name: name,
        plantName: plant,
        cropKey: crop,
        personality: personality,
        place: place,
        mode: mode,
        current: Readings(
          airTemp: cur.airTemp,
          airHumidity: cur.airHumidity,
          soilMoisture: soilNow ?? cur.soilMoisture,
          light: cur.light,
          updatedAt: now,
        ),
        settings: settings,
      );
      _devices[id] = {
        'irrigation': Device(id: 'irrigation', name: 'Watering', isOn: false, changedBy: 'user', changedAt: at(0, 7.6), order: 0),
        'window': Device(id: 'window', name: 'Window', isOn: false, changedBy: 'user', changedAt: at(1, 18), order: 1),
        'light': Device(id: 'light', name: 'Light', isOn: false, changedBy: 'schedule', changedAt: at(0, 6), order: 2),
        'heater': Device(id: 'heater', name: 'Heater', isOn: false, changedBy: 'auto', changedAt: at(1, 5), order: 3),
      };
      const students = ['Dana (7B)', 'Arman (8A)', 'Miras (7A)', 'Aisha (8B)'];
      final ev = <DeviceEvent>[];
      var k = 0;
      for (final day in [2, 1, 0]) {
        for (final hour in [7.5, 14.0]) {
          final on = at(day, hour);
          if (on.isAfter(now)) continue;
          final who = students[(k++ + id.length) % students.length];
          ev.add(DeviceEvent(ts: on, deviceId: 'irrigation', isOn: true, by: 'user', byName: who));
          ev.add(DeviceEvent(ts: on.add(const Duration(minutes: 2)), deviceId: 'irrigation', isOn: false, by: 'user', byName: who));
        }
      }
      ev.sort((a, b) => b.ts!.compareTo(a.ts!));
      _events[id] = ev;
    }

    const school12 = 'School No. 12, Kyzylorda';
    bed(
      id: 'school12-bed1', owner: 'teacher-12', name: 'Bed 1', plant: 'Tomi', crop: 'tomato', personality: 'cheerful',
      place: school12, mode: 'manual',
      settings: const GreenhouseSettings(tempMin: 16, tempMax: 30, humidityMin: 50, humidityMax: 75, soilMin: 35),
      profile: const DayProfile(22, 5, 62),
      scenario: (t, r) => inside(t, heatA, heatB) ? SimReading(round1(43 + _rnd.nextDouble() * 2.5), 35, r.soilMoisture, r.light) : r,
    );
    bed(
      id: 'school12-bed2', owner: 'teacher-12', name: 'Bed 2', plant: 'Cuke', crop: 'cucumber', personality: 'grumpy',
      place: school12, mode: 'manual',
      settings: const GreenhouseSettings(tempMin: 18, tempMax: 32, humidityMin: 70, humidityMax: 92, soilMin: 40),
      profile: const DayProfile(25, 4, 80),
      scenario: (t, r) {
        if (!inside(t, dryA, dryB)) return r;
        final hours = t.difference(dryA).inMinutes / 60;
        return SimReading(r.airTemp, r.airHumidity, round1(max(14.5, 50 - 1.6 * hours)), r.light);
      },
      soilNow: 24,
    );
    bed(
      id: 'school12-bed3', owner: 'teacher-12', name: 'Bed 3', plant: 'Berry', crop: 'strawberry', personality: 'gentle',
      place: school12, mode: 'manual',
      settings: const GreenhouseSettings(tempMin: 12, tempMax: 27, humidityMin: 60, humidityMax: 80, soilMin: 30),
      profile: const DayProfile(20, 4, 70),
      scenario: (t, r) => inside(t, coldA, coldB) ? SimReading(round1(7 + _rnd.nextDouble() * 2), r.airHumidity, r.soilMoisture, r.light) : r,
    );
    bed(
      id: 'school12-bed4', owner: 'teacher-12', name: 'Bed 4', plant: 'Dilly', crop: 'greens', personality: 'joker',
      place: school12, mode: 'auto',
      settings: const GreenhouseSettings(tempMin: 10, tempMax: 25, humidityMin: 55, humidityMax: 85, soilMin: 35),
      profile: const DayProfile(18, 4, 68),
    );
    bed(
      id: 'school5-bed1', owner: 'school-5', name: 'Bed 1', plant: 'Sprout', crop: 'greens', personality: 'cheerful',
      place: 'School No. 5, Aralsk', mode: 'manual',
      settings: const GreenhouseSettings(tempMin: 10, tempMax: 25, soilMin: 35),
      profile: const DayProfile(18, 4, 68),
    );

    void alert(String bedId, String param, double value, String msg, DateTime ts, bool read) {
      final b = _beds[bedId]!;
      _alerts.add(_AlertRow(
          'teacher-12',
          AlertItem(
              id: 'a${_nextId++}', greenhouseId: bedId, plantName: b.plantName, cropKey: b.cropKey,
              param: param, value: value, message: msg, ts: ts, read: read)));
    }

    alert('school12-bed1', 'airTemp', 45.2, 'I was overheating — 45.2 °C! Open the window next time!', at(1, 14.6), true);
    alert('school12-bed3', 'airTemp', 7.8, 'I’m cold, 7.8 °C… Please turn on the heater.', at(2, 3.5), true);
    alert('school12-bed2', 'soilMoisture', 15, 'Ugh, drought again — soil at 15 %!', at(3, 6), false);
    _notify();
  }

  // ---------------- demo controls (Settings → Demo tools) ----------------

  void demoHeatWave(String id) => _patch(id, (r) => r.copyWith(airTemp: 45));
  void demoDrySoil(String id) => _patch(id, (r) => r.copyWith(soilMoisture: 18));

  void _patch(String id, Readings Function(Readings) change) {
    final b = _beds[id];
    if (b == null) return;
    _beds[id] = b.copyWith(current: change(b.current).copyWith(updatedAt: DateTime.now()));
    _notify();
  }

  // ---------------- simulator tick ----------------

  void _onConnectivity() {
    if (_connectivity.online && _pendingOffline.isNotEmpty) {
      for (final f in List.of(_pendingOffline)) {
        f();
      }
      _pendingOffline.clear();
    }
    _notify();
  }

  void _tick() {
    if (!_connectivity.online) return; // no new data while "offline"
    final now = DateTime.now();
    _ticks++;
    for (final id in _beds.keys.toList()) {
      final b = _beds[id]!;
      final s = b.settings;
      final target = normalReading(now, DayProfile.fromRange(s.tempMin, s.tempMax, s.humidityMin, s.humidityMax), _rnd);
      final dev = _devices[id]!;
      final c = b.current;
      // Drift slowly back to a normal day, then apply devices (watering → soil rises).
      var t = c.airTemp + (target.airTemp - c.airTemp) * 0.02;
      var h = c.airHumidity + (target.airHumidity - c.airHumidity) * 0.02;
      var soil = c.soilMoisture - 0.03;
      var light = target.light;
      if (dev['irrigation']!.isOn) soil += 3;
      if (dev['window']!.isOn) {
        t -= 0.8;
        h -= 1.5;
      }
      if (dev['heater']!.isOn) {
        t += 0.7;
        h -= 0.5;
      }
      if (dev['light']!.isOn) light = max(light, 15000.0);
      final next = Readings(
        airTemp: round1(clampD(t, -20, 60)),
        airHumidity: round1(clampD(h, 5, 100)),
        soilMoisture: round1(clampD(soil, 0, 95)),
        light: light.roundToDouble(),
        updatedAt: now,
      );
      _beds[id] = b.copyWith(current: next);
      // A history point every 2 minutes of demo time keeps charts alive.
      if (_ticks % 24 == 0) {
        _history[id]!.add(HistoryPoint(
            ts: now, airTemp: next.airTemp, airHumidity: next.airHumidity, soilMoisture: next.soilMoisture, light: next.light));
      }
    }
    _notify();
  }

  // ---------------- GreenhouseRepository ----------------

  @override
  Stream<List<Greenhouse>> watchMyGreenhouses(String uid) => _watch(() {
        final list = _beds.values.where((b) => b.ownerId == uid).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      });

  @override
  Stream<Greenhouse?> watchGreenhouse(String id) => _watch(() => _beds[id]);

  @override
  Stream<List<Device>> watchDevices(String greenhouseId) => _watch(() {
        final list = (_devices[greenhouseId]?.values.toList() ?? <Device>[]);
        list.sort((a, b) => a.order.compareTo(b.order));
        return list;
      });

  @override
  Stream<List<HistoryPoint>> watchHistory(String greenhouseId, Duration period) => _watch(() {
        final from = DateTime.now().subtract(period);
        return (_history[greenhouseId] ?? const <HistoryPoint>[]).where((p) => p.ts.isAfter(from)).toList();
      });

  @override
  Stream<List<DeviceEvent>> watchEvents(String greenhouseId, {int limit = 50}) =>
      _watch(() => (_events[greenhouseId] ?? const <DeviceEvent>[]).take(limit).toList());

  @override
  Stream<List<AlertItem>> watchAlerts(String uid) => _watch(() {
        final list = _alerts.where((a) => a.uid == uid).map((a) => a.item).toList();
        list.sort((a, b) => (b.ts ?? DateTime(0)).compareTo(a.ts ?? DateTime(0)));
        return list;
      });

  @override
  Future<CommandResult> setDevice(String greenhouseId, String deviceId, bool isOn,
      {String by = 'user', String byName = ''}) async {
    void apply() {
      final d = _devices[greenhouseId]?[deviceId];
      if (d == null) return;
      final now = DateTime.now();
      _devices[greenhouseId]![deviceId] = d.copyWith(isOn: isOn, changedBy: by, changedAt: now);
      _events[greenhouseId]!.insert(0, DeviceEvent(ts: now, deviceId: deviceId, isOn: isOn, by: by, byName: byName));
      _notify();
    }

    if (!_connectivity.online) {
      _pendingOffline.add(apply);
      return CommandResult.queuedOffline;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250)); // feels like a network call
    apply();
    return CommandResult.sent;
  }

  @override
  Future<void> setMode(String greenhouseId, String mode) async {
    final b = _beds[greenhouseId];
    if (b == null) return;
    _beds[greenhouseId] = b.copyWith(mode: mode);
    _notify();
  }

  @override
  Future<void> updateSettings(String greenhouseId, GreenhouseSettings settings) async {
    final error = settings.validate();
    if (error != null) throw ArgumentError(error);
    final b = _beds[greenhouseId];
    if (b == null) return;
    _beds[greenhouseId] = b.copyWith(settings: settings);
    _notify();
  }

  @override
  Future<void> addAlert({
    required String uid,
    required Greenhouse greenhouse,
    required String param,
    required double value,
    required String message,
  }) async {
    _alerts.add(_AlertRow(
        uid,
        AlertItem(
            id: 'a${_nextId++}', greenhouseId: greenhouse.id, plantName: greenhouse.plantName,
            cropKey: greenhouse.cropKey, param: param, value: value, message: message,
            ts: DateTime.now(), read: false)));
    _notify();
  }

  @override
  Future<void> markAlertRead(String alertId) async {
    for (final a in _alerts) {
      if (a.item.id == alertId) a.item = _withRead(a.item);
    }
    _notify();
  }

  @override
  Future<void> markAllAlertsRead(String uid) async {
    for (final a in _alerts) {
      if (a.uid == uid) a.item = _withRead(a.item);
    }
    _notify();
  }

  AlertItem _withRead(AlertItem i) => AlertItem(
      id: i.id, greenhouseId: i.greenhouseId, plantName: i.plantName, cropKey: i.cropKey,
      param: i.param, value: i.value, message: i.message, ts: i.ts, read: true);
}
