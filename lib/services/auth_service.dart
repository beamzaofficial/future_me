import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn? _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? (kIsWeb ? null : GoogleSignIn());

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(
      (u) => u == null ? null : AppUser.fromFirebase(u),
    );
  }

  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : AppUser.fromFirebase(u);
  }

  Future<AppUser> signInWithGoogle() async {
    try {
      UserCredential cred;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()..addScope('email');
        cred = await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          throw AuthException('Sign-in cancelled.');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }
      final user = cred.user;
      if (user == null) throw AuthException('Sign-in failed.');
      return AppUser.fromFirebase(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Unexpected error: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        try {
          await _googleSignIn!.signOut();
        } catch (_) {
          // ignore — proceed with Firebase sign-out
        }
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'account-exists-with-different-credential':
        return 'Account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'Invalid credentials.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'popup-closed-by-user':
        return 'Sign-in window closed before completion.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
  }
}
