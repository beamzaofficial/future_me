import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  AppUser? _user;
  bool _initialized = false;
  bool _busy = false;
  String? _error;
  late final StreamSubscription<AppUser?> _sub;

  AuthProvider(this._service) {
    _sub = _service.authStateChanges().listen((u) {
      _user = u;
      _initialized = true;
      notifyListeners();
    });
  }

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isInitialized => _initialized;
  bool get isBusy => _busy;
  String? get error => _error;

  Future<void> signInWithGoogle() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _service.signInWithGoogle();
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Unexpected error.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _service.signOut();
    } on AuthException catch (e) {
      _error = e.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
