import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/models/app_user.dart';
import 'package:future_me/providers/auth_provider.dart';
import 'package:future_me/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late _MockAuthService service;
  late StreamController<AppUser?> authStream;

  setUp(() {
    service = _MockAuthService();
    authStream = StreamController<AppUser?>.broadcast();
    when(() => service.authStateChanges()).thenAnswer((_) => authStream.stream);
  });

  tearDown(() async {
    await authStream.close();
  });

  AppUser anon() =>
      const AppUser(uid: 'u', email: 'e@e.com', displayName: 'Tester');

  test('begins uninitialized and not signed in', () {
    final p = AuthProvider(service);
    expect(p.isInitialized, false);
    expect(p.isSignedIn, false);
    expect(p.user, null);
    p.dispose();
  });

  test('marks initialized once auth stream emits', () async {
    final p = AuthProvider(service);
    authStream.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(p.isInitialized, true);
    expect(p.isSignedIn, false);
    p.dispose();
  });

  test('reflects signed-in user on stream emission', () async {
    final p = AuthProvider(service);
    authStream.add(anon());
    await Future<void>.delayed(Duration.zero);
    expect(p.isSignedIn, true);
    expect(p.user?.uid, 'u');
    p.dispose();
  });

  test('signInWithGoogle toggles busy and clears error on success', () async {
    when(() => service.signInWithGoogle()).thenAnswer((_) async => anon());
    final p = AuthProvider(service);
    final future = p.signInWithGoogle();
    expect(p.isBusy, true);
    await future;
    expect(p.isBusy, false);
    expect(p.error, null);
    p.dispose();
  });

  test('signInWithGoogle stores error message on AuthException', () async {
    when(() => service.signInWithGoogle()).thenThrow(AuthException('boom'));
    final p = AuthProvider(service);
    await p.signInWithGoogle();
    expect(p.error, 'boom');
    expect(p.isBusy, false);
    p.dispose();
  });

  test('clearError resets error and notifies', () async {
    when(() => service.signInWithGoogle()).thenThrow(AuthException('x'));
    final p = AuthProvider(service);
    await p.signInWithGoogle();
    expect(p.error, 'x');

    var notified = 0;
    p.addListener(() => notified++);
    p.clearError();
    expect(p.error, null);
    expect(notified, 1);
    p.dispose();
  });

  test('signOut delegates to service', () async {
    when(() => service.signOut()).thenAnswer((_) async {});
    final p = AuthProvider(service);
    await p.signOut();
    verify(() => service.signOut()).called(1);
    p.dispose();
  });
}
