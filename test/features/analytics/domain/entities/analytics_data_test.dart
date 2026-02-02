// test/features/analytics/domain/entities/analytics_data_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/features/analytics/domain/entities/analytics_data.dart';

void main() {
  group('WeekStats', () {
    group('constructor', () {
      test('creates instance with all values', () {
        final stats = WeekStats(
          eggsCollected: 100,
          eggsConsumed: 20,
          eggsSold: 50,
          revenue: 25.0,
          expenses: 10.0,
          netProfit: 15.0,
          startDate: '2024-01-01',
          endDate: '2024-01-07',
        );

        expect(stats.eggsCollected, 100);
        expect(stats.eggsConsumed, 20);
        expect(stats.eggsSold, 50);
        expect(stats.revenue, 25.0);
        expect(stats.expenses, 10.0);
        expect(stats.netProfit, 15.0);
        expect(stats.startDate, '2024-01-01');
        expect(stats.endDate, '2024-01-07');
      });
    });

    group('WeekStats.empty()', () {
      test('creates instance with zero values', () {
        final stats = WeekStats.empty();

        expect(stats.eggsCollected, 0);
        expect(stats.eggsConsumed, 0);
        expect(stats.eggsSold, 0);
        expect(stats.revenue, 0.0);
        expect(stats.expenses, 0.0);
        expect(stats.netProfit, 0.0);
        expect(stats.startDate, '');
        expect(stats.endDate, '');
      });
    });

    group('fromJson', () {
      test('parses JSON correctly', () {
        final json = {
          'eggs_collected': 100,
          'eggs_consumed': 20,
          'eggs_sold': 50,
          'revenue': 25.0,
          'expenses': 10.0,
          'net_profit': 15.0,
          'start_date': '2024-01-01',
          'end_date': '2024-01-07',
        };

        final stats = WeekStats.fromJson(json);

        expect(stats.eggsCollected, 100);
        expect(stats.eggsConsumed, 20);
        expect(stats.eggsSold, 50);
        expect(stats.revenue, 25.0);
        expect(stats.expenses, 10.0);
        expect(stats.netProfit, 15.0);
      });

      test('handles missing values with defaults', () {
        final stats = WeekStats.fromJson({});

        expect(stats.eggsCollected, 0);
        expect(stats.eggsConsumed, 0);
        expect(stats.eggsSold, 0);
        expect(stats.revenue, 0.0);
        expect(stats.expenses, 0.0);
        expect(stats.netProfit, 0.0);
      });
    });

    group('edge cases', () {
      test('handles large numbers', () {
        final stats = WeekStats(
          eggsCollected: 1000000,
          eggsConsumed: 200000,
          eggsSold: 500000,
          revenue: 250000.99,
          expenses: 100000.50,
          netProfit: 149999.49,
          startDate: '2024-01-01',
          endDate: '2024-01-07',
        );

        expect(stats.eggsCollected, 1000000);
        expect(stats.netProfit, closeTo(149999.49, 0.01));
      });

      test('handles decimal precision', () {
        final stats = WeekStats(
          eggsCollected: 10,
          eggsConsumed: 2,
          eggsSold: 5,
          revenue: 2.555,
          expenses: 1.444,
          netProfit: 1.111,
          startDate: '2024-01-01',
          endDate: '2024-01-07',
        );

        expect(stats.revenue, closeTo(2.555, 0.001));
        expect(stats.expenses, closeTo(1.444, 0.001));
        expect(stats.netProfit, closeTo(1.111, 0.001));
      });
    });
  });

  group('ProductionSummary', () {
    test('creates instance with all values', () {
      final summary = ProductionSummary(
        totalCollected: 1000,
        totalConsumed: 200,
        totalRemaining: 800,
        todayCollected: 50,
        todayConsumed: 10,
        weekAverage: 45.5,
      );

      expect(summary.totalCollected, 1000);
      expect(summary.totalConsumed, 200);
      expect(summary.totalRemaining, 800);
      expect(summary.todayCollected, 50);
      expect(summary.todayConsumed, 10);
      expect(summary.weekAverage, 45.5);
      expect(summary.prediction, isNull);
    });

    test('empty() returns zero values', () {
      final summary = ProductionSummary.empty();

      expect(summary.totalCollected, 0);
      expect(summary.totalConsumed, 0);
      expect(summary.totalRemaining, 0);
      expect(summary.todayCollected, 0);
      expect(summary.todayConsumed, 0);
      expect(summary.weekAverage, 0);
      expect(summary.prediction, isNull);
    });

    test('fromJson parses correctly with prediction', () {
      final json = {
        'total_collected': 1000,
        'total_consumed': 200,
        'total_remaining': 800,
        'today_collected': 50,
        'today_consumed': 10,
        'week_average': 45.5,
        'prediction': {
          'predicted_eggs': 48,
          'min_eggs': 40,
          'max_eggs': 55,
          'confidence': 0.85,
          'trend': 'up',
        },
      };

      final summary = ProductionSummary.fromJson(json);

      expect(summary.totalCollected, 1000);
      expect(summary.prediction, isNotNull);
      expect(summary.prediction!.predictedEggs, 48);
      expect(summary.prediction!.trend, 'up');
    });

    test('fromJson handles null prediction', () {
      final json = {
        'total_collected': 1000,
        'total_consumed': 200,
        'total_remaining': 800,
        'today_collected': 50,
        'today_consumed': 10,
        'week_average': 45.5,
      };

      final summary = ProductionSummary.fromJson(json);
      expect(summary.prediction, isNull);
    });
  });

  group('ProductionPrediction', () {
    test('creates instance with all values', () {
      final prediction = ProductionPrediction(
        predictedEggs: 100,
        minEggs: 90,
        maxEggs: 110,
        confidence: 0.85,
        trend: 'up',
      );

      expect(prediction.predictedEggs, 100);
      expect(prediction.minEggs, 90);
      expect(prediction.maxEggs, 110);
      expect(prediction.confidence, 0.85);
      expect(prediction.trend, 'up');
    });

    test('fromJson parses correctly', () {
      final json = {
        'predicted_eggs': 100,
        'min_eggs': 90,
        'max_eggs': 110,
        'confidence': 0.85,
        'trend': 'down',
      };

      final prediction = ProductionPrediction.fromJson(json);

      expect(prediction.predictedEggs, 100);
      expect(prediction.minEggs, 90);
      expect(prediction.maxEggs, 110);
      expect(prediction.confidence, 0.85);
      expect(prediction.trend, 'down');
    });

    test('fromJson handles missing values with defaults', () {
      final prediction = ProductionPrediction.fromJson({});

      expect(prediction.predictedEggs, 0);
      expect(prediction.minEggs, 0);
      expect(prediction.maxEggs, 0);
      expect(prediction.confidence, 0.0);
      expect(prediction.trend, 'stable');
    });
  });

  group('SalesSummary', () {
    test('creates instance with all values', () {
      final summary = SalesSummary(
        totalQuantity: 500,
        totalRevenue: 250.0,
        averagePricePerEgg: 0.50,
        paidAmount: 200.0,
        pendingAmount: 50.0,
        advanceAmount: 0.0,
        lostAmount: 0.0,
        weekRevenue: 100.0,
        monthRevenue: 250.0,
      );

      expect(summary.totalQuantity, 500);
      expect(summary.totalRevenue, 250.0);
      expect(summary.averagePricePerEgg, 0.50);
      expect(summary.paidAmount, 200.0);
      expect(summary.pendingAmount, 50.0);
    });

    test('empty() returns zero values', () {
      final summary = SalesSummary.empty();

      expect(summary.totalQuantity, 0);
      expect(summary.totalRevenue, 0);
      expect(summary.averagePricePerEgg, 0);
      expect(summary.paidAmount, 0);
      expect(summary.pendingAmount, 0);
    });

    test('fromJson parses correctly', () {
      final json = {
        'total_quantity': 500,
        'total_revenue': 250.0,
        'average_price_per_egg': 0.50,
        'paid_amount': 200.0,
        'pending_amount': 50.0,
        'advance_amount': 10.0,
        'lost_amount': 5.0,
        'week_revenue': 100.0,
        'month_revenue': 250.0,
      };

      final summary = SalesSummary.fromJson(json);

      expect(summary.totalQuantity, 500);
      expect(summary.totalRevenue, 250.0);
      expect(summary.advanceAmount, 10.0);
      expect(summary.lostAmount, 5.0);
    });
  });

  group('ExpensesSummary', () {
    test('creates instance with all values', () {
      final summary = ExpensesSummary(
        totalExpenses: 150.0,
        byCategory: {'feed': 100.0, 'equipment': 50.0},
        weekExpenses: 50.0,
        monthExpenses: 150.0,
        netProfit: 100.0,
      );

      expect(summary.totalExpenses, 150.0);
      expect(summary.byCategory['feed'], 100.0);
      expect(summary.byCategory['equipment'], 50.0);
      expect(summary.weekExpenses, 50.0);
      expect(summary.netProfit, 100.0);
    });

    test('empty() returns zero values', () {
      final summary = ExpensesSummary.empty();

      expect(summary.totalExpenses, 0);
      expect(summary.byCategory, isEmpty);
      expect(summary.weekExpenses, 0);
      expect(summary.netProfit, 0);
    });

    test('fromJson parses categories correctly', () {
      final json = {
        'total_expenses': 150.0,
        'by_category': {'feed': 100.0, 'equipment': 50.0},
        'week_expenses': 50.0,
        'month_expenses': 150.0,
        'net_profit': 100.0,
      };

      final summary = ExpensesSummary.fromJson(json);

      expect(summary.byCategory.length, 2);
      expect(summary.byCategory['feed'], 100.0);
    });
  });

  group('FeedSummary', () {
    test('creates instance with all values', () {
      final summary = FeedSummary(
        totalStockKg: 100.0,
        totalConsumedKg: 50.0,
        lowStockCount: 1,
        estimatedDaysRemaining: 14,
        byType: {'layer': 60.0, 'grower': 40.0},
      );

      expect(summary.totalStockKg, 100.0);
      expect(summary.totalConsumedKg, 50.0);
      expect(summary.lowStockCount, 1);
      expect(summary.estimatedDaysRemaining, 14);
      expect(summary.feedEfficiency, isNull);
    });

    test('empty() returns zero values', () {
      final summary = FeedSummary.empty();

      expect(summary.totalStockKg, 0);
      expect(summary.totalConsumedKg, 0);
      expect(summary.lowStockCount, 0);
      expect(summary.estimatedDaysRemaining, 0);
    });

    test('fromJson parses feed efficiency', () {
      final json = {
        'total_stock_kg': 100.0,
        'total_consumed_kg': 50.0,
        'low_stock_count': 1,
        'estimated_days_remaining': 14,
        'feed_efficiency': {
          'kg_per_egg': 0.12,
          'eggs_per_kg': 8.3,
          'is_efficient': true,
          'benchmark': 0.13,
        },
        'by_type': {'layer': 60.0},
      };

      final summary = FeedSummary.fromJson(json);

      expect(summary.feedEfficiency, isNotNull);
      expect(summary.feedEfficiency!.kgPerEgg, 0.12);
      expect(summary.feedEfficiency!.isEfficient, true);
    });
  });

  group('HealthSummary', () {
    test('creates instance with all values', () {
      final summary = HealthSummary(
        totalDeaths: 5,
        totalAffected: 10,
        totalVetCosts: 150.0,
        upcomingActions: 2,
        recentRecords: 3,
      );

      expect(summary.totalDeaths, 5);
      expect(summary.totalAffected, 10);
      expect(summary.totalVetCosts, 150.0);
      expect(summary.upcomingActions, 2);
      expect(summary.recentRecords, 3);
    });

    test('empty() returns zero values', () {
      final summary = HealthSummary.empty();

      expect(summary.totalDeaths, 0);
      expect(summary.totalAffected, 0);
      expect(summary.totalVetCosts, 0);
      expect(summary.upcomingActions, 0);
      expect(summary.recentRecords, 0);
    });

    test('fromJson parses correctly', () {
      final json = {
        'total_deaths': 5,
        'total_affected': 10,
        'total_vet_costs': 150.0,
        'upcoming_actions': 2,
        'recent_records': 3,
      };

      final summary = HealthSummary.fromJson(json);

      expect(summary.totalDeaths, 5);
      expect(summary.totalVetCosts, 150.0);
    });
  });

  group('DashboardAlert', () {
    test('creates instance with all values', () {
      final alert = DashboardAlert(
        type: 'low_stock',
        severity: 'high',
        title: 'Low Feed Stock',
        message: 'Layer feed is running low',
        data: {'feed_type': 'layer', 'remaining_kg': 5.0},
      );

      expect(alert.type, 'low_stock');
      expect(alert.severity, 'high');
      expect(alert.title, 'Low Feed Stock');
      expect(alert.message, 'Layer feed is running low');
      expect(alert.data?['feed_type'], 'layer');
    });

    test('fromJson parses correctly', () {
      final json = {
        'type': 'reservation',
        'severity': 'medium',
        'title': 'Upcoming Reservation',
        'message': 'Order for John tomorrow',
        'data': {'customer': 'John', 'quantity': 30},
      };

      final alert = DashboardAlert.fromJson(json);

      expect(alert.type, 'reservation');
      expect(alert.severity, 'medium');
      expect(alert.data?['customer'], 'John');
    });

    test('fromJson handles missing values', () {
      final alert = DashboardAlert.fromJson({});

      expect(alert.type, '');
      expect(alert.severity, 'low');
      expect(alert.title, '');
      expect(alert.message, '');
      expect(alert.data, isNull);
    });
  });

  group('DashboardAnalytics', () {
    test('empty() returns all empty summaries', () {
      final analytics = DashboardAnalytics.empty();

      expect(analytics.production.totalCollected, 0);
      expect(analytics.sales.totalQuantity, 0);
      expect(analytics.expenses.totalExpenses, 0);
      expect(analytics.feed.totalStockKg, 0);
      expect(analytics.health.totalDeaths, 0);
      expect(analytics.alerts, isEmpty);
    });

    test('fromJson parses complete analytics', () {
      final json = {
        'production': {
          'total_collected': 1000,
          'total_consumed': 200,
          'total_remaining': 800,
          'today_collected': 50,
          'today_consumed': 10,
          'week_average': 45.5,
        },
        'sales': {
          'total_quantity': 500,
          'total_revenue': 250.0,
          'average_price_per_egg': 0.50,
          'paid_amount': 200.0,
          'pending_amount': 50.0,
          'advance_amount': 0.0,
          'lost_amount': 0.0,
          'week_revenue': 100.0,
          'month_revenue': 250.0,
        },
        'expenses': {
          'total_expenses': 150.0,
          'by_category': {},
          'week_expenses': 50.0,
          'month_expenses': 150.0,
          'net_profit': 100.0,
        },
        'feed': {
          'total_stock_kg': 100.0,
          'total_consumed_kg': 50.0,
          'low_stock_count': 1,
          'estimated_days_remaining': 14,
          'by_type': {},
        },
        'health': {
          'total_deaths': 0,
          'total_affected': 0,
          'total_vet_costs': 0.0,
          'upcoming_actions': 0,
          'recent_records': 0,
        },
        'alerts': [
          {
            'type': 'low_stock',
            'severity': 'high',
            'title': 'Low Stock',
            'message': 'Feed is low',
          }
        ],
      };

      final analytics = DashboardAnalytics.fromJson(json);

      expect(analytics.production.totalCollected, 1000);
      expect(analytics.sales.totalQuantity, 500);
      expect(analytics.expenses.netProfit, 100.0);
      expect(analytics.feed.lowStockCount, 1);
      expect(analytics.alerts.length, 1);
      expect(analytics.alerts.first.type, 'low_stock');
    });
  });

  group('FeedEfficiency', () {
    test('creates instance with all values', () {
      final efficiency = FeedEfficiency(
        kgPerEgg: 0.12,
        eggsPerKg: 8.3,
        isEfficient: true,
        benchmark: 0.13,
      );

      expect(efficiency.kgPerEgg, 0.12);
      expect(efficiency.eggsPerKg, 8.3);
      expect(efficiency.isEfficient, true);
      expect(efficiency.benchmark, 0.13);
    });

    test('fromJson parses correctly', () {
      final json = {
        'kg_per_egg': 0.15,
        'eggs_per_kg': 6.67,
        'is_efficient': false,
        'benchmark': 0.13,
      };

      final efficiency = FeedEfficiency.fromJson(json);

      expect(efficiency.kgPerEgg, 0.15);
      expect(efficiency.isEfficient, false);
    });

    test('fromJson handles missing values', () {
      final efficiency = FeedEfficiency.fromJson({});

      expect(efficiency.kgPerEgg, 0.0);
      expect(efficiency.eggsPerKg, 0.0);
      expect(efficiency.isEfficient, true);
      expect(efficiency.benchmark, 0.13);
    });
  });
}
