import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/models/app_user.dart';
import 'package:future_me/models/letter.dart';
import 'package:future_me/pages/vault_page.dart';
import 'package:future_me/providers/auth_provider.dart';
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

  Letter letter({
    required String id,
    required String title,
    required String content,
    required DateTime unlockAt,
    bool isPublic = false,
  }) {
    return Letter(
      id: id,
      authorId: 'me',
      authorName: 'Me',
      title: title,
      content: content,
      createdAt: DateTime(2026, 1, 1),
      unlockAt: unlockAt,
      isPublic: isPublic,
    );
  }

  Future<void> pumpVaultPage(WidgetTester tester) async {
    final auth = AuthProvider(authSvc);
    stream.add(const AppUser(uid: 'me', email: 'me@x.com', displayName: 'Me'));
    await tester.pump();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalStorageService>.value(value: storage),
          Provider<FirestoreService>.value(value: FirestoreService(db: fake)),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(home: VaultPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty vault invites the first letter', (tester) async {
    await pumpVaultPage(tester);

    expect(find.text('The vault is waiting'), findsOneWidget);
    expect(find.text('Write the first letter'), findsOneWidget);
  });

  testWidgets('groups letters into sleeping and ready shelves', (tester) async {
    await fake
        .collection('letters')
        .add(
          letter(
            id: '',
            title: 'Later spring',
            content: 'Hidden locked content',
            unlockAt: DateTime(2099, 1, 1),
          ).toMap(),
        );
    await fake
        .collection('letters')
        .add(
          letter(
            id: '',
            title: 'Opened day',
            content: 'This note is ready.',
            unlockAt: DateTime(2020, 1, 1),
            isPublic: true,
          ).toMap(),
        );

    await pumpVaultPage(tester);

    expect(find.text('Your private shelf of time'), findsOneWidget);
    expect(find.text('Sleeping letters'), findsOneWidget);
    expect(find.text('Ready to open'), findsOneWidget);
    expect(find.text('Sealed in the vault'), findsOneWidget);
    expect(find.text('Ready to read'), findsOneWidget);
    expect(find.text('Later spring'), findsOneWidget);
    expect(find.text('Opened day'), findsOneWidget);
    expect(find.text('Hidden locked content'), findsNothing);
    expect(find.text('This note is ready.'), findsOneWidget);
  });
}
