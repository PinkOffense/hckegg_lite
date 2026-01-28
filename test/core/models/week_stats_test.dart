// test/core/models/week_stats_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/models/week_stats.dart';

void main() {
  group('WeekStats', () {
    group('constructor', () {
      test('creates instance with all values', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 20,
          sold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
        );

        expect(stats.collected, 100);
        expect(stats.consumed, 20);
        expect(stats.sold, 50);
        expect(stats.revenue, 25.0);
        expect(stats.expenses, 10.0);
        expect(stats.netProfit, 15.0);
      });
    });

    group('WeekStats.empty()', () {
      test('creates instance with zero values', () {
        const stats = WeekStats.empty();

        expect(stats.collected, 0);
        expect(stats.consumed, 0);
        expect(stats.sold, 0);
        expect(stats.revenue, 0.0);
        expect(stats.expenses, 0.0);
        expect(stats.netProfit, 0.0);
      });
    });

    group('hasProfit', () {
      test('returns true when netProfit is positive', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 10,
          sold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
        );

        expect(stats.hasProfit, true);
      });

      test('returns false when netProfit is zero', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 10,
          sold: 50,
          revenue: 10.0,
          expenses: 10.0,
          netProfit: 0.0,
        );

        expect(stats.hasProfit, false);
      });

      test('returns false when netProfit is negative', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 10,
          sold: 50,
          revenue: 5.0,
          expenses: 10.0,
          netProfit: -5.0,
        );

        expect(stats.hasProfit, false);
      });
    });

    group('hasLoss', () {
      test('returns true when netProfit is negative', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 10,
          sold: 50,
          revenue: 5.0,
          expenses: 10.0,
          netProfit: -5.0,
        );

        expect(stats.hasLoss, true);
      });

      test('returns false when netProfit is zero', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 10,
          sold: 50,
          revenue: 10.0,
          expenses: 10.0,
          netProfit: 0.0,
        );

        expect(stats.hasLoss, false);
      });

      test('returns false when netProfit is positive', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 10,
          sold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
        );

        expect(stats.hasLoss, false);
      });
    });

    group('available', () {
      test('calculates available eggs correctly', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 20,
          sold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
        );

        // available = 100 - 20 - 50 = 30
        expect(stats.available, 30);
      });

      test('returns zero when all eggs used', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 50,
          sold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
        );

        expect(stats.available, 0);
      });

      test('returns negative when oversold/overconsumed', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 60,
          sold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
        );

        // available = 100 - 60 - 50 = -10
        expect(stats.available, -10);
      });
    });

    group('equality', () {
      test('two instances with same values are equal', () {
        final stats1 = WeekStats(
          collected: 100,
          consumed: 20,
          sold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
        );

        final stats2 = WeekStats(
          collected: 100,
          consumed: 20,
          sold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
        );

        expect(stats1, equals(stats2));
        expect(stats1.hashCode, equals(stats2.hashCode));
      });

      test('two instances with different values are not equal', () {
        final stats1 = WeekStats(
          collected: 100,
          consumed: 20,
          sold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
        );

        final stats2 = WeekStats(
          collected: 200, // different
          consumed: 20,
          sold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
        );

        expect(stats1, isNot(equals(stats2)));
      });
    });

    group('toString', () {
      test('returns formatted string with all values', () {
        final stats = WeekStats(
          collected: 100,
          consumed: 20,
          sold: 50,
          revenue: 25.50,
          expenses: 10.25,
          netProfit: 15.25,
        );

        final str = stats.toString();

        expect(str, contains('collected: 100'));
        expect(str, contains('consumed: 20'));
        expect(str, contains('sold: 50'));
        expect(str, contains('revenue: €25.50'));
        expect(str, contains('expenses: €10.25'));
        expect(str, contains('netProfit: €15.25'));
      });
    });

    group('edge cases', () {
      test('handles large numbers', () {
        final stats = WeekStats(
          collected: 1000000,
          consumed: 200000,
          sold: 500000,
          revenue: 250000.99,
          expenses: 100000.50,
          netProfit: 149999.49,
        );

        expect(stats.collected, 1000000);
        expect(stats.available, 300000);
        expect(stats.hasProfit, true);
      });

      test('handles decimal precision', () {
        final stats = WeekStats(
          collected: 10,
          consumed: 2,
          sold: 5,
          revenue: 2.555,
          expenses: 1.444,
          netProfit: 1.111,
        );

        expect(stats.revenue, closeTo(2.555, 0.001));
        expect(stats.expenses, closeTo(1.444, 0.001));
        expect(stats.netProfit, closeTo(1.111, 0.001));
      });
    });
  });
}
