// test/services/production_analytics_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/models/daily_egg_record.dart';
import 'package:hckegg_lite/services/production_analytics_service.dart';

void main() {
  late ProductionAnalyticsService service;

  setUp(() {
    service = ProductionAnalyticsService();
  });

  /// Helper to create a DailyEggRecord with a specific date
  DailyEggRecord createRecord(String date, int eggs) {
    return DailyEggRecord(
      id: 'test-$date',
      date: date,
      eggsCollected: eggs,
    );
  }

  /// Helper to get ISO date string for days ago
  String daysAgo(int days) {
    final date = DateTime.now().subtract(Duration(days: days));
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  group('ProductionAnalyticsService', () {
    group('predictTomorrow', () {
      test('returns null for empty records', () {
        final result = service.predictTomorrow([]);

        expect(result, isNull);
      });

      test('returns prediction for single record within 7 days', () {
        final records = [createRecord(daysAgo(1), 10)];

        final result = service.predictTomorrow(records);

        expect(result, isNotNull);
        expect(result!.predictedEggs, 10);
        expect(result.basedOnDays, 1);
      });

      test('calculates average for multiple records', () {
        final records = [
          createRecord(daysAgo(1), 10),
          createRecord(daysAgo(2), 12),
          createRecord(daysAgo(3), 8),
        ];

        final result = service.predictTomorrow(records);

        expect(result, isNotNull);
        expect(result!.predictedEggs, 10); // (10+12+8)/3 = 10
        expect(result.basedOnDays, 3);
      });

      test('excludes records older than 7 days', () {
        final records = [
          createRecord(daysAgo(1), 10),
          createRecord(daysAgo(2), 10),
          createRecord(daysAgo(10), 100), // Should be excluded
          createRecord(daysAgo(20), 100), // Should be excluded
        ];

        final result = service.predictTomorrow(records);

        expect(result, isNotNull);
        expect(result!.predictedEggs, 10); // Only recent records
        expect(result.basedOnDays, 2);
      });

      test('returns null when all records are older than 7 days', () {
        final records = [
          createRecord(daysAgo(10), 10),
          createRecord(daysAgo(15), 12),
        ];

        final result = service.predictTomorrow(records);

        expect(result, isNull);
      });

      test('has high confidence when variance is low', () {
        // All same values = zero variance = high confidence
        final records = [
          createRecord(daysAgo(1), 10),
          createRecord(daysAgo(2), 10),
          createRecord(daysAgo(3), 10),
          createRecord(daysAgo(4), 10),
        ];

        final result = service.predictTomorrow(records);

        expect(result, isNotNull);
        expect(result!.confidence, PredictionConfidence.high);
      });

      test('has medium confidence when variance is moderate', () {
        // Variance between 10% and 25% of average
        final records = [
          createRecord(daysAgo(1), 100),
          createRecord(daysAgo(2), 85),
          createRecord(daysAgo(3), 115),
          createRecord(daysAgo(4), 100),
        ];

        final result = service.predictTomorrow(records);

        expect(result, isNotNull);
        expect(result!.confidence, PredictionConfidence.medium);
      });

      test('has low confidence when variance is high', () {
        // High variance = low confidence
        final records = [
          createRecord(daysAgo(1), 100),
          createRecord(daysAgo(2), 50),
          createRecord(daysAgo(3), 150),
          createRecord(daysAgo(4), 20),
        ];

        final result = service.predictTomorrow(records);

        expect(result, isNotNull);
        expect(result!.confidence, PredictionConfidence.low);
      });

      test('minRange is clamped to 0', () {
        // When stdDev > average, minRange should be 0, not negative
        final records = [
          createRecord(daysAgo(1), 5),
          createRecord(daysAgo(2), 50),
        ];

        final result = service.predictTomorrow(records);

        expect(result, isNotNull);
        expect(result!.minRange, greaterThanOrEqualTo(0));
      });

      test('includes today record in calculation', () {
        final records = [
          createRecord(daysAgo(0), 15), // Today
          createRecord(daysAgo(1), 10),
        ];

        final result = service.predictTomorrow(records);

        expect(result, isNotNull);
        expect(result!.basedOnDays, 2);
        expect(result.predictedEggs, 13); // (15+10)/2 = 12.5 rounded
      });
    });

    group('checkProductionDrop', () {
      test('returns null when less than 3 records', () {
        final records = [
          createRecord(daysAgo(0), 10),
          createRecord(daysAgo(1), 10),
        ];

        final result = service.checkProductionDrop(records);

        expect(result, isNull);
      });

      test('returns null when no today record exists', () {
        final records = [
          createRecord(daysAgo(1), 10),
          createRecord(daysAgo(2), 10),
          createRecord(daysAgo(3), 10),
        ];

        final result = service.checkProductionDrop(records);

        expect(result, isNull);
      });

      test('returns null when no drop detected', () {
        final records = [
          createRecord(daysAgo(0), 10), // Today: same as average
          createRecord(daysAgo(1), 10),
          createRecord(daysAgo(2), 10),
          createRecord(daysAgo(3), 10),
        ];

        final result = service.checkProductionDrop(records);

        expect(result, isNull);
      });

      test('returns null when production increased', () {
        final records = [
          createRecord(daysAgo(0), 15), // Today: higher than average
          createRecord(daysAgo(1), 10),
          createRecord(daysAgo(2), 10),
          createRecord(daysAgo(3), 10),
        ];

        final result = service.checkProductionDrop(records);

        expect(result, isNull);
      });

      test('detects low severity drop (15-20%)', () {
        final records = [
          createRecord(daysAgo(0), 85), // Today: 15% below average of 100
          createRecord(daysAgo(1), 100),
          createRecord(daysAgo(2), 100),
          createRecord(daysAgo(3), 100),
        ];

        final result = service.checkProductionDrop(records);

        expect(result, isNotNull);
        expect(result!.severity, AlertSeverity.low);
        expect(result.todayValue, 85);
        expect(result.averageValue, 100);
        expect(result.dropPercent, closeTo(15, 0.5));
      });

      test('detects medium severity drop (20-30%)', () {
        final records = [
          createRecord(daysAgo(0), 75), // Today: 25% below average of 100
          createRecord(daysAgo(1), 100),
          createRecord(daysAgo(2), 100),
          createRecord(daysAgo(3), 100),
        ];

        final result = service.checkProductionDrop(records);

        expect(result, isNotNull);
        expect(result!.severity, AlertSeverity.medium);
        expect(result.dropPercent, closeTo(25, 0.5));
      });

      test('detects high severity drop (>30%)', () {
        final records = [
          createRecord(daysAgo(0), 60), // Today: 40% below average of 100
          createRecord(daysAgo(1), 100),
          createRecord(daysAgo(2), 100),
          createRecord(daysAgo(3), 100),
        ];

        final result = service.checkProductionDrop(records);

        expect(result, isNotNull);
        expect(result!.severity, AlertSeverity.high);
        expect(result.dropPercent, closeTo(40, 0.5));
      });

      test('respects custom threshold', () {
        final records = [
          createRecord(daysAgo(0), 90), // Today: 10% below average of 100
          createRecord(daysAgo(1), 100),
          createRecord(daysAgo(2), 100),
          createRecord(daysAgo(3), 100),
        ];

        // With default 15% threshold, no alert
        expect(service.checkProductionDrop(records), isNull);

        // With 5% threshold, should alert
        final result = service.checkProductionDrop(records, thresholdPercent: 5.0);
        expect(result, isNotNull);
        expect(result!.dropPercent, closeTo(10, 0.5));
      });

      test('returns null when average is zero', () {
        final records = [
          createRecord(daysAgo(0), 5),
          createRecord(daysAgo(1), 0),
          createRecord(daysAgo(2), 0),
          createRecord(daysAgo(3), 0),
        ];

        final result = service.checkProductionDrop(records);

        expect(result, isNull);
      });

      test('excludes records older than 7 days from average', () {
        final records = [
          createRecord(daysAgo(0), 50), // Today
          createRecord(daysAgo(1), 100),
          createRecord(daysAgo(2), 100),
          createRecord(daysAgo(10), 10), // Old - should be excluded
        ];

        final result = service.checkProductionDrop(records);

        expect(result, isNotNull);
        // Average should be 100 (from recent records), not affected by old record
        expect(result!.averageValue, 100);
        expect(result.dropPercent, closeTo(50, 0.5));
      });

      test('provides localized messages', () {
        final records = [
          createRecord(daysAgo(0), 70),
          createRecord(daysAgo(1), 100),
          createRecord(daysAgo(2), 100),
          createRecord(daysAgo(3), 100),
        ];

        final result = service.checkProductionDrop(records);

        expect(result, isNotNull);
        expect(result!.message, contains('dropped'));
        expect(result.messagePt, contains('caiu'));
      });
    });

    group('calculateFeedEfficiency', () {
      test('returns null when eggs produced is zero', () {
        final result = service.calculateFeedEfficiency(
          totalFeedKg: 10.0,
          totalEggsProduced: 0,
          periodDays: 7,
        );

        expect(result, isNull);
      });

      test('returns null when feed is zero', () {
        final result = service.calculateFeedEfficiency(
          totalFeedKg: 0,
          totalEggsProduced: 100,
          periodDays: 7,
        );

        expect(result, isNull);
      });

      test('calculates excellent efficiency (>10% better than benchmark)', () {
        // Benchmark is 0.13 kg/egg
        // Using 0.10 kg/egg = 77% of benchmark = 130% efficiency
        final result = service.calculateFeedEfficiency(
          totalFeedKg: 10.0,
          totalEggsProduced: 100, // 0.1 kg/egg
          periodDays: 7,
        );

        expect(result, isNotNull);
        expect(result!.rating, EfficiencyRating.excellent);
        expect(result.kgPerEgg, closeTo(0.10, 0.01));
        expect(result.eggsPerKg, closeTo(10.0, 0.1));
        expect(result.comparedToBenchmark, greaterThan(10)); // >10% better
      });

      test('calculates good efficiency (95-110% of benchmark)', () {
        // Using 0.13 kg/egg = exactly benchmark = 100% efficiency
        final result = service.calculateFeedEfficiency(
          totalFeedKg: 13.0,
          totalEggsProduced: 100, // 0.13 kg/egg
          periodDays: 7,
        );

        expect(result, isNotNull);
        expect(result!.rating, EfficiencyRating.good);
        expect(result.kgPerEgg, closeTo(0.13, 0.01));
      });

      test('calculates average efficiency (80-95% of benchmark)', () {
        // Using 0.15 kg/egg = 86.7% of benchmark
        final result = service.calculateFeedEfficiency(
          totalFeedKg: 15.0,
          totalEggsProduced: 100, // 0.15 kg/egg
          periodDays: 7,
        );

        expect(result, isNotNull);
        expect(result!.rating, EfficiencyRating.average);
      });

      test('calculates poor efficiency (<80% of benchmark)', () {
        // Using 0.20 kg/egg = 65% of benchmark
        final result = service.calculateFeedEfficiency(
          totalFeedKg: 20.0,
          totalEggsProduced: 100, // 0.20 kg/egg
          periodDays: 7,
        );

        expect(result, isNotNull);
        expect(result!.rating, EfficiencyRating.poor);
        expect(result.comparedToBenchmark, lessThan(-15)); // >15% worse
      });

      test('stores period days correctly', () {
        final result = service.calculateFeedEfficiency(
          totalFeedKg: 13.0,
          totalEggsProduced: 100,
          periodDays: 30,
        );

        expect(result, isNotNull);
        expect(result!.periodDays, 30);
      });

      test('calculates eggs per kg correctly', () {
        final result = service.calculateFeedEfficiency(
          totalFeedKg: 5.0,
          totalEggsProduced: 50,
          periodDays: 7,
        );

        expect(result, isNotNull);
        expect(result!.eggsPerKg, closeTo(10.0, 0.01));
      });
    });

    group('EfficiencyRating extension', () {
      test('displayName returns correct English names', () {
        expect(EfficiencyRating.excellent.displayName('en'), 'Excellent');
        expect(EfficiencyRating.good.displayName('en'), 'Good');
        expect(EfficiencyRating.average.displayName('en'), 'Average');
        expect(EfficiencyRating.poor.displayName('en'), 'Poor');
      });

      test('displayName returns correct Portuguese names', () {
        expect(EfficiencyRating.excellent.displayName('pt'), 'Excelente');
        expect(EfficiencyRating.good.displayName('pt'), 'Bom');
        expect(EfficiencyRating.average.displayName('pt'), 'Médio');
        expect(EfficiencyRating.poor.displayName('pt'), 'Fraco');
      });

      test('emoji returns correct values', () {
        expect(EfficiencyRating.excellent.emoji, contains(''));
        expect(EfficiencyRating.good.emoji, contains(''));
        expect(EfficiencyRating.average.emoji, contains(''));
        expect(EfficiencyRating.poor.emoji, contains(''));
      });
    });

    group('PredictionConfidence extension', () {
      test('displayName returns correct English names', () {
        expect(PredictionConfidence.high.displayName('en'), 'High');
        expect(PredictionConfidence.medium.displayName('en'), 'Medium');
        expect(PredictionConfidence.low.displayName('en'), 'Low');
      });

      test('displayName returns correct Portuguese names', () {
        expect(PredictionConfidence.high.displayName('pt'), 'Alta');
        expect(PredictionConfidence.medium.displayName('pt'), 'Média');
        expect(PredictionConfidence.low.displayName('pt'), 'Baixa');
      });
    });

    group('ProductionPrediction', () {
      test('stores all fields correctly', () {
        final prediction = ProductionPrediction(
          predictedEggs: 100,
          minRange: 90,
          maxRange: 110,
          confidence: PredictionConfidence.high,
          basedOnDays: 7,
        );

        expect(prediction.predictedEggs, 100);
        expect(prediction.minRange, 90);
        expect(prediction.maxRange, 110);
        expect(prediction.confidence, PredictionConfidence.high);
        expect(prediction.basedOnDays, 7);
      });
    });

    group('ProductionAlert', () {
      test('stores all fields correctly', () {
        final alert = ProductionAlert(
          type: AlertType.productionDrop,
          severity: AlertSeverity.high,
          message: 'Test message',
          messagePt: 'Mensagem de teste',
          todayValue: 50,
          averageValue: 100,
          dropPercent: 50.0,
        );

        expect(alert.type, AlertType.productionDrop);
        expect(alert.severity, AlertSeverity.high);
        expect(alert.message, 'Test message');
        expect(alert.messagePt, 'Mensagem de teste');
        expect(alert.todayValue, 50);
        expect(alert.averageValue, 100);
        expect(alert.dropPercent, 50.0);
      });
    });

    group('FeedEfficiency', () {
      test('stores all fields correctly', () {
        final efficiency = FeedEfficiency(
          kgPerEgg: 0.13,
          eggsPerKg: 7.69,
          rating: EfficiencyRating.good,
          comparedToBenchmark: 0.0,
          periodDays: 7,
        );

        expect(efficiency.kgPerEgg, 0.13);
        expect(efficiency.eggsPerKg, 7.69);
        expect(efficiency.rating, EfficiencyRating.good);
        expect(efficiency.comparedToBenchmark, 0.0);
        expect(efficiency.periodDays, 7);
      });
    });
  });
}
