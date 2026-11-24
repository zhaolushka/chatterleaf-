import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models.dart';
import 'repositories.dart';

// ---------------------------------------------------------------------------
// FIREBASE MODE (start with --dart-define=USE_FIREBASE=true).
// Same interface as the demo backend, so screens don't change at all.
// Data structure: see README → "Firestore structure". Rules: firestore.rules.
// ---------------------------------------------------------------------------

/// Firestore Timestamps → DateTime, recursively, so models stay Firebase-free.
Map<String, dynamic> _plain(Map<String, dynamic>? data) {
  dynamic conv(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), conv(val)));
    return v;
  }

  return (data ?? const {}).map((k, v) => MapEntry(k, conv(v)));
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  AppUser? _map(User? u) => u == null
      ? null
      : AppUser(uid: u.uid, email: u.email ?? '', displayName: (u.displayName?.isNotEmpty ?? false) ? u.displayName! : (u.email ?? ''));

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<void> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) throw const AuthFailure('Enter your email and password');
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(switch (e.code) {
        'invalid-email' => 'That email doesn’t look right',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Wrong email or password',
        'user-disabled' => 'This account is disabled',
        'too-many-requests' => 'Too many attempts. Wait a minute',
        'network-request-failed' => 'No internet. Check your connection',
        _ => 'Could not sign in (${e.code})',
      });
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

class FirestoreGreenhouseRepository implements GreenhouseRepository {
  FirestoreGreenhouseRepository(this._connectivity, {FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final ConnectivityService _connectivity;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _greenhouses => _db.collection('greenhouses');
  CollectionReference<Map<String, dynamic>> get _alerts => _db.collection('alerts');

  @override
  Stream<List<Greenhouse>> watchMyGreenhouses(String uid) {
    // The ownerId filter is required: security rules reject queries without it (M1).
    return _greenhouses.where('ownerId', isEqualTo: uid).snapshots(includeMetadataChanges: true).map((snap) {
      // Data from the local cache means we lost the connection (M8).
      _connectivity.reportOnline(!snap.metadata.isFromCache);
      final list = snap.docs.map((d) => Greenhouse.fromMap(d.id, _plain(d.data()))).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  @override
  Stream<Greenhouse?> watchGreenhouse(String id) => _greenhouses
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Greenhouse.fromMap(d.id, _plain(d.data())) : null);

  @override
  Stream<List<Device>> watchDevices(String greenhouseId) =>
      _greenhouses.doc(greenhouseId).collection('devices').snapshots().map((snap) {
        final list = snap.docs.map((d) => Device.fromMap(d.id, _plain(d.data()))).toList();
        list.sort((a, b) => a.order.compareTo(b.order));
        return list;
      });

  @override
  Stream<List<HistoryPoint>> watchHistory(String greenhouseId, Duration period) => _greenhouses
      .doc(greenhouseId)
      .collection('history')
      .where('ts', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(period)))
      .orderBy('ts')
      .snapshots()
      .map((snap) => snap.docs.map((d) => HistoryPoint.fromMap(_plain(d.data()))).toList());

  @override
  Stream<List<DeviceEvent>> watchEvents(String greenhouseId, {int limit = 50}) => _greenhouses
      .doc(greenhouseId)
      .collection('events')
      .orderBy('ts', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map((d) => DeviceEvent.fromMap(_plain(d.data()))).toList());

  @override
  Stream<List<AlertItem>> watchAlerts(String uid) => _alerts.where('ownerId', isEqualTo: uid).snapshots().map((snap) {
        final list = snap.docs.map((d) => AlertItem.fromMap(d.id, _plain(d.data()))).toList();
        list.sort((a, b) => (b.ts ?? DateTime(0)).compareTo(a.ts ?? DateTime(0)));
        return list;
      });

  @override
  Future<CommandResult> setDevice(String greenhouseId, String deviceId, bool isOn,
      {String by = 'user', String byName = ''}) async {
    final gh = _greenhouses.doc(greenhouseId);
    // A batch saves both writes or neither.
    final batch = _db.batch()
      ..update(gh.collection('devices').doc(deviceId), {
        'isOn': isOn,
        'changedBy': by,
        'changedAt': FieldValue.serverTimestamp(),
      })
      ..set(gh.collection('events').doc(), {
        'ts': FieldValue.serverTimestamp(),
        'deviceId': deviceId,
        'isOn': isOn,
        'by': by,
        'byName': byName,
      });
    try {
      // Offline, Firestore keeps the write in a queue and sends it later (M8).
      await batch.commit().timeout(const Duration(seconds: 5));
      return CommandResult.sent;
    } on TimeoutException {
      return CommandResult.queuedOffline;
    }
  }

  @override
  Future<void> setMode(String greenhouseId, String mode) => _greenhouses.doc(greenhouseId).update({'mode': mode});

  @override
  Future<void> updateSettings(String greenhouseId, GreenhouseSettings settings) {
    final error = settings.validate();
    if (error != null) throw ArgumentError(error);
    return _greenhouses.doc(greenhouseId).update({'settings': settings.toMap()});
  }

  @override
  Future<void> addAlert({
    required String uid,
    required Greenhouse greenhouse,
    required String param,
    required double value,
    required String message,
  }) =>
      _alerts.add({
        'ownerId': uid,
        'greenhouseId': greenhouse.id,
        'plantName': greenhouse.plantName,
        'cropKey': greenhouse.cropKey,
        'param': param,
        'value': value,
        'message': message,
        'ts': FieldValue.serverTimestamp(),
        'read': false,
      });

  @override
  Future<void> markAlertRead(String alertId) => _alerts.doc(alertId).update({'read': true});

  @override
  Future<void> markAllAlertsRead(String uid) async {
    final snap = await _alerts.where('ownerId', isEqualTo: uid).where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}
