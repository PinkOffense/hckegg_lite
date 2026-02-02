/// Configuration constants for analytics calculations
/// These values can be adjusted based on farm characteristics
class AnalyticsConfig {
  AnalyticsConfig._();

  // ============ FEED EFFICIENCY ============

  /// Benchmark kg of feed per egg (industry standard for laying hens)
  /// Lower is better - efficient hens use less feed per egg
  static const double feedEfficiencyBenchmark = 0.13;

  /// Daily feed consumption per hen in kg (average)
  /// Used to estimate days remaining for feed stock
  static const double dailyFeedConsumptionPerHen = 0.12;

  /// Default daily consumption estimate when hen count is unknown
  static const double defaultDailyFeedConsumption = 0.5;

  // ============ PRODUCTION PREDICTION ============

  /// Number of days to consider for production prediction
  static const int predictionWindowDays = 7;

  /// Minimum records needed for prediction
  static const int minRecordsForPrediction = 3;

  /// High confidence threshold (>= 7 days of data)
  static const int highConfidenceThreshold = 7;

  /// High confidence value
  static const double highConfidenceValue = 0.85;

  /// Low confidence value
  static const double lowConfidenceValue = 0.6;

  /// Trend threshold percentage (5% change to detect trend)
  static const double trendThreshold = 0.05;

  // ============ ALERTS ============

  /// Low stock severity threshold (below 50% of minimum = high severity)
  static const double lowStockHighSeverityThreshold = 0.5;

  // ============ TIME PERIODS ============

  /// Days for "recent" data queries
  static const int recentDays = 30;

  /// Days for week calculations
  static const int weekDays = 7;

  /// Days for month calculations
  static const int monthDays = 30;
}
