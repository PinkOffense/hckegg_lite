import 'dart:math';
import 'package:supabase/supabase.dart';
import '../../../../core/core.dart';
import '../../domain/entities/analytics_data.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._client);
  final SupabaseClient _client;

  /// Get complete dashboard analytics
  Future<Result<DashboardAnalytics>> getDashboardAnalytics(String userId) async {
    try {
      final production = await _getProductionSummary(userId);
      final sales = await _getSalesSummary(userId);
      final expenses = await _getExpensesSummary(userId, sales.totalRevenue);
      final feed = await _getFeedSummary(userId, production.totalCollected);
      final health = await _getHealthSummary(userId);
      final alerts = await _getAlerts(userId, feed, health);

      return Result.success(DashboardAnalytics(
        production: production,
        sales: sales,
        expenses: expenses,
        feed: feed,
        health: health,
        alerts: alerts,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get production summary
  Future<ProductionSummary> _getProductionSummary(String userId) async {
    final now = DateTime.now();
    final today = _formatDate(now);
    final weekAgo = _formatDate(now.subtract(const Duration(days: 7)));

    // Get all egg records
    final records = await _client
        .from('daily_egg_records')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    final recordsList = records as List;

    int totalCollected = 0;
    int totalConsumed = 0;
    int todayCollected = 0;
    int todayConsumed = 0;
    List<int> weekData = [];

    for (final r in recordsList) {
      final date = r['date'] as String;
      final collected = (r['eggs_collected'] as num?)?.toInt() ?? 0;
      final consumed = (r['eggs_consumed'] as num?)?.toInt() ?? 0;

      totalCollected += collected;
      totalConsumed += consumed;

      if (date == today) {
        todayCollected = collected;
        todayConsumed = consumed;
      }

      if (date.compareTo(weekAgo) >= 0) {
        weekData.add(collected);
      }
    }

    // Get sold eggs to calculate remaining
    final sales = await _client
        .from('egg_sales')
        .select('quantity_sold')
        .eq('user_id', userId);

    int totalSold = 0;
    for (final s in sales as List) {
      totalSold += (s['quantity_sold'] as num?)?.toInt() ?? 0;
    }

    final totalRemaining = totalCollected - totalConsumed - totalSold;
    final weekAverage = weekData.isEmpty ? 0.0 : weekData.reduce((a, b) => a + b) / weekData.length;

    // Calculate prediction
    ProductionPrediction? prediction;
    if (weekData.length >= 3) {
      prediction = _calculatePrediction(weekData);
    }

    return ProductionSummary(
      totalCollected: totalCollected,
      totalConsumed: totalConsumed,
      totalRemaining: totalRemaining < 0 ? 0 : totalRemaining,
      todayCollected: todayCollected,
      todayConsumed: todayConsumed,
      weekAverage: weekAverage,
      prediction: prediction,
    );
  }

  /// Calculate production prediction
  ProductionPrediction _calculatePrediction(List<int> weekData) {
    final avg = weekData.reduce((a, b) => a + b) / weekData.length;

    // Calculate standard deviation
    final variance = weekData.map((x) => pow(x - avg, 2)).reduce((a, b) => a + b) / weekData.length;
    final stdDev = sqrt(variance);

    // Determine trend
    String trend = 'stable';
    if (weekData.length >= 2) {
      final recentAvg = weekData.take(3).reduce((a, b) => a + b) / min(3, weekData.length);
      final olderAvg = weekData.skip(3).isEmpty ? avg : weekData.skip(3).reduce((a, b) => a + b) / weekData.skip(3).length;

      if (recentAvg > olderAvg * 1.05) {
        trend = 'up';
      } else if (recentAvg < olderAvg * 0.95) {
        trend = 'down';
      }
    }

    final predicted = avg.round();
    final minEggs = (avg - stdDev).round();
    final maxEggs = (avg + stdDev).round();
    final confidence = weekData.length >= 7 ? 0.85 : 0.6;

    return ProductionPrediction(
      predictedEggs: predicted,
      minEggs: minEggs < 0 ? 0 : minEggs,
      maxEggs: maxEggs,
      confidence: confidence,
      trend: trend,
    );
  }

  /// Get sales summary
  Future<SalesSummary> _getSalesSummary(String userId) async {
    final now = DateTime.now();
    final weekAgo = _formatDate(now.subtract(const Duration(days: 7)));
    final monthAgo = _formatDate(now.subtract(const Duration(days: 30)));

    final sales = await _client
        .from('egg_sales')
        .select()
        .eq('user_id', userId);

    final salesList = sales as List;

    int totalQuantity = 0;
    double totalRevenue = 0;
    double paidAmount = 0;
    double pendingAmount = 0;
    double advanceAmount = 0;
    double lostAmount = 0;
    double weekRevenue = 0;
    double monthRevenue = 0;

    for (final s in salesList) {
      final qty = (s['quantity_sold'] as num?)?.toInt() ?? 0;
      final amount = (s['total_amount'] as num?)?.toDouble() ?? 0.0;
      final status = s['payment_status'] as String? ?? 'pending';
      final isLost = s['is_lost'] as bool? ?? false;
      final date = s['date'] as String;

      totalQuantity += qty;
      totalRevenue += amount;

      if (isLost) {
        lostAmount += amount;
      } else {
        switch (status) {
          case 'paid':
            paidAmount += amount;
          case 'pending':
            pendingAmount += amount;
          case 'advance':
            advanceAmount += amount;
        }
      }

      if (date.compareTo(weekAgo) >= 0) {
        weekRevenue += amount;
      }
      if (date.compareTo(monthAgo) >= 0) {
        monthRevenue += amount;
      }
    }

    final avgPrice = totalQuantity > 0 ? totalRevenue / totalQuantity : 0.0;

    return SalesSummary(
      totalQuantity: totalQuantity,
      totalRevenue: totalRevenue,
      averagePricePerEgg: avgPrice,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      advanceAmount: advanceAmount,
      lostAmount: lostAmount,
      weekRevenue: weekRevenue,
      monthRevenue: monthRevenue,
    );
  }

  /// Get expenses summary
  Future<ExpensesSummary> _getExpensesSummary(String userId, double totalRevenue) async {
    final now = DateTime.now();
    final weekAgo = _formatDate(now.subtract(const Duration(days: 7)));
    final monthAgo = _formatDate(now.subtract(const Duration(days: 30)));

    final expenses = await _client
        .from('expenses')
        .select()
        .eq('user_id', userId);

    final expensesList = expenses as List;

    double totalExpenses = 0;
    double weekExpenses = 0;
    double monthExpenses = 0;
    Map<String, double> byCategory = {};

    for (final e in expensesList) {
      final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
      final category = e['category'] as String? ?? 'other';
      final date = e['date'] as String;

      totalExpenses += amount;
      byCategory[category] = (byCategory[category] ?? 0) + amount;

      if (date.compareTo(weekAgo) >= 0) {
        weekExpenses += amount;
      }
      if (date.compareTo(monthAgo) >= 0) {
        monthExpenses += amount;
      }
    }

    // Add vet costs to expenses
    final vetRecords = await _client
        .from('vet_records')
        .select('cost, date')
        .eq('user_id', userId);

    for (final v in vetRecords as List) {
      final cost = (v['cost'] as num?)?.toDouble() ?? 0.0;
      final date = v['date'] as String? ?? '';

      totalExpenses += cost;
      byCategory['vet'] = (byCategory['vet'] ?? 0) + cost;

      if (date.compareTo(weekAgo) >= 0) {
        weekExpenses += cost;
      }
      if (date.compareTo(monthAgo) >= 0) {
        monthExpenses += cost;
      }
    }

    return ExpensesSummary(
      totalExpenses: totalExpenses,
      byCategory: byCategory,
      weekExpenses: weekExpenses,
      monthExpenses: monthExpenses,
      netProfit: totalRevenue - totalExpenses,
    );
  }

  /// Get feed summary
  Future<FeedSummary> _getFeedSummary(String userId, int totalEggsCollected) async {
    final feedStocks = await _client
        .from('feed_stocks')
        .select()
        .eq('user_id', userId);

    final stocksList = feedStocks as List;

    double totalStockKg = 0;
    int lowStockCount = 0;
    Map<String, double> byType = {};

    for (final f in stocksList) {
      final qty = (f['current_quantity_kg'] as num?)?.toDouble() ?? 0.0;
      final minQty = (f['minimum_quantity_kg'] as num?)?.toDouble() ?? 10.0;
      final type = f['type'] as String? ?? 'other';

      totalStockKg += qty;
      byType[type] = (byType[type] ?? 0) + qty;

      if (qty <= minQty) {
        lowStockCount++;
      }
    }

    // Get total consumed from movements
    final movements = await _client
        .from('feed_movements')
        .select('quantity_kg, movement_type')
        .eq('user_id', userId);

    double totalConsumedKg = 0;
    for (final m in movements as List) {
      final type = m['movement_type'] as String? ?? '';
      final qty = (m['quantity_kg'] as num?)?.toDouble() ?? 0.0;
      if (type == 'consumption' || type == 'loss') {
        totalConsumedKg += qty;
      }
    }

    // Calculate estimated days remaining (assuming 0.5 kg/day consumption)
    final dailyConsumption = 0.5; // Could be calculated from historical data
    final estimatedDays = totalStockKg > 0 ? (totalStockKg / dailyConsumption).round() : 0;

    // Calculate feed efficiency
    FeedEfficiency? feedEfficiency;
    if (totalConsumedKg > 0 && totalEggsCollected > 0) {
      final kgPerEgg = totalConsumedKg / totalEggsCollected;
      const benchmark = 0.13;
      feedEfficiency = FeedEfficiency(
        kgPerEgg: kgPerEgg,
        eggsPerKg: totalEggsCollected / totalConsumedKg,
        isEfficient: kgPerEgg <= benchmark,
        benchmark: benchmark,
      );
    }

    return FeedSummary(
      totalStockKg: totalStockKg,
      totalConsumedKg: totalConsumedKg,
      lowStockCount: lowStockCount,
      estimatedDaysRemaining: estimatedDays,
      feedEfficiency: feedEfficiency,
      byType: byType,
    );
  }

  /// Get health summary
  Future<HealthSummary> _getHealthSummary(String userId) async {
    final now = DateTime.now();
    final monthAgo = _formatDate(now.subtract(const Duration(days: 30)));
    final today = _formatDate(now);

    final vetRecords = await _client
        .from('vet_records')
        .select()
        .eq('user_id', userId);

    final recordsList = vetRecords as List;

    int totalDeaths = 0;
    int totalAffected = 0;
    double totalVetCosts = 0;
    int upcomingActions = 0;
    int recentRecords = 0;

    for (final r in recordsList) {
      final type = r['type'] as String? ?? '';
      final affected = (r['hens_affected'] as num?)?.toInt() ?? 0;
      final cost = (r['cost'] as num?)?.toDouble() ?? 0.0;
      final date = r['date'] as String? ?? '';
      final nextAction = r['next_action_date'] as String?;

      totalAffected += affected;
      totalVetCosts += cost;

      if (type == 'death') {
        totalDeaths += affected;
      }

      if (date.compareTo(monthAgo) >= 0) {
        recentRecords++;
      }

      if (nextAction != null && nextAction.compareTo(today) >= 0) {
        upcomingActions++;
      }
    }

    return HealthSummary(
      totalDeaths: totalDeaths,
      totalAffected: totalAffected,
      totalVetCosts: totalVetCosts,
      upcomingActions: upcomingActions,
      recentRecords: recentRecords,
    );
  }

  /// Get dashboard alerts
  Future<List<DashboardAlert>> _getAlerts(
    String userId,
    FeedSummary feed,
    HealthSummary health,
  ) async {
    final alerts = <DashboardAlert>[];
    final now = DateTime.now();
    final today = _formatDate(now);
    final tomorrow = _formatDate(now.add(const Duration(days: 1)));

    // Low stock alerts
    if (feed.lowStockCount > 0) {
      final feedStocks = await _client
          .from('feed_stocks')
          .select('type, current_quantity_kg, minimum_quantity_kg')
          .eq('user_id', userId);

      for (final f in feedStocks as List) {
        final qty = (f['current_quantity_kg'] as num?)?.toDouble() ?? 0.0;
        final minQty = (f['minimum_quantity_kg'] as num?)?.toDouble() ?? 10.0;
        if (qty <= minQty) {
          final type = f['type'] as String;
          final daysRemaining = (qty / 0.5).round();
          alerts.add(DashboardAlert(
            type: 'low_stock',
            severity: qty <= minQty * 0.5 ? 'high' : 'medium',
            title: 'Low Stock: $type',
            message: '${qty.toStringAsFixed(1)} kg remaining (~$daysRemaining days)',
            data: {'feed_type': type, 'quantity_kg': qty, 'days_remaining': daysRemaining},
          ));
        }
      }
    }

    // Pending reservations
    final reservations = await _client
        .from('egg_reservations')
        .select()
        .eq('user_id', userId)
        .or('pickup_date.eq.$today,pickup_date.eq.$tomorrow');

    for (final r in reservations as List) {
      final pickupDate = r['pickup_date'] as String?;
      final customerName = r['customer_name'] as String? ?? 'Customer';
      final quantity = (r['quantity'] as num?)?.toInt() ?? 0;

      if (pickupDate != null) {
        alerts.add(DashboardAlert(
          type: 'reservation',
          severity: pickupDate == today ? 'high' : 'medium',
          title: pickupDate == today ? 'Pickup Today' : 'Pickup Tomorrow',
          message: '$customerName - $quantity eggs',
          data: {'customer_name': customerName, 'quantity': quantity, 'pickup_date': pickupDate},
        ));
      }
    }

    // Vet appointments
    final vetAppointments = await _client
        .from('vet_records')
        .select()
        .eq('user_id', userId)
        .or('next_action_date.eq.$today,next_action_date.eq.$tomorrow');

    for (final v in vetAppointments as List) {
      final nextDate = v['next_action_date'] as String?;
      final description = v['description'] as String? ?? 'Vet action';

      if (nextDate != null) {
        alerts.add(DashboardAlert(
          type: 'vet_appointment',
          severity: nextDate == today ? 'high' : 'medium',
          title: nextDate == today ? 'Vet Action Today' : 'Vet Action Tomorrow',
          message: description,
          data: {'date': nextDate, 'description': description},
        ));
      }
    }

    return alerts;
  }

  /// Get week statistics
  Future<Result<WeekStats>> getWeekStats(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final startDate = _formatDate(weekAgo);
      final endDate = _formatDate(now);

      // Get egg records for the week
      final eggRecords = await _client
          .from('daily_egg_records')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate)
          .lte('date', endDate);

      int eggsCollected = 0;
      int eggsConsumed = 0;
      for (final r in eggRecords as List) {
        eggsCollected += (r['eggs_collected'] as num?)?.toInt() ?? 0;
        eggsConsumed += (r['eggs_consumed'] as num?)?.toInt() ?? 0;
      }

      // Get sales for the week
      final sales = await _client
          .from('egg_sales')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate)
          .lte('date', endDate);

      int eggsSold = 0;
      double revenue = 0;
      for (final s in sales as List) {
        eggsSold += (s['quantity_sold'] as num?)?.toInt() ?? 0;
        revenue += (s['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Get expenses for the week
      final expenses = await _client
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate)
          .lte('date', endDate);

      double totalExpenses = 0;
      for (final e in expenses as List) {
        totalExpenses += (e['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Add vet costs
      final vetRecords = await _client
          .from('vet_records')
          .select('cost')
          .eq('user_id', userId)
          .gte('date', startDate)
          .lte('date', endDate);

      for (final v in vetRecords as List) {
        totalExpenses += (v['cost'] as num?)?.toDouble() ?? 0.0;
      }

      return Result.success(WeekStats(
        eggsCollected: eggsCollected,
        eggsConsumed: eggsConsumed,
        eggsSold: eggsSold,
        revenue: revenue,
        expenses: totalExpenses,
        netProfit: revenue - totalExpenses,
        startDate: startDate,
        endDate: endDate,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get production analytics with prediction
  Future<Result<ProductionSummary>> getProductionAnalytics(String userId) async {
    try {
      return Result.success(await _getProductionSummary(userId));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get sales analytics
  Future<Result<SalesSummary>> getSalesAnalytics(String userId) async {
    try {
      return Result.success(await _getSalesSummary(userId));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get expenses analytics
  Future<Result<ExpensesSummary>> getExpensesAnalytics(String userId) async {
    try {
      final sales = await _getSalesSummary(userId);
      return Result.success(await _getExpensesSummary(userId, sales.totalRevenue));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get feed analytics
  Future<Result<FeedSummary>> getFeedAnalytics(String userId) async {
    try {
      final production = await _getProductionSummary(userId);
      return Result.success(await _getFeedSummary(userId, production.totalCollected));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get health analytics
  Future<Result<HealthSummary>> getHealthAnalytics(String userId) async {
    try {
      return Result.success(await _getHealthSummary(userId));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
