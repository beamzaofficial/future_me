import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/models/app_user.dart';
import 'package:future_me/pages/write_page.dart';
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

  Future<void> pumpWritePage(WidgetTester tester) async {
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
        child: const MaterialApp(home: WritePage()),
      ),
    );
    await tester.pump();
  }

  Future<void> scrollToSubmit(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('submit-button'))),
      alignment: 0.55,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows validation error when title is empty', (tester) async {
    await pumpWritePage(tester);
    await scrollToSubmit(tester);
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pump();
    expect(find.text('Title is required.'), findsOneWidget);
  });

  testWidgets('keeps the write flow in one portrait viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpWritePage(tester);

    final submitBottom = tester.getBottomLeft(
      find.byKey(const Key('submit-button')),
    );
    expect(submitBottom.dy, lessThanOrEqualTo(760));
  });

  testWidgets('shows snackbar when unlock date not picked', (tester) async {
    await pumpWritePage(tester);
    await tester.enterText(find.byKey(const Key('title-field')), 'My letter');
    await tester.enterText(
      find.byKey(const Key('content-field')),
      'Hello future me, this is a real letter.',
    );
    await scrollToSubmit(tester);
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pump();
    expect(find.text('Please pick an unlock date.'), findsOneWidget);
  });

  testWidgets('typing into fields persists draft to local storage', (
    tester,
  ) async {
    await pumpWritePage(tester);
    await tester.enterText(find.byKey(const Key('title-field')), 'Draft title');
    await tester.enterText(
      find.byKey(const Key('content-field')),
      'Draft body content',
    );
    // wait for debounce + save
    await tester.pump(const Duration(milliseconds: 700));
    final draft = storage.getDraft();
    expect(draft, isNotNull);
    expect(draft!.title, 'Draft title');
    expect(draft.content, 'Draft body content');
  });
}
