import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/widgets/countdown_badge.dart';

void main() {
  Future<void> pump(WidgetTester tester, DateTime unlockAt) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CountdownBadge(unlockAt: unlockAt)),
      ),
    );
  }

  testWidgets('shows "Unlocked" when unlock time is in the past', (
    tester,
  ) async {
    await pump(tester, DateTime.now().subtract(const Duration(seconds: 10)));
    expect(find.text('Unlocked'), findsOneWidget);
    expect(find.byIcon(Icons.mark_email_read_rounded), findsOneWidget);
  });

  testWidgets('shows countdown text when unlock time is in the future', (
    tester,
  ) async {
    await pump(tester, DateTime.now().add(const Duration(days: 2, hours: 5)));
    expect(find.text('Unlocked'), findsNothing);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    // Could be 2d 5h or 2d 4h depending on tick — assert format shape
    expect(find.textContaining('d'), findsOneWidget);
  });
}
