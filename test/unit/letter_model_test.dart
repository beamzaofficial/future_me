import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/models/letter.dart';

void main() {
  group('Letter.isUnlockedAt', () {
    final unlockAt = DateTime(2030, 1, 1, 12, 0);
    final letter = _letter(unlockAt: unlockAt);

    test('returns false strictly before unlock time', () {
      expect(
        letter.isUnlockedAt(unlockAt.subtract(const Duration(seconds: 1))),
        false,
      );
    });

    test('returns true at exact unlock time', () {
      expect(letter.isUnlockedAt(unlockAt), true);
    });

    test('returns true after unlock time', () {
      expect(
        letter.isUnlockedAt(unlockAt.add(const Duration(seconds: 1))),
        true,
      );
    });
  });

  group('Letter.timeUntilUnlockAt', () {
    test('returns positive duration when locked', () {
      final letter = _letter(unlockAt: DateTime(2030, 1, 1));
      final remaining = letter.timeUntilUnlockAt(DateTime(2029, 12, 31));
      expect(remaining, const Duration(days: 1));
    });

    test('returns zero/negative duration when unlocked', () {
      final letter = _letter(unlockAt: DateTime(2030, 1, 1));
      final remaining = letter.timeUntilUnlockAt(DateTime(2030, 1, 2));
      expect(remaining.isNegative, true);
    });
  });

  group('Letter.reactionCount', () {
    test('counts reactions of a given type', () {
      final l = _letter(
        reactions: {'u1': 'heart', 'u2': 'heart', 'u3': 'star'},
      );
      expect(l.reactionCount(ReactionType.heart), 2);
      expect(l.reactionCount(ReactionType.star), 1);
      expect(l.reactionCount(ReactionType.hug), 0);
    });
  });

  group('Letter.reactionOf', () {
    test('returns the user\'s current reaction', () {
      final l = _letter(reactions: {'me': 'hug'});
      expect(l.reactionOf('me'), ReactionType.hug);
    });

    test('returns null when user has not reacted', () {
      final l = _letter(reactions: {'someone': 'star'});
      expect(l.reactionOf('me'), null);
    });
  });

  group('Letter.toMap / fromMap', () {
    test('round-trips through Firestore-shaped map', () {
      final original = _letter(
        title: 'Hello',
        content: 'world',
        reactions: {'u1': 'heart'},
        isPublic: true,
      );
      final map = original.toMap();
      // toMap uses Timestamps; fromMap should accept them
      final restored = Letter.fromMap('abc', map);
      expect(restored.id, 'abc');
      expect(restored.title, 'Hello');
      expect(restored.content, 'world');
      expect(restored.isPublic, true);
      expect(restored.reactions['u1'], 'heart');
      expect(restored.unlockAt, original.unlockAt);
      expect(restored.createdAt, original.createdAt);
    });

    test('fromMap supplies safe defaults for missing fields', () {
      final restored = Letter.fromMap('id', {});
      expect(restored.title, '');
      expect(restored.content, '');
      expect(restored.isPublic, false);
      expect(restored.authorName, 'Anonymous');
      expect(restored.reactions, isEmpty);
    });
  });

  group('Letter.copyWith', () {
    test('keeps id, authorId, createdAt and updates given fields', () {
      final l = _letter(title: 'old');
      final copy = l.copyWith(title: 'new', isPublic: true);
      expect(copy.id, l.id);
      expect(copy.authorId, l.authorId);
      expect(copy.createdAt, l.createdAt);
      expect(copy.title, 'new');
      expect(copy.isPublic, true);
      expect(copy.content, l.content);
    });
  });

  group('ReactionTypeX', () {
    test('keys are stable', () {
      expect(ReactionType.heart.key, 'heart');
      expect(ReactionType.hug.key, 'hug');
      expect(ReactionType.star.key, 'star');
    });

    test('fromKey resolves valid keys and returns null for unknown', () {
      expect(ReactionTypeX.fromKey('heart'), ReactionType.heart);
      expect(ReactionTypeX.fromKey('nope'), null);
    });
  });
}

Letter _letter({
  String id = 'id',
  String authorId = 'author',
  String authorName = 'Tester',
  String title = 'title',
  String content = 'content',
  DateTime? createdAt,
  DateTime? unlockAt,
  bool isPublic = false,
  Map<String, String> reactions = const {},
}) {
  final now = DateTime(2026, 1, 1);
  return Letter(
    id: id,
    authorId: authorId,
    authorName: authorName,
    title: title,
    content: content,
    createdAt: createdAt ?? now,
    unlockAt: unlockAt ?? now.add(const Duration(days: 30)),
    isPublic: isPublic,
    reactions: reactions,
  );
}

// Avoid unused-import warnings during refactors:
// ignore: unused_element
void _silence(Timestamp t) {}
