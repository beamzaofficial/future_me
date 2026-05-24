import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorageService.create();
  });

  test('themeMode defaults to system and persists', () async {
    expect(storage.getThemeMode(), 'system');
    await storage.setThemeMode('dark');
    expect(storage.getThemeMode(), 'dark');
  });

  test('notificationsEnabled defaults true and persists false', () async {
    expect(storage.getNotificationsEnabled(), true);
    await storage.setNotificationsEnabled(false);
    expect(storage.getNotificationsEnabled(), false);
  });

  test('draft returns null when no draft saved', () {
    expect(storage.getDraft(), null);
  });

  test('saveDraft and getDraft round-trip', () async {
    final draft = LetterDraft(
      title: 't',
      content: 'c',
      unlockAt: DateTime(2030),
      isPublic: true,
      savedAt: DateTime(2026, 5, 8),
    );
    await storage.saveDraft(draft);
    final got = storage.getDraft();
    expect(got, isNotNull);
    expect(got!.title, 't');
    expect(got.content, 'c');
    expect(got.isPublic, true);
    expect(got.unlockAt, DateTime(2030));
  });

  test('clearDraft removes draft', () async {
    await storage.saveDraft(
      LetterDraft(
        title: 'x',
        content: 'y',
        isPublic: false,
        savedAt: DateTime.now(),
      ),
    );
    expect(storage.getDraft(), isNotNull);
    await storage.clearDraft();
    expect(storage.getDraft(), null);
  });

  test('lastVaultViewedAt round-trips', () async {
    expect(storage.getLastVaultViewedAt(), null);
    final at = DateTime(2026, 5, 8, 10);
    await storage.setLastVaultViewedAt(at);
    expect(storage.getLastVaultViewedAt(), at);
  });

  test('getDraft returns null on corrupted json', () async {
    SharedPreferences.setMockInitialValues({'letter_draft': 'not-json{{{'});
    final s = await LocalStorageService.create();
    expect(s.getDraft(), null);
  });
}
