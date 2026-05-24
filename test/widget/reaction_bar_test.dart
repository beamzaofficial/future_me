import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/models/letter.dart';
import 'package:future_me/widgets/reaction_bar.dart';

void main() {
  Letter base({Map<String, String> reactions = const {}}) {
    return Letter(
      id: 'l',
      authorId: 'a',
      authorName: 'A',
      title: 't',
      content: 'c',
      createdAt: DateTime(2026, 1, 1),
      unlockAt: DateTime(2020, 1, 1),
      isPublic: true,
      reactions: reactions,
    );
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('shows count for each reaction type', (tester) async {
    final l = base(reactions: {'u1': 'heart', 'u2': 'heart', 'u3': 'star'});
    await pump(
      tester,
      ReactionBar(letter: l, currentUserId: 'me', onReact: (_) {}),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('reaction-heart')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('reaction-star')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('reaction-hug')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a reaction calls onReact with that type', (
    tester,
  ) async {
    ReactionType? captured;
    await pump(
      tester,
      ReactionBar(
        letter: base(),
        currentUserId: 'me',
        onReact: (t) => captured = t,
      ),
    );
    await tester.tap(find.byKey(const Key('reaction-star')));
    expect(captured, ReactionType.star);
  });

  testWidgets('tapping the user\'s active reaction toggles it off (null)', (
    tester,
  ) async {
    ReactionType? captured = ReactionType.heart;
    await pump(
      tester,
      ReactionBar(
        letter: base(reactions: {'me': 'heart'}),
        currentUserId: 'me',
        onReact: (t) => captured = t,
      ),
    );
    await tester.tap(find.byKey(const Key('reaction-heart')));
    expect(captured, null);
  });
}
