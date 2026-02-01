import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/date_constants.dart';
import '../core/models/week_stats.dart';
import '../state/providers/providers.dart';
import '../features/eggs/presentation/providers/egg_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/gradient_fab.dart';
import '../dialogs/daily_record_dialog.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../models/daily_egg_record.dart';
import '../models/feed_stock.dart';
import '../widgets/charts/production_chart.dart';
import '../widgets/charts/revenue_chart.dart';
import '../widgets/charts/revenue_vs_expenses_chart.dart';
import '../services/dashboard_export_service.dart';
import '../services/production_analytics_service.dart';
import '../core/date_utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Services - created once, reused
  final _analyticsService = ProductionAnalyticsService();
  final _exportService = DashboardExportService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final eggProvider = context.read<EggProvider>();
    final saleProvider = context.read<SaleProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final reservationProvider = context.read<ReservationProvider>();
    final feedStockProvider = context.read<FeedStockProvider>();
    final vetRecordProvider = context.read<VetRecordProvider>();

    await Future.wait([
      eggProvider.loadRecords(),
      saleProvider.loadSales(),
      expenseProvider.loadExpenses(),
      reservationProvider.loadReservations(),
      feedStockProvider.loadFeedStocks(),
      vetRecordProvider.loadRecords(),
    ]);
  }

  // Cache today's date string (computed once per page lifecycle)
  late final String _todayString = _computeTodayString();

  String _computeTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date, String locale) {
    return DateConstants.formatMonthDay(date, locale);
  }

  /// Build consolidated today's alerts data from multiple providers
  TodayAlertsData _buildTodayAlertsData({
    required FeedStockProvider feedStockProvider,
    required ReservationProvider reservationProvider,
    required VetRecordProvider vetRecordProvider,
  }) {
    final now = DateTime.now();
    final todayStr = AppDateUtils.toIsoDateString(now);
    final tomorrowStr = AppDateUtils.toIsoDateString(now.add(const Duration(days: 1)));

    // Feed stock alerts (low stock or any stock for visibility)
    final feedAlerts = <FeedStockAlertItem>[];
    for (final stock in feedStockProvider.feedStocks) {
      // Estimate days remaining based on average consumption
      // Assume ~0.12-0.15 kg/hen/day, but we'll use a simple calculation
      final estimatedDays = stock.currentQuantityKg > 0
          ? (stock.currentQuantityKg / 0.5).round().clamp(0, 999) // rough estimate
          : 0;

      if (stock.isLowStock || estimatedDays <= 7) {
        feedAlerts.add(FeedStockAlertItem(
          feedType: stock.type,
          currentKg: stock.currentQuantityKg,
          estimatedDaysRemaining: estimatedDays,
          isLowStock: stock.isLowStock,
        ));
      }
    }

    // Reservation alerts (today and tomorrow)
    final reservationAlerts = <ReservationAlertItem>[];
    for (final reservation in reservationProvider.reservations) {
      if (reservation.date == todayStr || reservation.date == tomorrowStr) {
        reservationAlerts.add(ReservationAlertItem(
          customerName: reservation.customerName ?? 'Unknown',
          quantity: reservation.quantity,
          date: reservation.date,
          isToday: reservation.date == todayStr,
        ));
      }
    }

    // Vet appointment alerts (today)
    final vetAlerts = <VetAppointmentAlertItem>[];
    for (final record in vetRecordProvider.getTodayAppointments()) {
      vetAlerts.add(VetAppointmentAlertItem(
        description: record.description,
        date: record.nextActionDate ?? todayStr,
        hensAffected: record.hensAffected,
      ));
    }

    return TodayAlertsData(
      feedAlerts: feedAlerts,
      reservationAlerts: reservationAlerts,
      vetAlerts: vetAlerts,
    );
  }

  Future<void> _exportDashboard(BuildContext context, String locale) async {
    final eggProvider = context.read<EggProvider>();
    final saleProvider = context.read<SaleProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final reservationProvider = context.read<ReservationProvider>();
    final feedStockProvider = context.read<FeedStockProvider>();
    final vetRecordProvider = context.read<VetRecordProvider>();

    final todayRecord = eggProvider.getRecordByDate(_todayString);
    final weekStats = eggProvider.getWeekStats(
      sales: saleProvider.sales,
      expenses: expenseProvider.expenses,
    );
    final recentRecords = eggProvider.getRecentRecords(7);
    final availableEggs = eggProvider.totalEggsCollected - eggProvider.totalEggsConsumed - saleProvider.totalEggsSold;
    final reservedEggs = reservationProvider.reservations.fold<int>(0, (sum, r) => sum + r.quantity);

    // Get prediction and alert for PDF
    final prediction = _analyticsService.predictTomorrow(eggProvider.records);
    final alert = _analyticsService.checkProductionDrop(eggProvider.records);

    // Get today's alerts for PDF
    final todayAlertsData = _buildTodayAlertsData(
      feedStockProvider: feedStockProvider,
      reservationProvider: reservationProvider,
      vetRecordProvider: vetRecordProvider,
    );

    try {
      await _exportService.exportToPdf(
        locale: locale,
        todayEggs: todayRecord?.eggsCollected ?? 0,
        weekStats: weekStats,
        recentRecords: recentRecords,
        availableEggs: availableEggs,
        reservedEggs: reservedEggs,
        prediction: prediction,
        alert: alert,
        todayAlerts: todayAlertsData,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale == 'pt' ? 'Erro ao exportar: $e' : 'Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      title: t('dashboard'),
      additionalActions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: locale == 'pt' ? 'Exportar PDF' : 'Export PDF',
          onPressed: () => _exportDashboard(context, locale),
        ),
      ],
      fab: GradientFAB(
        icon: Icons.add,
        label: locale == 'pt' ? 'Novo Registo' : 'New Record',
        extended: true,
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const DailyRecordDialog(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Consumer6<EggProvider, SaleProvider, ExpenseProvider, ReservationProvider, FeedStockProvider, VetRecordProvider>(
            builder: (context, eggProvider, saleProvider, expenseProvider, reservationProvider, feedStockProvider, vetRecordProvider, _) {
              // Show loading skeleton on initial load
              if (eggProvider.state == EggState.loading && eggProvider.records.isEmpty) {
                return const SkeletonPage(showStats: true, showChart: true, listItemCount: 3);
              }

              final records = eggProvider.records;
              final sales = saleProvider.sales;
              final todayRecord = eggProvider.getRecordByDate(_todayString);
              final weekStats = eggProvider.getWeekStats(
                sales: sales,
                expenses: expenseProvider.expenses,
              );
              final recentRecords = eggProvider.getRecentRecords(7);
              final recentSales = saleProvider.getRecentSales(7);

              // Analytics
              final prediction = _analyticsService.predictTomorrow(records);
              final alert = _analyticsService.checkProductionDrop(records);

              // Build today's alerts data
              final todayAlertsData = _buildTodayAlertsData(
                feedStockProvider: feedStockProvider,
                reservationProvider: reservationProvider,
                vetRecordProvider: vetRecordProvider,
              );

            if (records.isEmpty) {
              return ChickenEmptyState(
                title: locale == 'pt' ? 'Sem Registos' : 'No Records Yet',
                message: locale == 'pt'
                    ? 'Comece a registar a sua recolha diária de ovos'
                    : 'Start tracking your daily egg collection',
                actionLabel: locale == 'pt' ? 'Adicionar Registo de Hoje' : 'Add Today\'s Record',
                onAction: () => showDialog(
                  context: context,
                  builder: (_) => const DailyRecordDialog(),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Collection - Big Number
                  Card(
                    elevation: 4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer.withValues(alpha: 0.3),
                            colorScheme.primaryContainer.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.egg,
                                size: 32,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                locale == 'pt' ? 'Recolha de Hoje' : 'Today\'s Collection',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${todayRecord?.eggsCollected ?? 0}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(DateTime.now(), locale),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Production Alert (if any)
                  if (alert != null)
                    _ProductionAlertCard(alert: alert, locale: locale),

                  // Tomorrow's Prediction
                  if (prediction != null)
                    _PredictionCard(prediction: prediction, locale: locale),

                  // Today's Consolidated Alerts
                  _TodayAlertsCard(alertsData: todayAlertsData, locale: locale),

                  const SizedBox(height: 8),

                  // This Week's Stats
                  Text(
                    locale == 'pt' ? 'Esta Semana' : 'This Week',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.egg,
                          label: locale == 'pt' ? 'Recolhidos' : 'Collected',
                          value: '${weekStats.collected}',
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.sell,
                          label: locale == 'pt' ? 'Vendidos' : 'Sold',
                          value: '${weekStats.sold}',
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.restaurant,
                          label: locale == 'pt' ? 'Consumidos' : 'Consumed',
                          value: '${weekStats.consumed}',
                          color: colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.euro,
                          label: locale == 'pt' ? 'Receita' : 'Revenue',
                          value: '€${weekStats.revenue.toStringAsFixed(2)}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Inventory Stats (Available for Sale & Reserved)
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.inventory,
                          label: locale == 'pt' ? 'Disponíveis' : 'Available',
                          value: '${eggProvider.totalEggsCollected - eggProvider.totalEggsConsumed - saleProvider.totalEggsSold}',
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.bookmark,
                          label: locale == 'pt' ? 'Reservados' : 'Reserved',
                          value: '${reservationProvider.reservations.fold<int>(0, (sum, r) => sum + r.quantity)}',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Financial Stats (Expenses & Net Profit)
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.trending_down,
                          label: locale == 'pt' ? 'Despesas' : 'Expenses',
                          value: '€${weekStats.expenses.toStringAsFixed(2)}',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: weekStats.hasProfit ? Icons.trending_up : Icons.trending_down,
                          label: locale == 'pt' ? 'Lucro Líquido' : 'Net Profit',
                          value: '€${weekStats.netProfit.toStringAsFixed(2)}',
                          color: weekStats.hasProfit ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Production Chart
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.bar_chart, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                t('production_chart'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ProductionChart(
                          records: recentRecords,
                          locale: locale,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Revenue Chart
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.euro, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                t('revenue_chart'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RevenueChart(
                          sales: recentSales,
                          locale: locale,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Revenue vs Expenses Chart
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.compare_arrows, color: theme.colorScheme.secondary),
                              const SizedBox(width: 8),
                              Text(
                                t('revenue_vs_expenses'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RevenueVsExpensesChart(
                          sales: recentSales,
                          locale: locale,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ChartLegend(
                                color: Colors.green,
                                label: locale == 'pt' ? 'Receitas' : 'Revenue',
                              ),
                              const SizedBox(width: 24),
                              _ChartLegend(
                                color: Colors.red,
                                label: locale == 'pt' ? 'Despesas' : 'Expenses',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Last 7 Days
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('last_7_days'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/eggs'),
                        child: Text(locale == 'pt' ? 'Ver Todos' : 'View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...recentRecords.map((record) => _DayRecordCard(
                        record: record,
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => DailyRecordDialog(existingRecord: record),
                        ),
                      )),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label: $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28, semanticLabel: label),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayRecordCard extends StatelessWidget {
  final DailyEggRecord record;
  final VoidCallback onTap;

  const _DayRecordCard({
    required this.record,
    required this.onTap,
  });

  String _formatDate(String dateStr, String locale) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(recordDate).inDays;

    if (difference == 0) return locale == 'pt' ? 'Hoje' : 'Today';
    if (difference == 1) return locale == 'pt' ? 'Ontem' : 'Yesterday';

    return locale == 'pt'
        ? DateConstants.formatDayMonth(date, locale)
        : DateConstants.formatMonthDay(date, locale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${record.eggsCollected}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(record.date, locale),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (record.eggsConsumed > 0) ...[
                          Icon(Icons.restaurant, size: 14, color: theme.textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Text(
                            '${record.eggsConsumed} ${locale == 'pt' ? 'consumidos' : 'eaten'}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final ProductionPrediction prediction;
  final String locale;

  const _PredictionCard({
    required this.prediction,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withValues(alpha: 0.1),
              Colors.blue.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_graph,
                color: Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale == 'pt' ? 'Previsão para Amanhã' : 'Tomorrow\'s Prediction',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '~${prediction.predictedEggs}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        locale == 'pt' ? 'ovos' : 'eggs',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale == 'pt'
                        ? 'Intervalo: ${prediction.minRange}-${prediction.maxRange} • Confiança: ${prediction.confidence.displayName(locale)}'
                        : 'Range: ${prediction.minRange}-${prediction.maxRange} • Confidence: ${prediction.confidence.displayName(locale)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductionAlertCard extends StatelessWidget {
  final ProductionAlert alert;
  final String locale;

  const _ProductionAlertCard({
    required this.alert,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color alertColor;
    final IconData alertIcon;

    switch (alert.severity) {
      case AlertSeverity.high:
        alertColor = Colors.red;
        alertIcon = Icons.warning_rounded;
        break;
      case AlertSeverity.medium:
        alertColor = Colors.orange;
        alertIcon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.low:
        alertColor = Colors.amber;
        alertIcon = Icons.info_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              alertColor.withValues(alpha: 0.15),
              alertColor.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: alertColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: alertColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                alertIcon,
                color: alertColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale == 'pt' ? 'Alerta de Produção' : 'Production Alert',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: alertColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale == 'pt' ? alert.messagePt : alert.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale == 'pt'
                        ? 'Hoje: ${alert.todayValue} ovos • Média: ${alert.averageValue} ovos'
                        : 'Today: ${alert.todayValue} eggs • Average: ${alert.averageValue} eggs',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for consolidated today's alerts
class TodayAlertsData {
  final List<FeedStockAlertItem> feedAlerts;
  final List<ReservationAlertItem> reservationAlerts;
  final List<VetAppointmentAlertItem> vetAlerts;

  TodayAlertsData({
    required this.feedAlerts,
    required this.reservationAlerts,
    required this.vetAlerts,
  });

  bool get hasAlerts =>
      feedAlerts.isNotEmpty ||
      reservationAlerts.isNotEmpty ||
      vetAlerts.isNotEmpty;

  int get totalAlerts =>
      feedAlerts.length + reservationAlerts.length + vetAlerts.length;
}

class FeedStockAlertItem {
  final FeedType feedType;
  final double currentKg;
  final int estimatedDaysRemaining;
  final bool isLowStock;

  FeedStockAlertItem({
    required this.feedType,
    required this.currentKg,
    required this.estimatedDaysRemaining,
    required this.isLowStock,
  });
}

class ReservationAlertItem {
  final String customerName;
  final int quantity;
  final String date;
  final bool isToday;

  ReservationAlertItem({
    required this.customerName,
    required this.quantity,
    required this.date,
    required this.isToday,
  });
}

class VetAppointmentAlertItem {
  final String description;
  final String date;
  final int hensAffected;

  VetAppointmentAlertItem({
    required this.description,
    required this.date,
    required this.hensAffected,
  });
}

class _TodayAlertsCard extends StatelessWidget {
  final TodayAlertsData alertsData;
  final String locale;

  const _TodayAlertsCard({
    required this.alertsData,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!alertsData.hasAlerts) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.withValues(alpha: 0.1),
              Colors.indigo.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: Colors.indigo.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale == 'pt' ? 'Alertas do Dia' : "Today's Alerts",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                      Text(
                        locale == 'pt'
                            ? '${alertsData.totalAlerts} ${alertsData.totalAlerts == 1 ? 'item' : 'itens'} a verificar'
                            : '${alertsData.totalAlerts} ${alertsData.totalAlerts == 1 ? 'item' : 'items'} to check',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Feed Stock Alerts
            if (alertsData.feedAlerts.isNotEmpty) ...[
              _AlertSection(
                icon: Icons.inventory_2,
                iconColor: Colors.orange,
                title: locale == 'pt' ? 'Stock de Ração' : 'Feed Stock',
                children: alertsData.feedAlerts.map((alert) => _AlertItem(
                  text: locale == 'pt'
                      ? '${alert.feedType.displayName('pt')}: ${alert.currentKg.toStringAsFixed(1)}kg (~${alert.estimatedDaysRemaining} dias)'
                      : '${alert.feedType.displayName('en')}: ${alert.currentKg.toStringAsFixed(1)}kg (~${alert.estimatedDaysRemaining} days)',
                  isWarning: alert.isLowStock,
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Reservation Alerts
            if (alertsData.reservationAlerts.isNotEmpty) ...[
              _AlertSection(
                icon: Icons.bookmark,
                iconColor: Colors.blue,
                title: locale == 'pt' ? 'Reservas Pendentes' : 'Pending Reservations',
                children: alertsData.reservationAlerts.map((alert) => _AlertItem(
                  text: locale == 'pt'
                      ? '${alert.customerName}: ${alert.quantity} ovos ${alert.isToday ? "(HOJE)" : "(amanhã)"}'
                      : '${alert.customerName}: ${alert.quantity} eggs ${alert.isToday ? "(TODAY)" : "(tomorrow)"}',
                  isWarning: alert.isToday,
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Vet Appointment Alerts
            if (alertsData.vetAlerts.isNotEmpty) ...[
              _AlertSection(
                icon: Icons.medical_services,
                iconColor: Colors.red,
                title: locale == 'pt' ? 'Consultas Veterinárias' : 'Vet Appointments',
                children: alertsData.vetAlerts.map((alert) => _AlertItem(
                  text: locale == 'pt'
                      ? '${alert.description} (${alert.hensAffected} galinhas)'
                      : '${alert.description} (${alert.hensAffected} hens)',
                  isWarning: true,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _AlertSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String text;
  final bool isWarning;

  const _AlertItem({
    required this.text,
    required this.isWarning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isWarning ? Colors.orange : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isWarning
                    ? theme.textTheme.bodyMedium?.color
                    : theme.textTheme.bodySmall?.color,
                fontWeight: isWarning ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
