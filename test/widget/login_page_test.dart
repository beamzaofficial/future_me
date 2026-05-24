import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/models/app_user.dart';
import 'package:future_me/pages/login_page.dart';
import 'package:future_me/providers/auth_provider.dart';
import 'package:future_me/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late _MockAuthService service;
  late StreamController<AppUser?> stream;

  setUp(() {
    service = _MockAuthService();
    stream = StreamController<AppUser?>.broadcast();
    when(() => service.authStateChanges()).thenAnswer((_) => stream.stream);
    when(() => service.signInWithGoogle()).thenAnswer(
      (_) async => const AppUser(uid: 'u', email: 'e', displayName: 'd'),
    );
  });

  tearDown(() async => stream.close());

  Widget wrap(AuthProvider p) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: p,
      child: const MaterialApp(home: LoginPage()),
    );
  }

  testWidgets('renders title and Google sign-in button', (tester) async {
    final p = AuthProvider(service);
    await tester.pumpWidget(wrap(p));
    expect(find.text('Future Me'), findsOneWidget);
    expect(find.byKey(const Key('google-signin-button')), findsOneWidget);
    p.dispose();
  });

  testWidgets('tapping Google button calls AuthService.signInWithGoogle', (
    tester,
  ) async {
    final p = AuthProvider(service);
    await tester.pumpWidget(wrap(p));
    await tester.tap(find.byKey(const Key('google-signin-button')));
    await tester.pump();
    verify(() => service.signInWithGoogle()).called(1);
    p.dispose();
  });

  testWidgets('shows error banner when sign-in fails', (tester) async {
    when(
      () => service.signInWithGoogle(),
    ).thenThrow(AuthException('Network error.'));
    final p = AuthProvider(service);
    await tester.pumpWidget(wrap(p));
    await tester.tap(find.byKey(const Key('google-signin-button')));
    await tester.pump();
    expect(find.byKey(const Key('auth-error')), findsOneWidget);
    expect(find.text('Network error.'), findsOneWidget);
    p.dispose();
  });

  testWidgets('button shows loading indicator while busy', (tester) async {
    final completer = Completer<AppUser>();
    when(() => service.signInWithGoogle()).thenAnswer((_) => completer.future);
    final p = AuthProvider(service);
    await tester.pumpWidget(wrap(p));
    await tester.tap(find.byKey(const Key('google-signin-button')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(const AppUser(uid: 'u', email: 'e', displayName: 'd'));
    await tester.pumpAndSettle();
    p.dispose();
  });
}
