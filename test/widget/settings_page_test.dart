import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/models/app_user.dart';
import 'package:future_me/models/letter.dart';
import 'package:future_me/pages/settings_page.dart';
import 'package:future_me/providers/auth_provider.dart';
import 'package:future_me/providers/theme_provider.dart';
import 'package:future_me/services/auth_service.dart';
import 'package:future_me/services/firestore_service.dart';
import 'package:future_me/services/local_storage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late _MockAuthService authSvc;
  late FakeFirebaseFirestore fake;
  late LocalStorageService storage;
  late StreamController<AppUser?> stream;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorageService.create();
    fake = FakeFirebaseFirestore();
    authSvc = _MockAuthService();
    stream = StreamController<AppUser?>.broadcast();
    when(() => authSvc.authStateChanges()).thenAnswer((_) => stream.stream);
  });

  tearDown(() async => stream.close());

  Future<void> pumpSettingsPage(WidgetTester tester) async {
    final auth = AuthProvider(authSvc);
    stream.add(const AppUser(uid: 'me', email: 'me@x.com', displayName: 'Me'));
    await tester.pump();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalStorageService>.value(value: storage),
          Provider<FirestoreService>.value(value: FirestoreService(db: fake)),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(storage),
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the settings story hero and vault pulse', (
    tester,
  ) async {
    await fake
        .collection('letters')
        .add(
          Letter(
            id: '',
            authorId: 'me',
            authorName: 'Me',
            title: 'Later',
            content: 'Hidden',
            createdAt: DateTime(2026, 1, 1),
            unlockAt: DateTime(2099, 1, 1),
            isPublic: false,
          ).toMap(),
        );

    await pumpSettingsPage(tester);

    expect(find.text('Tune the writing room'), findsOneWidget);
    expect(find.text('Vault pulse'), findsOneWidget);
    expect(find.textContaining('The next seal softens'), findsOneWidget);
  });

  testWidgets('keeps settings content in one portrait viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 680));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpSettingsPage(tester);

    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byKey(const Key('notifications-switch'))).dy,
      lessThanOrEqualTo(680),
    );
    expect(
      tester.getBottomLeft(find.byKey(const Key('signout-tile'))).dy,
      lessThanOrEqualTo(680),
    );
    expect(
      tester.getBottomLeft(find.text('FUTURE ME')).dy,
      lessThanOrEqualTo(680),
    );
  });

  testWidgets('notification switch persists preference', (tester) async {
    await pumpSettingsPage(tester);

    expect(storage.getNotificationsEnabled(), true);
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('notifications-switch'))),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notifications-switch')));
    await tester.pumpAndSettle();

    expect(storage.getNotificationsEnabled(), false);
  });
}
