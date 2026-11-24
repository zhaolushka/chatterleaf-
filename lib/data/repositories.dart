import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Login error with a friendly message.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
  @override
  String toString() => message;
}

/// Result of sending a command to a device.
enum CommandResult { sent, queuedOffline }

/// Sign in / sign out (M1). Two implementations: demo (in memory) and Firebase.
abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
}

/// The ONLY way screens read or change data. Two implementations:
/// [MockGreenhouseRepository] (demo, no keys) and [FirestoreGreenhouseRepository].
///
/// watch... methods return Streams: new values arrive by themselves when data
/// changes, so screens update without a restart (M2).
abstract class GreenhouseRepository {
  Stream<List<Greenhouse>> watchMyGreenhouses(String uid);
  Stream<Greenhouse?> watchGreenhouse(String id);
  Stream<List<Device>> watchDevices(String greenhouseId);
  Stream<List<HistoryPoint>> watchHistory(String greenhouseId, Duration period);
  Stream<List<DeviceEvent>> watchEvents(String greenhouseId, {int limit = 50});
  Stream<List<AlertItem>> watchAlerts(String uid);

  /// Turn a device on or off (M3) and write it to the activity log.
  Future<CommandResult> setDevice(String greenhouseId, String deviceId, bool isOn,
      {String by = 'user', String byName = ''});

  /// Manual or automatic mode (M4).
  Future<void> setMode(String greenhouseId, String mode);

  /// Save thresholds (M7). Call [GreenhouseSettings.validate] first.
  Future<void> updateSettings(String greenhouseId, GreenhouseSettings settings);

  Future<void> addAlert({
    required String uid,
    required Greenhouse greenhouse,
    required String param,
    required double value,
    required String message,
  });
  Future<void> markAlertRead(String alertId);
  Future<void> markAllAlertsRead(String uid);
}

/// Internet on/off (M8). In demo mode it can be switched off from Settings.
class ConnectivityService extends ChangeNotifier {
  bool _deviceOnline = true;
  bool _simulatedOffline = false;

  bool get online => _deviceOnline && !_simulatedOffline;
  bool get simulatedOffline => _simulatedOffline;

  /// Called by the Firebase repository when data starts coming from the cache.
  void reportOnline(bool value) {
    if (_deviceOnline == value) return;
    _deviceOnline = value;
    notifyListeners();
  }

  void setSimulatedOffline(bool value) {
    if (_simulatedOffline == value) return;
    _simulatedOffline = value;
    notifyListeners();
  }
}
