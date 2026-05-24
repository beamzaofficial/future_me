import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/widgets/countdown_badge.dart';

void main() {
  group('formatRemaining', () {
    test('returns Unlocked for zero or negative duration', () {
      expect(formatRemaining(Duration.zero), 'Unlocked');
      expect(formatRemaining(const Duration(seconds: -5)), 'Unlocked');
    });

    test('shows days+hours when more than a day', () {
      expect(formatRemaining(const Duration(days: 3, hours: 4)), '3d 4h');
    });

    test('shows hours+minutes when less than a day', () {
      expect(formatRemaining(const Duration(hours: 2, minutes: 15)), '2h 15m');
    });

    test('shows minutes+seconds when less than an hour', () {
      expect(
        formatRemaining(const Duration(minutes: 5, seconds: 30)),
        '5m 30s',
      );
    });

    test('shows seconds-only when less than a minute', () {
      expect(formatRemaining(const Duration(seconds: 42)), '42s');
    });
  });
}
