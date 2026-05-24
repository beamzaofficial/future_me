import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/models/letter.dart';
import 'package:future_me/widgets/letter_card.dart';

void main() {
  Letter letter({required DateTime unlockAt, String content = 'Hidden body'}) {
    return Letter(
      id: 'l1',
      authorId: 'u',
      authorName: 'Alice',
      title: 'Hello',
      content: content,
      createdAt: DateTime(2026, 1, 1),
      unlockAt: unlockAt,
      isPublic: true,
    );
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('shows full content preview when unlocked', (tester) async {
    final l = letter(
      unlockAt: DateTime(2020, 1, 1),
      content: 'Visible message body',
    );
    await pump(tester, LetterCard(letter: l));
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Visible message body'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('hides body and shows sealed-until text when locked', (
    tester,
  ) async {
    final l = letter(unlockAt: DateTime(2099, 1, 1), content: 'Hidden body');
    await pump(tester, LetterCard(letter: l));
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Hidden body'), findsNothing);
    expect(find.textContaining('Sealed until'), findsOneWidget);
  });

  testWidgets('invokes onTap callback', (tester) async {
    var tapped = false;
    final l = letter(unlockAt: DateTime(2020, 1, 1));
    await pump(tester, LetterCard(letter: l, onTap: () => tapped = true));
    await tester.tap(find.byType(LetterCard));
    expect(tapped, true);
  });
}
