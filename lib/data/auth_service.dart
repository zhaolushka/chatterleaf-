import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';
import 'mock/mock_firestore.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthUser {
  const AuthUser({required this.uid, required this.email});
  final String uid;
  final String email;
}

/// Email/password auth. Mock mode uses in-memory accounts (no Firebase).
class AuthService extends ChangeNotifier {
  AuthService({this.useMock = true}) {
    if (useMock) {
      _seedDemoAccounts();
    }
  }

  final bool useMock;
  final _uuid = const Uuid();
  final MockFirestore _db = MockFirestore.instance;

  AuthUser? _user;
  AuthUser? get currentUser => _user;

  // email -> {uid, password, name}
  final Map<String, _MockAccount> _accounts = {};

  final _authChanges = StreamController<AuthUser?>.broadcast();
  Stream<AuthUser?> get authStateChanges => _authChanges.stream;

  void _seedDemoAccounts() {
    _registerLocal(
      email: 'demo@chatterleaf.app',
      password: 'password123',
      name: 'Demo Grower',
      uid: 'uid-demo',
      greenhouseId: 'gh-demo',
    );
    _registerLocal(
      email: 'grower2@chatterleaf.app',
      password: 'password123',
      name: 'Second Grower',
      uid: 'uid-grower2',
      greenhouseId: 'gh-grower2',
    );
  }

  void _registerLocal({
    required String email,
    required String password,
    required String name,
    required String uid,
    required String greenhouseId,
  }) {
    _accounts[email.toLowerCase()] = _MockAccount(
      uid: uid,
      email: email,
      password: password,
      name: name,
    );
    _db.setDoc('users/$uid', {
      'name': name,
      'email': email,
      'greenhouseId': greenhouseId,
    });
  }

  Future<AuthUser> signIn(String email, String password) async {
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null) {
      throw AuthException('No account found for that email.');
    }
    if (account.password != password) {
      throw AuthException('Wrong password. Try again.');
    }
    _user = AuthUser(uid: account.uid, email: account.email);
    _authChanges.add(_user);
    notifyListeners();
    return _user!;
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw AuthException('An account with that email already exists.');
    }
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }
    final uid = _uuid.v4();
    final ghId = 'gh-$uid';
    _registerLocal(
      email: email.trim(),
      password: password,
      name: name.trim().isEmpty ? 'Grower' : name.trim(),
      uid: uid,
      greenhouseId: ghId,
    );
    return signIn(email, password);
  }

  Future<void> signOut() async {
    _user = null;
    _authChanges.add(null);
    notifyListeners();
  }

  Future<UserProfile?> loadProfile(String uid) async {
    final data = _db.getDoc('users/$uid');
    if (data == null) return null;
    return UserProfile.fromMap(uid, data);
  }

  @override
  void dispose() {
    _authChanges.close();
    super.dispose();
  }
}

class _MockAccount {
  _MockAccount({
    required this.uid,
    required this.email,
    required this.password,
    required this.name,
  });
  final String uid;
  final String email;
  final String password;
  final String name;
}
