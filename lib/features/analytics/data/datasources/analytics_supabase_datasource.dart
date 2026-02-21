import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/context/farm_context.dart';
import '../../domain/entities/analytics_data.dart';

/// Supabase implementation of analytics datasource
/// Computes analytics locally from raw data
class AnalyticsSupabaseDataSource {
  final SupabaseClient _client;

  AnalyticsSupabaseDataSource(this._client);

  String? get _farmId => FarmContext().farmId;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.id;
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _weekAgoStr() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
  }

  String _monthAgoStr() {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return '${monthAgo.year}-${monthAgo.month.toString().padLeft(2, '0')}-${monthAgo.day.toString().padLeft(2, '0')}';
  }

  PostgrestFilterBuilder _filterByFarm(PostgrestFilterBuilder query) {
    if (_farmId != null) {
      return query.eq('farm_id', _farmId!);
    }
    return query.eq('user_id', _userId);
  }

  /// Get complete dashboard analytics
  Future<DashboardAnalytics> getDashboardAnalytics() async {
    final results = await Future.wait([
      getProductionAnalytics(),
      getSalesAnalytics(),
      getExpensesAnalytics(),
      getFeedAnalytics(),
      getHealthAnalytics(),
    ]);

    final production = results[0] as ProductionSummary;
    final sales = results[1] as SalesSummary;
    final expenses = results[2] as ExpensesSummary;
    final feed = results[3] as FeedSummary;
    final health = results[4] as HealthSummary;

    // Generate alerts based on the data
    final alerts = _generateAlerts(production, sales, expenses, feed, health);

    return DashboardAnalytics(
      production: production,
      sales: sales,
      expenses: expenses,
      feed: feed,
      health: health,
      alerts: alerts,
    );
  }

  /// Get week statistics
  Future<WeekStats> getWeekStats() async {
    final today = _todayStr();
    final weekAgo = _weekAgoStr();

    // Get eggs data for the week
    var eggsQuery = _client.from('daily_egg_records').select();
    eggsQuery = _filterByFarm(eggsQuery);
    final eggsData = await eggsQuery.gte('date', weekAgo).lte('date', today);

    int eggsCollected = 0;
    int eggsConsumed = 0;
    for (final record in eggsData) {
      eggsCollected += (record['collected'] as int?) ?? 0;
      eggsConsumed += (record['consumed'] as int?) ?? 0;
    }

    // Get sales for the week
    var salesQuery = _client.from('egg_sales').select();
    salesQuery = _filterByFarm(salesQuery);
    final salesData = await salesQuery.gte('date', weekAgo).lte('date', today);

    int eggsSold = 0;
    double revenue = 0;
    for (final sale in salesData) {
      eggsSold += (sale['quantity'] as int?) ?? 0;
      revenue += ((sale['total_amount'] as num?) ?? 0).toDouble();
    }

    // Get expenses for the week
    var expensesQuery = _client.from('expenses').select();
    expensesQuery = _filterByFarm(expensesQuery);
    final expensesData = await expensesQuery.gte('date', weekAgo).lte('date', today);

    double expenses = 0;
    for (final expense in expensesData) {
      expenses += ((expense['amount'] as num?) ?? 0).toDouble();
    }

    return WeekStats(
      eggsCollected: eggsCollected,
      eggsConsumed: eggsConsumed,
      eggsSold: eggsSold,
      revenue: revenue,
      expenses: expenses,
      netProfit: revenue - expenses,
      startDate: weekAgo,
      endDate: today,
    );
  }

  /// Get production analytics
  Future<ProductionSummary> getProductionAnalytics() async {
    final today = _todayStr();
    final weekAgo = _weekAgoStr();

    // Get all egg records
    var query = _client.from('daily_egg_records').select();
    query = _filterByFarm(query);
    final allData = await query.order('date', ascending: false);

    int totalCollected = 0;
    int totalConsumed = 0;
    int todayCollected = 0;
    int todayConsumed = 0;

    for (final record in allData) {
      final collected = (record['collected'] as int?) ?? 0;
      final consumed = (record['consumed'] as int?) ?? 0;
      totalCollected += collected;
      totalConsumed += consumed;

      if (record['date'] == today) {
        todayCollected = collected;
        todayConsumed = consumed;
      }
    }

    // Get sales to calculate remaining
    var salesQuery = _client.from('egg_sales').select();
    salesQuery = _filterByFarm(salesQuery);
    final salesData = await salesQuery;

    int totalSold = 0;
    for (final sale in salesData) {
      totalSold += (sale['quantity'] as int?) ?? 0;
    }

    // Calculate week average
    var weekQuery = _client.from('daily_egg_records').select();
    weekQuery = _filterByFarm(weekQuery);
    final weekData = await weekQuery.gte('date', weekAgo).lte('date', today);

    double weekTotal = 0;
    for (final record in weekData) {
      weekTotal += ((record['collected'] as int?) ?? 0).toDouble();
    }
    final weekAverage = weekData.isEmpty ? 0.0 : weekTotal / weekData.length;

    return ProductionSummary(
      totalCollected: totalCollected,
      totalConsumed: totalConsumed,
      totalRemaining: totalCollected - totalConsumed - totalSold,
      todayCollected: todayCollected,
      todayConsumed: todayConsumed,
      weekAverage: weekAverage,
    );
  }

  /// Get sales analytics
  Future<SalesSummary> getSalesAnalytics() async {
    final today = _todayStr();
    final weekAgo = _weekAgoStr();
    final monthAgo = _monthAgoStr();

    // Get all sales
    var query = _client.from('egg_sales').select();
    query = _filterByFarm(query);
    final allData = await query.order('date', ascending: false);

    int totalQuantity = 0;
    double totalRevenue = 0;
    double paidAmount = 0;
    double pendingAmount = 0;
    double advanceAmount = 0;
    double lostAmount = 0;

    for (final sale in allData) {
      final quantity = (sale['quantity'] as int?) ?? 0;
      final amount = ((sale['total_amount'] as num?) ?? 0).toDouble();
      final status = sale['payment_status'] as String? ?? 'pending';
      final isLost = sale['is_lost'] as bool? ?? false;

      totalQuantity += quantity;
      totalRevenue += amount;

      if (isLost) {
        lostAmount += amount;
      } else if (status == 'paid') {
        paidAmount += amount;
      } else if (status == 'advance') {
        advanceAmount += amount;
      } else {
        pendingAmount += amount;
      }
    }

    // Week revenue
    var weekQuery = _client.from('egg_sales').select();
    weekQuery = _filterByFarm(weekQuery);
    final weekData = await weekQuery.gte('date', weekAgo).lte('date', today);

    double weekRevenue = 0;
    for (final sale in weekData) {
      weekRevenue += ((sale['total_amount'] as num?) ?? 0).toDouble();
    }

    // Month revenue
    var monthQuery = _client.from('egg_sales').select();
    monthQuery = _filterByFarm(monthQuery);
    final monthData = await monthQuery.gte('date', monthAgo).lte('date', today);

    double monthRevenue = 0;
    for (final sale in monthData) {
      monthRevenue += ((sale['total_amount'] as num?) ?? 0).toDouble();
    }

    return SalesSummary(
      totalQuantity: totalQuantity,
      totalRevenue: totalRevenue,
      averagePricePerEgg: totalQuantity > 0 ? totalRevenue / totalQuantity : 0,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      advanceAmount: advanceAmount,
      lostAmount: lostAmount,
      weekRevenue: weekRevenue,
      monthRevenue: monthRevenue,
    );
  }

  /// Get expenses analytics
  Future<ExpensesSummary> getExpensesAnalytics() async {
    final today = _todayStr();
    final weekAgo = _weekAgoStr();
    final monthAgo = _monthAgoStr();

    // Get all expenses
    var query = _client.from('expenses').select();
    query = _filterByFarm(query);
    final allData = await query.order('date', ascending: false);

    double totalExpenses = 0;
    final byCategory = <String, double>{};

    for (final expense in allData) {
      final amount = ((expense['amount'] as num?) ?? 0).toDouble();
      final category = expense['category'] as String? ?? 'other';

      totalExpenses += amount;
      byCategory[category] = (byCategory[category] ?? 0) + amount;
    }

    // Week expenses
    var weekQuery = _client.from('expenses').select();
    weekQuery = _filterByFarm(weekQuery);
    final weekData = await weekQuery.gte('date', weekAgo).lte('date', today);

    double weekExpenses = 0;
    for (final expense in weekData) {
      weekExpenses += ((expense['amount'] as num?) ?? 0).toDouble();
    }

    // Month expenses
    var monthQuery = _client.from('expenses').select();
    monthQuery = _filterByFarm(monthQuery);
    final monthData = await monthQuery.gte('date', monthAgo).lte('date', today);

    double monthExpenses = 0;
    for (final expense in monthData) {
      monthExpenses += ((expense['amount'] as num?) ?? 0).toDouble();
    }

    // Get total sales for net profit calculation
    var salesQuery = _client.from('egg_sales').select();
    salesQuery = _filterByFarm(salesQuery);
    final salesData = await salesQuery;

    double totalRevenue = 0;
    for (final sale in salesData) {
      totalRevenue += ((sale['total_amount'] as num?) ?? 0).toDouble();
    }

    return ExpensesSummary(
      totalExpenses: totalExpenses,
      byCategory: byCategory,
      weekExpenses: weekExpenses,
      monthExpenses: monthExpenses,
      netProfit: totalRevenue - totalExpenses,
    );
  }

  /// Get feed analytics
  Future<FeedSummary> getFeedAnalytics() async {
    // Get all feed stocks
    var query = _client.from('feed_stocks').select();
    query = _filterByFarm(query);
    final allData = await query;

    double totalStockKg = 0;
    int lowStockCount = 0;
    final byType = <String, double>{};

    for (final stock in allData) {
      final currentQty = ((stock['current_quantity'] as num?) ?? 0).toDouble();
      final minQty = ((stock['minimum_quantity'] as num?) ?? 0).toDouble();
      final feedType = stock['feed_type'] as String? ?? 'other';

      totalStockKg += currentQty;
      byType[feedType] = (byType[feedType] ?? 0) + currentQty;

      if (currentQty <= minQty) {
        lowStockCount++;
      }
    }

    // Get feed movements for consumed calculation
    var movementsQuery = _client.from('feed_movements').select();
    if (_farmId != null) {
      movementsQuery = movementsQuery.eq('farm_id', _farmId!);
    } else {
      movementsQuery = movementsQuery.eq('user_id', _userId);
    }
    final movementsData = await movementsQuery.eq('type', 'usage');

    double totalConsumedKg = 0;
    for (final movement in movementsData) {
      totalConsumedKg += ((movement['quantity'] as num?) ?? 0).toDouble();
    }

    // Estimate days remaining (based on average daily consumption)
    int estimatedDaysRemaining = 0;
    if (totalConsumedKg > 0) {
      // Calculate average daily consumption from movements in last 30 days
      final monthAgo = _monthAgoStr();
      var recentMovementsQuery = _client.from('feed_movements').select();
      if (_farmId != null) {
        recentMovementsQuery = recentMovementsQuery.eq('farm_id', _farmId!);
      } else {
        recentMovementsQuery = recentMovementsQuery.eq('user_id', _userId);
      }
      final recentData = await recentMovementsQuery
          .eq('type', 'usage')
          .gte('date', monthAgo);

      double recentConsumption = 0;
      for (final movement in recentData) {
        recentConsumption += ((movement['quantity'] as num?) ?? 0).toDouble();
      }

      final avgDailyConsumption = recentConsumption / 30;
      if (avgDailyConsumption > 0) {
        estimatedDaysRemaining = (totalStockKg / avgDailyConsumption).round();
      }
    }

    return FeedSummary(
      totalStockKg: totalStockKg,
      totalConsumedKg: totalConsumedKg,
      lowStockCount: lowStockCount,
      estimatedDaysRemaining: estimatedDaysRemaining,
      byType: byType,
    );
  }

  /// Get health analytics
  Future<HealthSummary> getHealthAnalytics() async {
    final today = _todayStr();
    final monthAgo = _monthAgoStr();

    // Get all vet records
    var query = _client.from('vet_records').select();
    query = _filterByFarm(query);
    final allData = await query;

    int totalDeaths = 0;
    int totalAffected = 0;
    double totalVetCosts = 0;

    for (final record in allData) {
      totalDeaths += (record['deaths'] as int?) ?? 0;
      totalAffected += (record['affected_count'] as int?) ?? 0;
      totalVetCosts += ((record['cost'] as num?) ?? 0).toDouble();
    }

    // Get upcoming actions
    var upcomingQuery = _client.from('vet_records').select();
    upcomingQuery = _filterByFarm(upcomingQuery);
    final upcomingData = await upcomingQuery
        .not('next_action_date', 'is', null)
        .gte('next_action_date', today);

    // Get recent records (last 30 days)
    var recentQuery = _client.from('vet_records').select();
    recentQuery = _filterByFarm(recentQuery);
    final recentData = await recentQuery.gte('date', monthAgo);

    return HealthSummary(
      totalDeaths: totalDeaths,
      totalAffected: totalAffected,
      totalVetCosts: totalVetCosts,
      upcomingActions: upcomingData.length,
      recentRecords: recentData.length,
    );
  }

  /// Generate alerts based on the data
  List<DashboardAlert> _generateAlerts(
    ProductionSummary production,
    SalesSummary sales,
    ExpensesSummary expenses,
    FeedSummary feed,
    HealthSummary health,
  ) {
    final alerts = <DashboardAlert>[];

    // Low feed stock alert
    if (feed.lowStockCount > 0) {
      alerts.add(DashboardAlert(
        type: 'feed_low',
        severity: feed.lowStockCount > 2 ? 'high' : 'medium',
        title: 'Low Feed Stock',
        message: '${feed.lowStockCount} feed items are running low',
      ));
    }

    // Pending payments alert
    if (sales.pendingAmount > 0) {
      alerts.add(DashboardAlert(
        type: 'pending_payments',
        severity: sales.pendingAmount > 100 ? 'medium' : 'low',
        title: 'Pending Payments',
        message: '${sales.pendingAmount.toStringAsFixed(2)} in pending payments',
      ));
    }

    // Upcoming vet actions
    if (health.upcomingActions > 0) {
      alerts.add(DashboardAlert(
        type: 'vet_upcoming',
        severity: 'low',
        title: 'Upcoming Vet Actions',
        message: '${health.upcomingActions} upcoming vet actions',
      ));
    }

    // Production decline alert (if today's production is significantly lower than average)
    if (production.weekAverage > 0 && production.todayCollected < production.weekAverage * 0.5) {
      alerts.add(DashboardAlert(
        type: 'production_low',
        severity: 'medium',
        title: 'Low Production',
        message: 'Today\'s production is below average',
      ));
    }

    return alerts;
  }
}
