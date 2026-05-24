// Integration test that exercises end-to-end navigation and data display
// without hitting real Firebase.
//
// We swap in:
//   * A stub AuthService that emits a signed-in user immediately
//   * FakeFirebaseFirestore for cloud data
//   * A clean SharedPreferences for local storage
//
// Run on a connected device or emulator (adb device id) or web:
//   flutter test integration_test/app_flow_test.dart -d <device_id>
//   flutter test integration_test/app_flow_test.dart -d chrome

import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/main.dart';
import 'package:future_me/models/app_user.dart';
import 'package:future_me/models/letter.dart';
import 'package:future_me/services/auth_service.dart';
import 'package:future_me/services/firestore_service.dart';
import 'package:future_me/services/local_storage_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAuthService implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  static const _signedInUser = AppUser(
    uid: 'integration-user',
    email: 'i@test.com',
    displayName: 'Integration Tester',
  );

  _StubAuthService() {
    Future.microtask(() {
      _user = _signedInUser;
      _controller.add(_user);
    });
  }

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWithGoogle() async {
    _user = _signedInUser;
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signed-in user can navigate to vault and see preloaded letters', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.create();
    final fake = FakeFirebaseFirestore();
    final fs = FirestoreService(db: fake);

    // Seed a letter authored by the integration user (unlocked).
    await fs.createLetter(Letter(
      id: '',
      authorId: _StubAuthService._signedInUser.uid,
      authorName: _StubAuthService._signedInUser.displayName,
      title: 'My past letter',
      content: 'Hi from the past.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      unlockAt: DateTime.now().subtract(const Duration(days: 1)),
      isPublic: true,
    ));

    await tester.pumpWidget(FutureMeApp(
      storage: storage,
      authService: _StubAuthService(),
      firestoreService: fs,
    ));
    await tester.pumpAndSettle();

    // Public Wall should show the public unlocked letter
    expect(find.text('Public Wall'), findsOneWidget);
    expect(find.text('My past letter'), findsOneWidget);

    // Navigate to Vault
    await tester.tap(find.text('Vault'));
    await tester.pumpAndSettle();
    expect(find.text('My Vault'), findsOneWidget);
    expect(find.text('My past letter'), findsOneWidget);
    expect(find.text('Unsealed'), findsOneWidget);

    // Open detail
    await tester.tap(find.text('My past letter'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('letter-content')), findsOneWidget);
    expect(find.text('Hi from the past.'), findsOneWidget);
  });

  testWidgets('signing out returns the user to the login page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.create();
    final auth = _StubAuthService();

    await tester.pumpWidget(FutureMeApp(
      storage: storage,
      authService: auth,
      firestoreService: FirestoreService(db: FakeFirebaseFirestore()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('signout-tile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('google-signin-button')), findsOneWidget);
  });
}
