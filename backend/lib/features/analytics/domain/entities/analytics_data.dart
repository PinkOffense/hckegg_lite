/// Analytics response DTOs for the backend API

/// Dashboard summary with all key metrics
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

  Map<String, dynamic> toJson() => {
        'production': production.toJson(),
        'sales': sales.toJson(),
        'expenses': expenses.toJson(),
        'feed': feed.toJson(),
        'health': health.toJson(),
        'alerts': alerts.map((a) => a.toJson()).toList(),
      };
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
    required this.prediction,
  });

  final int totalCollected;
  final int totalConsumed;
  final int totalRemaining;
  final int todayCollected;
  final int todayConsumed;
  final double weekAverage;
  final ProductionPrediction? prediction;

  Map<String, dynamic> toJson() => {
        'total_collected': totalCollected,
        'total_consumed': totalConsumed,
        'total_remaining': totalRemaining,
        'today_collected': todayCollected,
        'today_consumed': todayConsumed,
        'week_average': weekAverage,
        'prediction': prediction?.toJson(),
      };
}

/// Production prediction for next day
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
  final double confidence; // 0.0 to 1.0
  final String trend; // 'up', 'down', 'stable'

  Map<String, dynamic> toJson() => {
        'predicted_eggs': predictedEggs,
        'min_eggs': minEggs,
        'max_eggs': maxEggs,
        'confidence': confidence,
        'trend': trend,
      };
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

  Map<String, dynamic> toJson() => {
        'total_quantity': totalQuantity,
        'total_revenue': totalRevenue,
        'average_price_per_egg': averagePricePerEgg,
        'paid_amount': paidAmount,
        'pending_amount': pendingAmount,
        'advance_amount': advanceAmount,
        'lost_amount': lostAmount,
        'week_revenue': weekRevenue,
        'month_revenue': monthRevenue,
      };
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

  Map<String, dynamic> toJson() => {
        'total_expenses': totalExpenses,
        'by_category': byCategory,
        'week_expenses': weekExpenses,
        'month_expenses': monthExpenses,
        'net_profit': netProfit,
      };
}

/// Feed stock metrics
class FeedSummary {
  const FeedSummary({
    required this.totalStockKg,
    required this.totalConsumedKg,
    required this.lowStockCount,
    required this.estimatedDaysRemaining,
    required this.feedEfficiency,
    required this.byType,
  });

  final double totalStockKg;
  final double totalConsumedKg;
  final int lowStockCount;
  final int estimatedDaysRemaining;
  final FeedEfficiency? feedEfficiency;
  final Map<String, double> byType;

  Map<String, dynamic> toJson() => {
        'total_stock_kg': totalStockKg,
        'total_consumed_kg': totalConsumedKg,
        'low_stock_count': lowStockCount,
        'estimated_days_remaining': estimatedDaysRemaining,
        'feed_efficiency': feedEfficiency?.toJson(),
        'by_type': byType,
      };
}

/// Feed efficiency metrics
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
  final double benchmark; // 0.13 kg/egg is standard

  Map<String, dynamic> toJson() => {
        'kg_per_egg': kgPerEgg,
        'eggs_per_kg': eggsPerKg,
        'is_efficient': isEfficient,
        'benchmark': benchmark,
      };
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
  final int recentRecords; // Last 30 days

  Map<String, dynamic> toJson() => {
        'total_deaths': totalDeaths,
        'total_affected': totalAffected,
        'total_vet_costs': totalVetCosts,
        'upcoming_actions': upcomingActions,
        'recent_records': recentRecords,
      };
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

  final String type; // 'low_stock', 'reservation', 'vet_appointment', 'production_drop'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String title;
  final String message;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toJson() => {
        'type': type,
        'severity': severity,
        'title': title,
        'message': message,
        if (data != null) 'data': data,
      };
}

/// Week statistics for dashboard
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

  Map<String, dynamic> toJson() => {
        'eggs_collected': eggsCollected,
        'eggs_consumed': eggsConsumed,
        'eggs_sold': eggsSold,
        'revenue': revenue,
        'expenses': expenses,
        'net_profit': netProfit,
        'start_date': startDate,
        'end_date': endDate,
      };
}
