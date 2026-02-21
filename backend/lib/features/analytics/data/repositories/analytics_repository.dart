import 'dart:math';
import 'package:supabase/supabase.dart';
import '../../../../core/core.dart';
import '../../../../core/config/analytics_config.dart';
import '../../domain/entities/analytics_data.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._client);
  final SupabaseClient _client;

  /// Flag to track if RPC functions are available
  /// Set to false after first failed RPC call to avoid repeated failures
  bool _useRpcFunctions = true;

  /// Get complete dashboard analytics
  /// Uses parallel queries for better performance
  Future<Result<DashboardAnalytics>> getDashboardAnalytics(String userId, {String? farmId}) async {
    try {
      // Phase 1: Run independent queries in parallel
      final results = await Future.wait([
        _getProductionSummary(userId, farmId: farmId),
        _getSalesSummary(userId, farmId: farmId),
        _getHealthSummary(userId, farmId: farmId),
      ]);

      final production = results[0] as ProductionSummary;
      final sales = results[1] as SalesSummary;
      final health = results[2] as HealthSummary;

      // Phase 2: Run dependent queries in parallel
      final dependentResults = await Future.wait([
        _getExpensesSummary(userId, sales.totalRevenue, farmId: farmId),
        _getFeedSummary(userId, production.totalCollected, farmId: farmId),
      ]);

      final expenses = dependentResults[0] as ExpensesSummary;
      final feed = dependentResults[1] as FeedSummary;

      // Phase 3: Get alerts (depends on feed and health)
      final alerts = await _getAlerts(userId, feed, health, farmId: farmId);

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

  /// Get production summary using database aggregates when available
  Future<ProductionSummary> _getProductionSummary(String userId, {String? farmId}) async {
    if (_useRpcFunctions) {
      try {
        return await _getProductionSummaryRpc(userId, farmId: farmId);
      } catch (_) {
        // RPC functions not available, fall back to manual aggregation
        _useRpcFunctions = false;
      }
    }
    return _getProductionSummaryManual(userId, farmId: farmId);
  }

  /// Get production summary using RPC functions (database-side aggregation)
  Future<ProductionSummary> _getProductionSummaryRpc(String userId, {String? farmId}) async {
    // Run RPC calls in parallel
    final params = farmId != null ? {'p_farm_id': farmId} : {'p_user_id': userId};
    final results = await Future.wait([
      _client.rpc('get_production_totals', params: params),
      _client.rpc('get_production_week_data', params: params),
      _client.rpc('get_total_eggs_sold', params: params),
    ]);

    final totals = (results[0] as List).isNotEmpty ? results[0][0] : {};
    final weekDataRaw = results[1] as List;
    final totalSold = (results[2] as num?)?.toInt() ?? 0;

    final totalCollected = (totals['total_collected'] as num?)?.toInt() ?? 0;
    final totalConsumed = (totals['total_consumed'] as num?)?.toInt() ?? 0;
    final todayCollected = (totals['today_collected'] as num?)?.toInt() ?? 0;
    final todayConsumed = (totals['today_consumed'] as num?)?.toInt() ?? 0;

    final weekData = weekDataRaw
        .map((r) => (r['eggs_collected'] as num?)?.toInt() ?? 0)
        .toList();

    final totalRemaining = totalCollected - totalConsumed - totalSold;
    final weekAverage = weekData.isEmpty
        ? 0.0
        : weekData.reduce((a, b) => a + b) / weekData.length;

    ProductionPrediction? prediction;
    if (weekData.length >= AnalyticsConfig.minRecordsForPrediction) {
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

  /// Get production summary using manual aggregation (fallback)
  Future<ProductionSummary> _getProductionSummaryManual(String userId, {String? farmId}) async {
    final now = DateTime.now();
    final today = _formatDate(now);
    final weekAgo = _formatDate(now.subtract(const Duration(days: 7)));

    // Get all egg records
    var query = _client.from('daily_egg_records').select();
    if (farmId != null) {
      query = query.eq('farm_id', farmId);
    } else {
      query = query.eq('user_id', userId);
    }
    final records = await query.order('date', ascending: false);

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
    var salesQuery = _client.from('egg_sales').select('quantity_sold');
    if (farmId != null) {
      salesQuery = salesQuery.eq('farm_id', farmId);
    } else {
      salesQuery = salesQuery.eq('user_id', userId);
    }
    final sales = await salesQuery;

    int totalSold = 0;
    for (final s in sales as List) {
      totalSold += (s['quantity_sold'] as num?)?.toInt() ?? 0;
    }

    final totalRemaining = totalCollected - totalConsumed - totalSold;
    final weekAverage = weekData.isEmpty ? 0.0 : weekData.reduce((a, b) => a + b) / weekData.length;

    // Calculate prediction
    ProductionPrediction? prediction;
    if (weekData.length >= AnalyticsConfig.minRecordsForPrediction) {
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

      if (recentAvg > olderAvg * (1 + AnalyticsConfig.trendThreshold)) {
        trend = 'up';
      } else if (recentAvg < olderAvg * (1 - AnalyticsConfig.trendThreshold)) {
        trend = 'down';
      }
    }

    final predicted = avg.round();
    final minEggs = (avg - stdDev).round();
    final maxEggs = (avg + stdDev).round();
    final confidence = weekData.length >= AnalyticsConfig.highConfidenceThreshold
        ? AnalyticsConfig.highConfidenceValue
        : AnalyticsConfig.lowConfidenceValue;

    return ProductionPrediction(
      predictedEggs: predicted,
      minEggs: minEggs < 0 ? 0 : minEggs,
      maxEggs: maxEggs,
      confidence: confidence,
      trend: trend,
    );
  }

  /// Get sales summary using database aggregates when available
  Future<SalesSummary> _getSalesSummary(String userId, {String? farmId}) async {
    if (_useRpcFunctions) {
      try {
        return await _getSalesSummaryRpc(userId, farmId: farmId);
      } catch (_) {
        _useRpcFunctions = false;
      }
    }
    return _getSalesSummaryManual(userId, farmId: farmId);
  }

  /// Get sales summary using RPC functions (database-side aggregation)
  Future<SalesSummary> _getSalesSummaryRpc(String userId, {String? farmId}) async {
    final params = farmId != null ? {'p_farm_id': farmId} : {'p_user_id': userId};
    final result = await _client.rpc('get_sales_totals', params: params);
    final data = (result as List).isNotEmpty ? result[0] : {};

    final totalQuantity = (data['total_quantity'] as num?)?.toInt() ?? 0;
    final totalRevenue = (data['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final avgPrice = totalQuantity > 0 ? totalRevenue / totalQuantity : 0.0;

    return SalesSummary(
      totalQuantity: totalQuantity,
      totalRevenue: totalRevenue,
      averagePricePerEgg: avgPrice,
      paidAmount: (data['paid_amount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (data['pending_amount'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (data['advance_amount'] as num?)?.toDouble() ?? 0.0,
      lostAmount: (data['lost_amount'] as num?)?.toDouble() ?? 0.0,
      weekRevenue: (data['week_revenue'] as num?)?.toDouble() ?? 0.0,
      monthRevenue: (data['month_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Get sales summary using manual aggregation (fallback)
  Future<SalesSummary> _getSalesSummaryManual(String userId, {String? farmId}) async {
    final now = DateTime.now();
    final weekAgo = _formatDate(now.subtract(const Duration(days: 7)));
    final monthAgo = _formatDate(now.subtract(const Duration(days: 30)));

    var query = _client.from('egg_sales').select();
    if (farmId != null) {
      query = query.eq('farm_id', farmId);
    } else {
      query = query.eq('user_id', userId);
    }
    final sales = await query;

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

  /// Get expenses summary using database aggregates when available
  Future<ExpensesSummary> _getExpensesSummary(String userId, double totalRevenue, {String? farmId}) async {
    if (_useRpcFunctions) {
      try {
        return await _getExpensesSummaryRpc(userId, totalRevenue, farmId: farmId);
      } catch (_) {
        _useRpcFunctions = false;
      }
    }
    return _getExpensesSummaryManual(userId, totalRevenue, farmId: farmId);
  }

  /// Get expenses summary using RPC functions (database-side aggregation)
  Future<ExpensesSummary> _getExpensesSummaryRpc(String userId, double totalRevenue, {String? farmId}) async {
    final params = farmId != null ? {'p_farm_id': farmId} : {'p_user_id': userId};
    final results = await Future.wait([
      _client.rpc('get_expenses_totals', params: params),
      _client.rpc('get_vet_costs_totals', params: params),
    ]);

    final expData = (results[0] as List).isNotEmpty ? results[0][0] : {};
    final vetData = (results[1] as List).isNotEmpty ? results[1][0] : {};

    final totalExpenses = (expData['total_expenses'] as num?)?.toDouble() ?? 0.0;
    final totalVetCosts = (vetData['total_vet_costs'] as num?)?.toDouble() ?? 0.0;
    final weekExpenses = (expData['week_expenses'] as num?)?.toDouble() ?? 0.0;
    final weekVetCosts = (vetData['week_vet_costs'] as num?)?.toDouble() ?? 0.0;
    final monthExpenses = (expData['month_expenses'] as num?)?.toDouble() ?? 0.0;
    final monthVetCosts = (vetData['month_vet_costs'] as num?)?.toDouble() ?? 0.0;

    final byCategory = <String, double>{};
    if ((expData['feed_expenses'] as num?)?.toDouble() != 0) {
      byCategory['feed'] = (expData['feed_expenses'] as num).toDouble();
    }
    if ((expData['maintenance_expenses'] as num?)?.toDouble() != 0) {
      byCategory['maintenance'] = (expData['maintenance_expenses'] as num).toDouble();
    }
    if ((expData['equipment_expenses'] as num?)?.toDouble() != 0) {
      byCategory['equipment'] = (expData['equipment_expenses'] as num).toDouble();
    }
    if ((expData['utilities_expenses'] as num?)?.toDouble() != 0) {
      byCategory['utilities'] = (expData['utilities_expenses'] as num).toDouble();
    }
    if ((expData['other_expenses'] as num?)?.toDouble() != 0) {
      byCategory['other'] = (expData['other_expenses'] as num).toDouble();
    }
    if (totalVetCosts > 0) {
      byCategory['vet'] = totalVetCosts;
    }

    return ExpensesSummary(
      totalExpenses: totalExpenses + totalVetCosts,
      byCategory: byCategory,
      weekExpenses: weekExpenses + weekVetCosts,
      monthExpenses: monthExpenses + monthVetCosts,
      netProfit: totalRevenue - (totalExpenses + totalVetCosts),
    );
  }

  /// Get expenses summary using manual aggregation (fallback)
  Future<ExpensesSummary> _getExpensesSummaryManual(String userId, double totalRevenue, {String? farmId}) async {
    final now = DateTime.now();
    final weekAgo = _formatDate(now.subtract(const Duration(days: 7)));
    final monthAgo = _formatDate(now.subtract(const Duration(days: 30)));

    var expQuery = _client.from('expenses').select();
    if (farmId != null) {
      expQuery = expQuery.eq('farm_id', farmId);
    } else {
      expQuery = expQuery.eq('user_id', userId);
    }
    final expenses = await expQuery;

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
    var vetQuery = _client.from('vet_records').select('cost, date');
    if (farmId != null) {
      vetQuery = vetQuery.eq('farm_id', farmId);
    } else {
      vetQuery = vetQuery.eq('user_id', userId);
    }
    final vetRecords = await vetQuery;

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

  /// Get feed summary using database aggregates when available
  Future<FeedSummary> _getFeedSummary(String userId, int totalEggsCollected, {String? farmId}) async {
    if (_useRpcFunctions) {
      try {
        return await _getFeedSummaryRpc(userId, totalEggsCollected, farmId: farmId);
      } catch (_) {
        _useRpcFunctions = false;
      }
    }
    return _getFeedSummaryManual(userId, totalEggsCollected, farmId: farmId);
  }

  /// Get feed summary using RPC functions (database-side aggregation)
  Future<FeedSummary> _getFeedSummaryRpc(String userId, int totalEggsCollected, {String? farmId}) async {
    final params = farmId != null ? {'p_farm_id': farmId} : {'p_user_id': userId};
    final results = await Future.wait([
      _client.rpc('get_feed_totals', params: params),
      _client.rpc('get_feed_consumed_total', params: params),
    ]);

    final feedData = (results[0] as List).isNotEmpty ? results[0][0] : {};
    final totalConsumedKg = (results[1] as num?)?.toDouble() ?? 0.0;

    final totalStockKg = (feedData['total_stock_kg'] as num?)?.toDouble() ?? 0.0;
    final lowStockCount = (feedData['low_stock_count'] as num?)?.toInt() ?? 0;

    final byType = <String, double>{};
    if ((feedData['layer_stock'] as num?)?.toDouble() != 0) {
      byType['layer'] = (feedData['layer_stock'] as num).toDouble();
    }
    if ((feedData['grower_stock'] as num?)?.toDouble() != 0) {
      byType['grower'] = (feedData['grower_stock'] as num).toDouble();
    }
    if ((feedData['starter_stock'] as num?)?.toDouble() != 0) {
      byType['starter'] = (feedData['starter_stock'] as num).toDouble();
    }
    if ((feedData['scratch_stock'] as num?)?.toDouble() != 0) {
      byType['scratch'] = (feedData['scratch_stock'] as num).toDouble();
    }
    if ((feedData['supplement_stock'] as num?)?.toDouble() != 0) {
      byType['supplement'] = (feedData['supplement_stock'] as num).toDouble();
    }
    if ((feedData['other_stock'] as num?)?.toDouble() != 0) {
      byType['other'] = (feedData['other_stock'] as num).toDouble();
    }

    final estimatedDays = totalStockKg > 0
        ? (totalStockKg / AnalyticsConfig.defaultDailyFeedConsumption).round()
        : 0;

    FeedEfficiency? feedEfficiency;
    if (totalConsumedKg > 0 && totalEggsCollected > 0) {
      final kgPerEgg = totalConsumedKg / totalEggsCollected;
      feedEfficiency = FeedEfficiency(
        kgPerEgg: kgPerEgg,
        eggsPerKg: totalEggsCollected / totalConsumedKg,
        isEfficient: kgPerEgg <= AnalyticsConfig.feedEfficiencyBenchmark,
        benchmark: AnalyticsConfig.feedEfficiencyBenchmark,
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

  /// Get feed summary using manual aggregation (fallback)
  Future<FeedSummary> _getFeedSummaryManual(String userId, int totalEggsCollected, {String? farmId}) async {
    var stockQuery = _client.from('feed_stocks').select();
    if (farmId != null) {
      stockQuery = stockQuery.eq('farm_id', farmId);
    } else {
      stockQuery = stockQuery.eq('user_id', userId);
    }
    final feedStocks = await stockQuery;

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
    var movQuery = _client.from('feed_movements').select('quantity_kg, movement_type');
    if (farmId != null) {
      movQuery = movQuery.eq('farm_id', farmId);
    } else {
      movQuery = movQuery.eq('user_id', userId);
    }
    final movements = await movQuery;

    double totalConsumedKg = 0;
    for (final m in movements as List) {
      final type = m['movement_type'] as String? ?? '';
      final qty = (m['quantity_kg'] as num?)?.toDouble() ?? 0.0;
      if (type == 'consumption' || type == 'loss') {
        totalConsumedKg += qty;
      }
    }

    // Calculate estimated days remaining
    final estimatedDays = totalStockKg > 0
        ? (totalStockKg / AnalyticsConfig.defaultDailyFeedConsumption).round()
        : 0;

    // Calculate feed efficiency
    FeedEfficiency? feedEfficiency;
    if (totalConsumedKg > 0 && totalEggsCollected > 0) {
      final kgPerEgg = totalConsumedKg / totalEggsCollected;
      feedEfficiency = FeedEfficiency(
        kgPerEgg: kgPerEgg,
        eggsPerKg: totalEggsCollected / totalConsumedKg,
        isEfficient: kgPerEgg <= AnalyticsConfig.feedEfficiencyBenchmark,
        benchmark: AnalyticsConfig.feedEfficiencyBenchmark,
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

  /// Get health summary using database aggregates when available
  Future<HealthSummary> _getHealthSummary(String userId, {String? farmId}) async {
    if (_useRpcFunctions) {
      try {
        return await _getHealthSummaryRpc(userId, farmId: farmId);
      } catch (_) {
        _useRpcFunctions = false;
      }
    }
    return _getHealthSummaryManual(userId, farmId: farmId);
  }

  /// Get health summary using RPC functions (database-side aggregation)
  Future<HealthSummary> _getHealthSummaryRpc(String userId, {String? farmId}) async {
    final params = farmId != null ? {'p_farm_id': farmId} : {'p_user_id': userId};
    final result = await _client.rpc('get_health_totals', params: params);
    final data = (result as List).isNotEmpty ? result[0] : {};

    return HealthSummary(
      totalDeaths: (data['total_deaths'] as num?)?.toInt() ?? 0,
      totalAffected: (data['total_affected'] as num?)?.toInt() ?? 0,
      totalVetCosts: (data['total_vet_costs'] as num?)?.toDouble() ?? 0.0,
      upcomingActions: (data['upcoming_actions'] as num?)?.toInt() ?? 0,
      recentRecords: (data['recent_records'] as num?)?.toInt() ?? 0,
    );
  }

  /// Get health summary using manual aggregation (fallback)
  Future<HealthSummary> _getHealthSummaryManual(String userId, {String? farmId}) async {
    final now = DateTime.now();
    final monthAgo = _formatDate(now.subtract(const Duration(days: 30)));
    final today = _formatDate(now);

    var healthQuery = _client.from('vet_records').select();
    if (farmId != null) {
      healthQuery = healthQuery.eq('farm_id', farmId);
    } else {
      healthQuery = healthQuery.eq('user_id', userId);
    }
    final vetRecords = await healthQuery;

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
    HealthSummary health, {
    String? farmId,
  }) async {
    final alerts = <DashboardAlert>[];
    final now = DateTime.now();
    final today = _formatDate(now);
    final tomorrow = _formatDate(now.add(const Duration(days: 1)));

    // Low stock alerts
    if (feed.lowStockCount > 0) {
      var feedQuery = _client.from('feed_stocks').select('type, current_quantity_kg, minimum_quantity_kg');
      if (farmId != null) {
        feedQuery = feedQuery.eq('farm_id', farmId);
      } else {
        feedQuery = feedQuery.eq('user_id', userId);
      }
      final feedStocks = await feedQuery;

      for (final f in feedStocks as List) {
        final qty = (f['current_quantity_kg'] as num?)?.toDouble() ?? 0.0;
        final minQty = (f['minimum_quantity_kg'] as num?)?.toDouble() ?? 10.0;
        if (qty <= minQty) {
          final type = f['type'] as String;
          final daysRemaining = (qty / AnalyticsConfig.defaultDailyFeedConsumption).round();
          final isHighSeverity = qty <= minQty * AnalyticsConfig.lowStockHighSeverityThreshold;
          alerts.add(DashboardAlert(
            type: 'low_stock',
            severity: isHighSeverity ? 'high' : 'medium',
            title: 'Low Stock: $type',
            message: '${qty.toStringAsFixed(1)} kg remaining (~$daysRemaining days)',
            data: {'feed_type': type, 'quantity_kg': qty, 'days_remaining': daysRemaining},
          ));
        }
      }
    }

    // Pending reservations
    var resQuery = _client.from('egg_reservations').select();
    if (farmId != null) {
      resQuery = resQuery.eq('farm_id', farmId);
    } else {
      resQuery = resQuery.eq('user_id', userId);
    }
    final reservations = await resQuery.or('pickup_date.eq.$today,pickup_date.eq.$tomorrow');

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
    var vetQuery = _client.from('vet_records').select();
    if (farmId != null) {
      vetQuery = vetQuery.eq('farm_id', farmId);
    } else {
      vetQuery = vetQuery.eq('user_id', userId);
    }
    final vetAppointments = await vetQuery.or('next_action_date.eq.$today,next_action_date.eq.$tomorrow');

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

  /// Get week statistics using database aggregates when available
  Future<Result<WeekStats>> getWeekStats(String userId, {String? farmId}) async {
    if (_useRpcFunctions) {
      try {
        return await _getWeekStatsRpc(userId, farmId: farmId);
      } catch (_) {
        _useRpcFunctions = false;
      }
    }
    return _getWeekStatsManual(userId, farmId: farmId);
  }

  /// Get week statistics using RPC function (single database call)
  Future<Result<WeekStats>> _getWeekStatsRpc(String userId, {String? farmId}) async {
    try {
      final params = farmId != null ? {'p_farm_id': farmId} : {'p_user_id': userId};
      final result = await _client.rpc('get_week_stats', params: params);
      final data = (result as List).isNotEmpty ? result[0] : {};

      final expenses = (data['expenses'] as num?)?.toDouble() ?? 0.0;
      final revenue = (data['revenue'] as num?)?.toDouble() ?? 0.0;

      return Result.success(WeekStats(
        eggsCollected: (data['eggs_collected'] as num?)?.toInt() ?? 0,
        eggsConsumed: (data['eggs_consumed'] as num?)?.toInt() ?? 0,
        eggsSold: (data['eggs_sold'] as num?)?.toInt() ?? 0,
        revenue: revenue,
        expenses: expenses,
        netProfit: revenue - expenses,
        startDate: data['start_date']?.toString() ?? '',
        endDate: data['end_date']?.toString() ?? '',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get week statistics using manual aggregation (fallback)
  Future<Result<WeekStats>> _getWeekStatsManual(String userId, {String? farmId}) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final startDate = _formatDate(weekAgo);
      final endDate = _formatDate(now);

      // Build queries with farm_id or user_id filter
      var eggQuery = _client.from('daily_egg_records').select();
      var salesQuery = _client.from('egg_sales').select();
      var expQuery = _client.from('expenses').select();
      var vetQuery = _client.from('vet_records').select('cost');

      if (farmId != null) {
        eggQuery = eggQuery.eq('farm_id', farmId);
        salesQuery = salesQuery.eq('farm_id', farmId);
        expQuery = expQuery.eq('farm_id', farmId);
        vetQuery = vetQuery.eq('farm_id', farmId);
      } else {
        eggQuery = eggQuery.eq('user_id', userId);
        salesQuery = salesQuery.eq('user_id', userId);
        expQuery = expQuery.eq('user_id', userId);
        vetQuery = vetQuery.eq('user_id', userId);
      }

      // Run all queries in parallel - they are independent
      final results = await Future.wait([
        eggQuery.gte('date', startDate).lte('date', endDate),
        salesQuery.gte('date', startDate).lte('date', endDate),
        expQuery.gte('date', startDate).lte('date', endDate),
        vetQuery.gte('date', startDate).lte('date', endDate),
      ]);

      // Process egg records
      int eggsCollected = 0;
      int eggsConsumed = 0;
      for (final r in results[0] as List) {
        eggsCollected += (r['eggs_collected'] as num?)?.toInt() ?? 0;
        eggsConsumed += (r['eggs_consumed'] as num?)?.toInt() ?? 0;
      }

      // Process sales
      int eggsSold = 0;
      double revenue = 0;
      for (final s in results[1] as List) {
        eggsSold += (s['quantity_sold'] as num?)?.toInt() ?? 0;
        revenue += (s['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Process expenses
      double totalExpenses = 0;
      for (final e in results[2] as List) {
        totalExpenses += (e['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Add vet costs
      for (final v in results[3] as List) {
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
  Future<Result<ProductionSummary>> getProductionAnalytics(String userId, {String? farmId}) async {
    try {
      return Result.success(await _getProductionSummary(userId, farmId: farmId));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get sales analytics
  Future<Result<SalesSummary>> getSalesAnalytics(String userId, {String? farmId}) async {
    try {
      return Result.success(await _getSalesSummary(userId, farmId: farmId));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get expenses analytics
  Future<Result<ExpensesSummary>> getExpensesAnalytics(String userId, {String? farmId}) async {
    try {
      final sales = await _getSalesSummary(userId, farmId: farmId);
      return Result.success(await _getExpensesSummary(userId, sales.totalRevenue, farmId: farmId));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get feed analytics
  Future<Result<FeedSummary>> getFeedAnalytics(String userId, {String? farmId}) async {
    try {
      final production = await _getProductionSummary(userId, farmId: farmId);
      return Result.success(await _getFeedSummary(userId, production.totalCollected, farmId: farmId));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get health analytics
  Future<Result<HealthSummary>> getHealthAnalytics(String userId, {String? farmId}) async {
    try {
      return Result.success(await _getHealthSummary(userId, farmId: farmId));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
