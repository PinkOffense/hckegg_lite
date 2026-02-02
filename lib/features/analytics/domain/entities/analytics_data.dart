/// Analytics data models for the frontend
/// These mirror the backend DTOs

/// Complete dashboard analytics
class DashboardAnalytics {
  const DashboardAnalytics({
    required this.production,
    required this.sales,
    required this.expenses,
    required this.feed,
    required this.health,
    required this.alerts,
  });

  final ProductionSummary production;
  final SalesSummary sales;
  final ExpensesSummary expenses;
  final FeedSummary feed;
  final HealthSummary health;
  final List<DashboardAlert> alerts;

  factory DashboardAnalytics.fromJson(Map<String, dynamic> json) {
    return DashboardAnalytics(
      production: ProductionSummary.fromJson(json['production']),
      sales: SalesSummary.fromJson(json['sales']),
      expenses: ExpensesSummary.fromJson(json['expenses']),
      feed: FeedSummary.fromJson(json['feed']),
      health: HealthSummary.fromJson(json['health']),
      alerts: (json['alerts'] as List)
          .map((a) => DashboardAlert.fromJson(a))
          .toList(),
    );
  }

  static DashboardAnalytics empty() => DashboardAnalytics(
        production: ProductionSummary.empty(),
        sales: SalesSummary.empty(),
        expenses: ExpensesSummary.empty(),
        feed: FeedSummary.empty(),
        health: HealthSummary.empty(),
        alerts: [],
      );
}

/// Production metrics
class ProductionSummary {
  const ProductionSummary({
    required this.totalCollected,
    required this.totalConsumed,
    required this.totalRemaining,
    required this.todayCollected,
    required this.todayConsumed,
    required this.weekAverage,
    this.prediction,
  });

  final int totalCollected;
  final int totalConsumed;
  final int totalRemaining;
  final int todayCollected;
  final int todayConsumed;
  final double weekAverage;
  final ProductionPrediction? prediction;

  factory ProductionSummary.fromJson(Map<String, dynamic> json) {
    return ProductionSummary(
      totalCollected: json['total_collected'] as int? ?? 0,
      totalConsumed: json['total_consumed'] as int? ?? 0,
      totalRemaining: json['total_remaining'] as int? ?? 0,
      todayCollected: json['today_collected'] as int? ?? 0,
      todayConsumed: json['today_consumed'] as int? ?? 0,
      weekAverage: (json['week_average'] as num?)?.toDouble() ?? 0.0,
      prediction: json['prediction'] != null
          ? ProductionPrediction.fromJson(json['prediction'])
          : null,
    );
  }

  static ProductionSummary empty() => const ProductionSummary(
        totalCollected: 0,
        totalConsumed: 0,
        totalRemaining: 0,
        todayCollected: 0,
        todayConsumed: 0,
        weekAverage: 0,
      );
}

/// Production prediction
class ProductionPrediction {
  const ProductionPrediction({
    required this.predictedEggs,
    required this.minEggs,
    required this.maxEggs,
    required this.confidence,
    required this.trend,
  });

  final int predictedEggs;
  final int minEggs;
  final int maxEggs;
  final double confidence;
  final String trend;

  factory ProductionPrediction.fromJson(Map<String, dynamic> json) {
    return ProductionPrediction(
      predictedEggs: json['predicted_eggs'] as int? ?? 0,
      minEggs: json['min_eggs'] as int? ?? 0,
      maxEggs: json['max_eggs'] as int? ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      trend: json['trend'] as String? ?? 'stable',
    );
  }
}

/// Sales metrics
class SalesSummary {
  const SalesSummary({
    required this.totalQuantity,
    required this.totalRevenue,
    required this.averagePricePerEgg,
    required this.paidAmount,
    required this.pendingAmount,
    required this.advanceAmount,
    required this.lostAmount,
    required this.weekRevenue,
    required this.monthRevenue,
  });

  final int totalQuantity;
  final double totalRevenue;
  final double averagePricePerEgg;
  final double paidAmount;
  final double pendingAmount;
  final double advanceAmount;
  final double lostAmount;
  final double weekRevenue;
  final double monthRevenue;

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    return SalesSummary(
      totalQuantity: json['total_quantity'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      averagePricePerEgg: (json['average_price_per_egg'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (json['advance_amount'] as num?)?.toDouble() ?? 0.0,
      lostAmount: (json['lost_amount'] as num?)?.toDouble() ?? 0.0,
      weekRevenue: (json['week_revenue'] as num?)?.toDouble() ?? 0.0,
      monthRevenue: (json['month_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static SalesSummary empty() => const SalesSummary(
        totalQuantity: 0,
        totalRevenue: 0,
        averagePricePerEgg: 0,
        paidAmount: 0,
        pendingAmount: 0,
        advanceAmount: 0,
        lostAmount: 0,
        weekRevenue: 0,
        monthRevenue: 0,
      );
}

/// Expenses metrics
class ExpensesSummary {
  const ExpensesSummary({
    required this.totalExpenses,
    required this.byCategory,
    required this.weekExpenses,
    required this.monthExpenses,
    required this.netProfit,
  });

  final double totalExpenses;
  final Map<String, double> byCategory;
  final double weekExpenses;
  final double monthExpenses;
  final double netProfit;

  factory ExpensesSummary.fromJson(Map<String, dynamic> json) {
    final byCat = <String, double>{};
    if (json['by_category'] != null) {
      (json['by_category'] as Map<String, dynamic>).forEach((k, v) {
        byCat[k] = (v as num).toDouble();
      });
    }
    return ExpensesSummary(
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      byCategory: byCat,
      weekExpenses: (json['week_expenses'] as num?)?.toDouble() ?? 0.0,
      monthExpenses: (json['month_expenses'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static ExpensesSummary empty() => const ExpensesSummary(
        totalExpenses: 0,
        byCategory: {},
        weekExpenses: 0,
        monthExpenses: 0,
        netProfit: 0,
      );
}

/// Feed metrics
class FeedSummary {
  const FeedSummary({
    required this.totalStockKg,
    required this.totalConsumedKg,
    required this.lowStockCount,
    required this.estimatedDaysRemaining,
    this.feedEfficiency,
    required this.byType,
  });

  final double totalStockKg;
  final double totalConsumedKg;
  final int lowStockCount;
  final int estimatedDaysRemaining;
  final FeedEfficiency? feedEfficiency;
  final Map<String, double> byType;

  factory FeedSummary.fromJson(Map<String, dynamic> json) {
    final byT = <String, double>{};
    if (json['by_type'] != null) {
      (json['by_type'] as Map<String, dynamic>).forEach((k, v) {
        byT[k] = (v as num).toDouble();
      });
    }
    return FeedSummary(
      totalStockKg: (json['total_stock_kg'] as num?)?.toDouble() ?? 0.0,
      totalConsumedKg: (json['total_consumed_kg'] as num?)?.toDouble() ?? 0.0,
      lowStockCount: json['low_stock_count'] as int? ?? 0,
      estimatedDaysRemaining: json['estimated_days_remaining'] as int? ?? 0,
      feedEfficiency: json['feed_efficiency'] != null
          ? FeedEfficiency.fromJson(json['feed_efficiency'])
          : null,
      byType: byT,
    );
  }

  static FeedSummary empty() => const FeedSummary(
        totalStockKg: 0,
        totalConsumedKg: 0,
        lowStockCount: 0,
        estimatedDaysRemaining: 0,
        byType: {},
      );
}

/// Feed efficiency
class FeedEfficiency {
  const FeedEfficiency({
    required this.kgPerEgg,
    required this.eggsPerKg,
    required this.isEfficient,
    required this.benchmark,
  });

  final double kgPerEgg;
  final double eggsPerKg;
  final bool isEfficient;
  final double benchmark;

  factory FeedEfficiency.fromJson(Map<String, dynamic> json) {
    return FeedEfficiency(
      kgPerEgg: (json['kg_per_egg'] as num?)?.toDouble() ?? 0.0,
      eggsPerKg: (json['eggs_per_kg'] as num?)?.toDouble() ?? 0.0,
      isEfficient: json['is_efficient'] as bool? ?? true,
      benchmark: (json['benchmark'] as num?)?.toDouble() ?? 0.13,
    );
  }
}

/// Health metrics
class HealthSummary {
  const HealthSummary({
    required this.totalDeaths,
    required this.totalAffected,
    required this.totalVetCosts,
    required this.upcomingActions,
    required this.recentRecords,
  });

  final int totalDeaths;
  final int totalAffected;
  final double totalVetCosts;
  final int upcomingActions;
  final int recentRecords;

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      totalDeaths: json['total_deaths'] as int? ?? 0,
      totalAffected: json['total_affected'] as int? ?? 0,
      totalVetCosts: (json['total_vet_costs'] as num?)?.toDouble() ?? 0.0,
      upcomingActions: json['upcoming_actions'] as int? ?? 0,
      recentRecords: json['recent_records'] as int? ?? 0,
    );
  }

  static HealthSummary empty() => const HealthSummary(
        totalDeaths: 0,
        totalAffected: 0,
        totalVetCosts: 0,
        upcomingActions: 0,
        recentRecords: 0,
      );
}

/// Dashboard alert
class DashboardAlert {
  const DashboardAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.data,
  });

  final String type;
  final String severity;
  final String title;
  final String message;
  final Map<String, dynamic>? data;

  factory DashboardAlert.fromJson(Map<String, dynamic> json) {
    return DashboardAlert(
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Week statistics
class WeekStats {
  const WeekStats({
    required this.eggsCollected,
    required this.eggsConsumed,
    required this.eggsSold,
    required this.revenue,
    required this.expenses,
    required this.netProfit,
    required this.startDate,
    required this.endDate,
  });

  final int eggsCollected;
  final int eggsConsumed;
  final int eggsSold;
  final double revenue;
  final double expenses;
  final double netProfit;
  final String startDate;
  final String endDate;

  factory WeekStats.fromJson(Map<String, dynamic> json) {
    return WeekStats(
      eggsCollected: json['eggs_collected'] as int? ?? 0,
      eggsConsumed: json['eggs_consumed'] as int? ?? 0,
      eggsSold: json['eggs_sold'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
    );
  }

  static WeekStats empty() => const WeekStats(
        eggsCollected: 0,
        eggsConsumed: 0,
        eggsSold: 0,
        revenue: 0,
        expenses: 0,
        netProfit: 0,
        startDate: '',
        endDate: '',
      );
}
