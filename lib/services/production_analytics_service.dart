import '../models/daily_egg_record.dart';

class ProductionAnalyticsService {
  /// Predicts tomorrow's egg production based on the last 7 days average
  /// Returns null if not enough data
  ProductionPrediction? predictTomorrow(List<DailyEggRecord> records) {
    if (records.isEmpty) return null;

    // Get last 7 days of records
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final recentRecords = records.where((r) {
      final date = DateTime.parse(r.date);
      return date.isAfter(sevenDaysAgo) || date.isAtSameMomentAs(sevenDaysAgo);
    }).toList();

    if (recentRecords.isEmpty) return null;

    // Calculate average
    final total = recentRecords.fold<int>(0, (sum, r) => sum + r.eggsCollected);
    final average = total / recentRecords.length;

    // Calculate standard deviation for confidence
    final variance = recentRecords.fold<double>(0, (sum, r) {
      final diff = r.eggsCollected - average;
      return sum + (diff * diff);
    }) / recentRecords.length;
    final stdDev = variance > 0 ? _sqrt(variance) : 0.0;

    // Confidence is higher when variance is low
    final confidence = stdDev < average * 0.1
        ? PredictionConfidence.high
        : stdDev < average * 0.25
            ? PredictionConfidence.medium
            : PredictionConfidence.low;

    return ProductionPrediction(
      predictedEggs: average.round(),
      minRange: (average - stdDev).round().clamp(0, 999),
      maxRange: (average + stdDev).round(),
      confidence: confidence,
      basedOnDays: recentRecords.length,
    );
  }

  /// Checks if today's production is significantly below average
  /// Returns an alert if production dropped more than threshold%
  ProductionAlert? checkProductionDrop(
    List<DailyEggRecord> records, {
    double thresholdPercent = 15.0,
  }) {
    if (records.length < 3) return null;

    // Get today's record
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final todayRecord = records.where((r) => r.date == todayStr).firstOrNull;
    if (todayRecord == null) return null;

    // Calculate average of last 7 days (excluding today)
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentRecords = records.where((r) {
      if (r.date == todayStr) return false;
      final date = DateTime.parse(r.date);
      return date.isAfter(sevenDaysAgo);
    }).toList();

    if (recentRecords.isEmpty) return null;

    final average = recentRecords.fold<int>(0, (sum, r) => sum + r.eggsCollected) / recentRecords.length;

    if (average == 0) return null;

    final dropPercent = ((average - todayRecord.eggsCollected) / average) * 100;

    if (dropPercent >= thresholdPercent) {
      return ProductionAlert(
        type: AlertType.productionDrop,
        severity: dropPercent >= 30
            ? AlertSeverity.high
            : dropPercent >= 20
                ? AlertSeverity.medium
                : AlertSeverity.low,
        message: 'Production dropped ${dropPercent.toStringAsFixed(0)}% below average',
        messagePt: 'Produção caiu ${dropPercent.toStringAsFixed(0)}% abaixo da média',
        todayValue: todayRecord.eggsCollected,
        averageValue: average.round(),
        dropPercent: dropPercent,
      );
    }

    return null;
  }

  /// Calculates feed efficiency (kg of feed per egg produced)
  FeedEfficiency? calculateFeedEfficiency({
    required double totalFeedKg,
    required int totalEggsProduced,
    required int periodDays,
  }) {
    if (totalEggsProduced == 0 || totalFeedKg == 0) return null;

    final kgPerEgg = totalFeedKg / totalEggsProduced;
    final eggsPerKg = totalEggsProduced / totalFeedKg;

    // Industry benchmark: ~120-140g feed per egg (0.12-0.14 kg/egg)
    final benchmark = 0.13;
    final efficiency = benchmark / kgPerEgg;

    EfficiencyRating rating;
    if (efficiency >= 1.1) {
      rating = EfficiencyRating.excellent;
    } else if (efficiency >= 0.95) {
      rating = EfficiencyRating.good;
    } else if (efficiency >= 0.8) {
      rating = EfficiencyRating.average;
    } else {
      rating = EfficiencyRating.poor;
    }

    return FeedEfficiency(
      kgPerEgg: kgPerEgg,
      eggsPerKg: eggsPerKg,
      rating: rating,
      comparedToBenchmark: ((efficiency - 1) * 100),
      periodDays: periodDays,
    );
  }

  // Simple square root implementation
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}

class ProductionPrediction {
  final int predictedEggs;
  final int minRange;
  final int maxRange;
  final PredictionConfidence confidence;
  final int basedOnDays;

  ProductionPrediction({
    required this.predictedEggs,
    required this.minRange,
    required this.maxRange,
    required this.confidence,
    required this.basedOnDays,
  });
}

enum PredictionConfidence { high, medium, low }

class ProductionAlert {
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final String messagePt;
  final int todayValue;
  final int averageValue;
  final double dropPercent;

  ProductionAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.messagePt,
    required this.todayValue,
    required this.averageValue,
    required this.dropPercent,
  });
}

enum AlertType { productionDrop, productionSpike }
enum AlertSeverity { low, medium, high }

class FeedEfficiency {
  final double kgPerEgg;
  final double eggsPerKg;
  final EfficiencyRating rating;
  final double comparedToBenchmark; // percentage above/below benchmark
  final int periodDays;

  FeedEfficiency({
    required this.kgPerEgg,
    required this.eggsPerKg,
    required this.rating,
    required this.comparedToBenchmark,
    required this.periodDays,
  });
}

enum EfficiencyRating { excellent, good, average, poor }

extension EfficiencyRatingExtension on EfficiencyRating {
  String displayName(String locale) {
    switch (this) {
      case EfficiencyRating.excellent:
        return locale == 'pt' ? 'Excelente' : 'Excellent';
      case EfficiencyRating.good:
        return locale == 'pt' ? 'Bom' : 'Good';
      case EfficiencyRating.average:
        return locale == 'pt' ? 'Médio' : 'Average';
      case EfficiencyRating.poor:
        return locale == 'pt' ? 'Fraco' : 'Poor';
    }
  }

  String get emoji {
    switch (this) {
      case EfficiencyRating.excellent:
        return '🌟';
      case EfficiencyRating.good:
        return '✅';
      case EfficiencyRating.average:
        return '⚠️';
      case EfficiencyRating.poor:
        return '❌';
    }
  }
}

extension PredictionConfidenceExtension on PredictionConfidence {
  String displayName(String locale) {
    switch (this) {
      case PredictionConfidence.high:
        return locale == 'pt' ? 'Alta' : 'High';
      case PredictionConfidence.medium:
        return locale == 'pt' ? 'Média' : 'Medium';
      case PredictionConfidence.low:
        return locale == 'pt' ? 'Baixa' : 'Low';
    }
  }
}
