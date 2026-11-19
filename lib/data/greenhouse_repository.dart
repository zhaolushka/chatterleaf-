import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/alert.dart';
import '../models/chat_message.dart';
import '../models/device.dart';
import '../models/greenhouse.dart';
import '../models/greenhouse_settings.dart';
import '../models/history_point.dart';
import '../models/readings.dart';
// Persona comes via greenhouse.dart (public field type).
import '../models/user_profile.dart';
import 'alert_service.dart';
import 'auth_service.dart';
import 'automation_service.dart';
import 'connectivity_service.dart';
import 'mock/mock_firestore.dart';
import 'persona_engine.dart';

/// Single data entry point for screens. Firebase / mock lives only here.
class GreenhouseRepository extends ChangeNotifier {
  GreenhouseRepository({
    required AuthService auth,
    required ConnectivityService connectivity,
    this.useMock = true,
  })  : _auth = auth,
        _connectivity = connectivity {
    // ignore: prefer_initializing_formals — keep named params for clarity
    _auth.authStateChanges.listen((user) async {
      if (user == null) {
        _profile = null;
        _greenhouseId = null;
        notifyListeners();
        return;
      }
      await _ensureGreenhouseFor(user);
      notifyListeners();
    });
  }

  final AuthService _auth;
  final ConnectivityService _connectivity;
  final bool useMock;
  final MockFirestore _db = MockFirestore.instance;
  final _uuid = const Uuid();
  final _persona = const PersonaEngine();
  final _automation = const AutomationService();
  final _alerts = AlertService();

  UserProfile? _profile;
  String? _greenhouseId;

  UserProfile? get profile => _profile;
  String? get greenhouseId => _greenhouseId;
  bool get isOffline => !_connectivity.isOnline;

  void _requireOnline() {
    if (!_connectivity.isOnline) {
      throw StateError('No connection. Changes will sync when you are back online.');
    }
  }

  Future<void> _ensureGreenhouseFor(AuthUser user) async {
    final profile = await _auth.loadProfile(user.uid);
    if (profile == null) return;
    _profile = profile;
    _greenhouseId = profile.greenhouseId;
    final path = 'greenhouses/${profile.greenhouseId}';
    if (_db.getDoc(path) == null) {
      await _bootstrapGreenhouse(profile);
    }
  }

  Future<void> _bootstrapGreenhouse(UserProfile profile) async {
    final gid = profile.greenhouseId;
    final now = DateTime.now();
    _db.setDoc('greenhouses/$gid', {
      'ownerUid': profile.uid,
      'name': "${profile.name}'s Greenhouse",
      'mode': 'manual',
      'persona': Persona.tomatoDramaQueen.id,
    });
    _db.setDoc('greenhouses/$gid/current', Readings.demoHealthy().toMap());
    _db.setDoc(
      'greenhouses/$gid/settings',
      GreenhouseSettings.defaults().toMap(),
    );
    for (final d in Device.defaults()) {
      _db.setDoc('greenhouses/$gid/devices/${d.id}', d.toMap());
    }
    final greet = _persona.greeting(Persona.tomatoDramaQueen);
    _db.setDoc('greenhouses/$gid/chat/${_uuid.v4()}', {
      'ts': now.toIso8601String(),
      'text': greet,
      'fromPlant': true,
    });
  }

  // --- Streams (screens use StreamBuilder) ---

  Stream<Greenhouse?> watchGreenhouse() {
    final gid = _greenhouseId;
    if (gid == null) return Stream.value(null);
    return _db.watchDoc('greenhouses/$gid').map((data) {
      if (data == null) return null;
      return Greenhouse.fromMap(gid, data);
    });
  }

  Stream<Readings?> watchReadings() {
    final gid = _greenhouseId;
    if (gid == null) return Stream.value(null);
    return _db.watchDoc('greenhouses/$gid/current').map((data) {
      if (data == null) return null;
      return Readings.fromMap(data);
    });
  }

  Stream<GreenhouseSettings?> watchSettings() {
    final gid = _greenhouseId;
    if (gid == null) return Stream.value(null);
    return _db.watchDoc('greenhouses/$gid/settings').map((data) {
      if (data == null) return null;
      return GreenhouseSettings.fromMap(data);
    });
  }

  Stream<List<Device>> watchDevices() {
    final gid = _greenhouseId;
    if (gid == null) return Stream.value(const []);
    return _db.watchCollection('greenhouses/$gid/devices').map((map) {
      final list = map.entries.map((e) => Device.fromMap(e.key, e.value)).toList();
      list.sort((a, b) => a.id.compareTo(b.id));
      return list;
    });
  }

  Stream<List<AlertItem>> watchAlerts() {
    final gid = _greenhouseId;
    if (gid == null) return Stream.value(const []);
    return _db.watchCollection('greenhouses/$gid/alerts').map((map) {
      final list =
          map.entries.map((e) => AlertItem.fromMap(e.key, e.value)).toList();
      list.sort((a, b) => b.ts.compareTo(a.ts));
      return list;
    });
  }

  Stream<List<ChatMessage>> watchChat() {
    final gid = _greenhouseId;
    if (gid == null) return Stream.value(const []);
    return _db.watchCollection('greenhouses/$gid/chat').map((map) {
      final list =
          map.entries.map((e) => ChatMessage.fromMap(e.key, e.value)).toList();
      list.sort((a, b) => a.ts.compareTo(b.ts));
      return list;
    });
  }

  Stream<List<HistoryPoint>> watchHistory({required Duration window}) {
    final gid = _greenhouseId;
    if (gid == null) return Stream.value(const []);
    final since = DateTime.now().subtract(window);
    return _db.watchCollection('greenhouses/$gid/history').map((map) {
      final list =
          map.entries.map((e) => HistoryPoint.fromMap(e.key, e.value)).toList();
      final filtered = list.where((p) => p.ts.isAfter(since)).toList()
        ..sort((a, b) => a.ts.compareTo(b.ts));
      return filtered;
    });
  }

  Stream<ChatMessage?> watchLatestPlantMessage() {
    return watchChat().map((msgs) {
      for (var i = msgs.length - 1; i >= 0; i--) {
        if (msgs[i].fromPlant) return msgs[i];
      }
      return null;
    });
  }

  // --- Mutations ---

  Future<void> setMode(String mode) async {
    _requireOnline();
    final gid = _greenhouseId;
    if (gid == null) return;
    _db.setDoc('greenhouses/$gid', {'mode': mode}, merge: true);
    if (mode == 'auto') {
      await _runAutomation();
    }
  }

  Future<void> setPersona(Persona persona) async {
    _requireOnline();
    final gid = _greenhouseId;
    if (gid == null) return;
    _db.setDoc('greenhouses/$gid', {'persona': persona.id}, merge: true);
    await _postPlant(_persona.greeting(persona));
  }

  Future<void> setDevice(String deviceId, bool isOn,
      {String changedBy = 'user'}) async {
    _requireOnline();
    final gid = _greenhouseId;
    if (gid == null) return;
    final path = 'greenhouses/$gid/devices/$deviceId';
    final existing = _db.getDoc(path) ?? {};
    _db.setDoc(
      path,
      {
        ...existing,
        'isOn': isOn,
        'updatedAt': DateTime.now().toIso8601String(),
        'changedBy': changedBy,
        'type': existing['type'] ?? deviceId,
        'name': existing['name'] ?? deviceId,
      },
    );
    final gh = _db.getDoc('greenhouses/$gid');
    final persona = Persona.fromId(gh?['persona'] as String?);
    await _postPlant(
      _persona.deviceConfirm(
        persona: persona,
        deviceType: deviceId,
        isOn: isOn,
        changedBy: changedBy,
      ),
    );
  }

  Future<void> saveSettings(GreenhouseSettings settings) async {
    _requireOnline();
    final err = GreenhouseSettings.validate(settings);
    if (err != null) throw ArgumentError(err);
    final gid = _greenhouseId;
    if (gid == null) return;
    _db.setDoc('greenhouses/$gid/settings', settings.toMap());
    final gh = _db.getDoc('greenhouses/$gid');
    if (gh != null && gh['mode'] == 'auto') {
      await _runAutomation();
    }
  }

  /// Demo helper: push a new reading (also used by "simulate" tools).
  Future<void> updateReadings(Readings readings) async {
    _requireOnline();
    final gid = _greenhouseId;
    if (gid == null) return;
    _db.setDoc('greenhouses/$gid/current', readings.toMap());
    await _onNewReading(readings);
  }

  Future<void> markAlertRead(String alertId) async {
    final gid = _greenhouseId;
    if (gid == null) return;
    _db.setDoc('greenhouses/$gid/alerts/$alertId', {'read': true}, merge: true);
  }

  Future<void> sendUserChat(String text) async {
    _requireOnline();
    final gid = _greenhouseId;
    if (gid == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _db.setDoc('greenhouses/$gid/chat/${_uuid.v4()}', {
      'ts': DateTime.now().toIso8601String(),
      'text': trimmed,
      'fromPlant': false,
    });
    // Simple echo reply from current readings.
    final current = _db.getDoc('greenhouses/$gid/current');
    final gh = _db.getDoc('greenhouses/$gid');
    if (current != null && gh != null) {
      final r = Readings.fromMap(current);
      final persona = Persona.fromId(gh['persona'] as String?);
      await _postPlant(
        _persona.readingMessage(
          persona: persona,
          parameter: 'airTemp',
          value: r.airTemp,
          outOfRange: false,
          high: false,
        ),
      );
    }
  }

  Future<void> _postPlant(String text) async {
    final gid = _greenhouseId;
    if (gid == null) return;
    _db.setDoc('greenhouses/$gid/chat/${_uuid.v4()}', {
      'ts': DateTime.now().toIso8601String(),
      'text': text,
      'fromPlant': true,
    });
  }

  Future<void> _onNewReading(Readings readings) async {
    final gid = _greenhouseId;
    if (gid == null) return;
    final settingsData = _db.getDoc('greenhouses/$gid/settings');
    final gh = _db.getDoc('greenhouses/$gid');
    if (settingsData == null || gh == null) return;
    final settings = GreenhouseSettings.fromMap(settingsData);
    final persona = Persona.fromId(gh['persona'] as String?);

    final pending = _alerts.check(
      readings: readings,
      settings: settings,
      persona: persona,
    );
    for (final a in pending) {
      final id = _uuid.v4();
      _db.setDoc('greenhouses/$gid/alerts/$id', {
        'ts': DateTime.now().toIso8601String(),
        'parameter': a.parameter,
        'value': a.value,
        'message': a.message,
        'read': false,
      });
      await _postPlant(a.message);
    }

    if (gh['mode'] == 'auto') {
      await _runAutomation(readings: readings, settings: settings);
    }
  }

  Future<void> _runAutomation({
    Readings? readings,
    GreenhouseSettings? settings,
  }) async {
    final gid = _greenhouseId;
    if (gid == null) return;
    final r = readings ??
        Readings.fromMap(_db.getDoc('greenhouses/$gid/current') ?? {});
    final s = settings ??
        GreenhouseSettings.fromMap(
          _db.getDoc('greenhouses/$gid/settings') ?? {},
        );
    final devicesMap = <String, Device>{};
    for (final d in Device.defaults()) {
      final data = _db.getDoc('greenhouses/$gid/devices/${d.id}');
      devicesMap[d.id] = data == null ? d : Device.fromMap(d.id, data);
    }
    final actions = _automation.evaluate(
      readings: r,
      settings: s,
      devices: devicesMap.values.toList(),
    );
    for (final a in actions) {
      await setDevice(a.deviceId, a.turnOn, changedBy: 'auto');
    }
  }

  /// Settings → Create demo data: 7 days hourly history incl. 45°C and 18% soil.
  Future<void> createDemoData() async {
    _requireOnline();
    final gid = _greenhouseId;
    if (gid == null) return;
    _db.clearCollection('greenhouses/$gid/history');
    _db.clearCollection('greenhouses/$gid/alerts');

    final now = DateTime.now();
    final rand = Random(42);
    var spikeTempDone = false;
    var drySoilDone = false;

    for (var h = 7 * 24; h >= 0; h--) {
      final ts = now.subtract(Duration(hours: h));
      var temp = 22 + rand.nextDouble() * 6;
      var soil = 35 + rand.nextDouble() * 20;
      var hum = 50 + rand.nextDouble() * 15;
      var light = 8000 + rand.nextDouble() * 10000;

      // Guarantee defense demo spikes exist in the week.
      if (!spikeTempDone && h == 30) {
        temp = 45;
        spikeTempDone = true;
      }
      if (!drySoilDone && h == 18) {
        soil = 18;
        drySoilDone = true;
      }

      final id = 'h-${ts.toIso8601String()}';
      _db.setDoc('greenhouses/$gid/history/$id', {
        'ts': ts.toIso8601String(),
        'airTemp': double.parse(temp.toStringAsFixed(1)),
        'airHumidity': double.parse(hum.toStringAsFixed(1)),
        'soilMoisture': double.parse(soil.toStringAsFixed(1)),
        'light': double.parse(light.toStringAsFixed(0)),
      });
    }

    // Leave current readings healthy so the live demo can push spikes next.
    await updateReadings(Readings.demoHealthy());
    await _postPlant(
      'Demo data ready: 7 days of history, including a 45°C spike and 18% soil.',
    );
    notifyListeners();
  }

  /// Push the classic defense scenarios from Settings / demo tools.
  Future<void> simulateHotSpike() async {
    final current = await _currentOrHealthy();
    await updateReadings(current.copyWith(
      airTemp: 45,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> simulateDrySoil() async {
    final current = await _currentOrHealthy();
    await updateReadings(current.copyWith(
      soilMoisture: 18,
      updatedAt: DateTime.now(),
    ));
  }

  Future<Readings> _currentOrHealthy() async {
    final gid = _greenhouseId;
    if (gid == null) return Readings.demoHealthy();
    final data = _db.getDoc('greenhouses/$gid/current');
    return data == null ? Readings.demoHealthy() : Readings.fromMap(data);
  }
}
