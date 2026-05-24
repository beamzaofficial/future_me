import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/services/local_storage_service.dart';

void main() {
  group('LetterDraft', () {
    test('round-trips through JSON', () {
      final draft = LetterDraft(
        title: 'Dear me',
        content: 'Hello future',
        unlockAt: DateTime(2030, 6, 1, 9, 30),
        isPublic: true,
        savedAt: DateTime(2026, 5, 8, 12),
      );
      final restored = LetterDraft.fromJson(draft.toJson());
      expect(restored.title, draft.title);
      expect(restored.content, draft.content);
      expect(restored.isPublic, draft.isPublic);
      expect(restored.unlockAt, draft.unlockAt);
      expect(restored.savedAt, draft.savedAt);
    });

    test('isEmpty true when title and content are blank', () {
      final empty = LetterDraft(
        title: '   ',
        content: '',
        isPublic: false,
        savedAt: DateTime.now(),
      );
      expect(empty.isEmpty, true);
    });

    test('isEmpty false when content has text', () {
      final d = LetterDraft(
        title: '',
        content: 'something',
        isPublic: false,
        savedAt: DateTime.now(),
      );
      expect(d.isEmpty, false);
    });

    test('fromJson tolerates missing fields', () {
      final d = LetterDraft.fromJson(<String, dynamic>{});
      expect(d.title, '');
      expect(d.content, '');
      expect(d.isPublic, false);
      expect(d.unlockAt, null);
    });
  });
}
