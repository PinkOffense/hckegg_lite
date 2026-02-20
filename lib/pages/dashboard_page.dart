import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/date_constants.dart';
import '../state/providers/providers.dart';
import '../features/eggs/presentation/providers/egg_provider.dart';
import '../features/analytics/domain/entities/analytics_data.dart' as analytics;
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/gradient_fab.dart';
import '../dialogs/daily_record_dialog.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../models/daily_egg_record.dart';
import '../widgets/charts/production_chart.dart';
import '../widgets/charts/revenue_chart.dart';
import '../widgets/charts/revenue_vs_expenses_chart.dart';
import '../services/dashboard_export_service.dart';

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
    final vetProvider = context.read<VetProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();

    await Future.wait([
      eggProvider.loadRecords(),
      saleProvider.loadSales(),
      expenseProvider.loadExpenses(),
      reservationProvider.loadReservations(),
      feedStockProvider.loadFeedStocks(),
      vetProvider.loadRecords(),
      analyticsProvider.loadDashboardAnalytics(),
    ]).timeout(const Duration(seconds: 15), onTimeout: () => []);
  }

  // Compute today's date fresh each time (handles midnight rollover)
  String get _todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date, String locale) {
    return DateConstants.formatMonthDay(date, locale);
  }

  Future<void> _exportDashboard(BuildContext context, String locale) async {
    final t = (String k) => Translations.of(locale, k);
    final eggProvider = context.read<EggProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();

    final todayRecord = eggProvider.getRecordByDate(_todayString);
    final recentRecords = eggProvider.getRecentRecords(7);
    final dashboard = analyticsProvider.dashboard;

    try {
      await _exportService.exportToPdfFromAnalytics(
        locale: locale,
        todayEggs: todayRecord?.eggsCollected ?? 0,
        recentRecords: recentRecords,
        dashboard: dashboard,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('export_error').replaceAll('{e}', e.toString())),
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
          tooltip: t('export_pdf'),
          onPressed: () => _exportDashboard(context, locale),
        ),
      ],
      fab: GradientFAB(
        icon: Icons.add,
        label: t('new_record'),
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
          child: Consumer3<EggProvider, SaleProvider, AnalyticsProvider>(
            builder: (context, eggProvider, saleProvider, analyticsProvider, _) {
              // Show loading skeleton on initial load
              final isLoading = eggProvider.state == EggState.loading || analyticsProvider.isLoading;
              if (isLoading && eggProvider.records.isEmpty) {
                return const SkeletonPage(showStats: true, showChart: true, listItemCount: 3);
              }

              // Show error state with retry option
              final hasError = eggProvider.hasError || analyticsProvider.hasError;
              if (hasError && eggProvider.records.isEmpty) {
                return _ErrorView(
                  locale: locale,
                  errorMessage: eggProvider.errorMessage ?? analyticsProvider.errorMessage,
                  onRetry: _onRefresh,
                );
              }

              final records = eggProvider.records;
              final todayRecord = eggProvider.getRecordByDate(_todayString);
              final recentRecords = eggProvider.getRecentRecords(7);
              final recentSales = saleProvider.getRecentSales(7);

              // Analytics from backend
              final dashboard = analyticsProvider.dashboard;
              final weekStatsData = analyticsProvider.weekStats;

            // Get reservation provider for reserved count (read, not watch -
            // to avoid rebuilding entire dashboard when reservations change)
            final reservationProvider = context.read<ReservationProvider>();

            if (records.isEmpty) {
              return ChickenEmptyState(
                title: t('no_records_yet'),
                message: t('start_tracking'),
                actionLabel: t('add_todays_record'),
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
                                t('todays_collection'),
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

                  // Tomorrow's Prediction (from backend)
                  if (dashboard.production.prediction != null)
                    _PredictionCardFromApi(prediction: dashboard.production.prediction!, locale: locale),

                  // Today's Alerts (from backend)
                  if (dashboard.alerts.isNotEmpty)
                    _AlertsCardFromApi(alerts: dashboard.alerts, locale: locale),

                  const SizedBox(height: 8),

                  // This Week's Stats (from backend)
                  Text(
                    t('this_week'),
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
                          label: t('collected'),
                          value: '${weekStatsData.eggsCollected}',
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.sell,
                          label: t('sold'),
                          value: '${weekStatsData.eggsSold}',
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
                          label: t('consumed'),
                          value: '${weekStatsData.eggsConsumed}',
                          color: colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.euro,
                          label: t('revenue'),
                          value: '€${weekStatsData.revenue.toStringAsFixed(2)}',
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
                          label: t('available'),
                          value: '${dashboard.production.totalRemaining}',
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.bookmark,
                          label: t('reserved'),
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
                          label: t('expenses'),
                          value: '€${weekStatsData.expenses.toStringAsFixed(2)}',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: weekStatsData.netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                          label: t('net_profit'),
                          value: '€${weekStatsData.netProfit.toStringAsFixed(2)}',
                          color: weekStatsData.netProfit >= 0 ? Colors.green : Colors.red,
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
                                label: t('revenue'),
                              ),
                              const SizedBox(width: 24),
                              _ChartLegend(
                                color: Colors.red,
                                label: t('expenses'),
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
                        onPressed: () => context.go('/eggs'),
                        child: Text(t('view_all')),
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
    final t = (String k) => Translations.of(locale, k);
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(recordDate).inDays;

    if (difference == 0) return t('today');
    if (difference == 1) return t('yesterday');

    return locale == 'pt'
        ? DateConstants.formatDayMonth(date, locale)
        : DateConstants.formatMonthDay(date, locale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final t = (String k) => Translations.of(locale, k);

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
                            '${record.eggsConsumed} ${t('eaten')}',
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

/// Prediction card using backend analytics data
class _PredictionCardFromApi extends StatelessWidget {
  final analytics.ProductionPrediction prediction;
  final String locale;

  const _PredictionCardFromApi({
    required this.prediction,
    required this.locale,
  });

  String _getTrendIcon() {
    switch (prediction.trend) {
      case 'up':
        return '↑';
      case 'down':
        return '↓';
      default:
        return '→';
    }
  }

  String _getConfidenceLabel(String Function(String) t) {
    if (prediction.confidence >= 0.8) {
      return t('severity_high');
    } else if (prediction.confidence >= 0.5) {
      return t('severity_medium');
    } else {
      return t('severity_low');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = (String k, {Map<String, String>? params}) =>
        Translations.of(locale, k, params: params);

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
                    t('tomorrow_prediction'),
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
                        '${t('eggs_unit')} ${_getTrendIcon()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('prediction_range', params: {
                      'min': '${prediction.minEggs}',
                      'max': '${prediction.maxEggs}',
                      'confidence': _getConfidenceLabel((k) => Translations.of(locale, k)),
                    }),
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

/// Alerts card using backend analytics data
class _AlertsCardFromApi extends StatelessWidget {
  final List<analytics.DashboardAlert> alerts;
  final String locale;

  const _AlertsCardFromApi({
    required this.alerts,
    required this.locale,
  });

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'low_stock':
        return Icons.inventory_2;
      case 'reservation':
        return Icons.bookmark;
      case 'vet':
        return Icons.medical_services;
      case 'production':
        return Icons.trending_down;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = (String k, {Map<String, String>? params}) =>
        Translations.of(locale, k, params: params);

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
                        t('todays_alerts'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                      Text(
                        alerts.length == 1
                            ? t('items_to_check_singular')
                            : t('items_to_check_plural', params: {'count': '${alerts.length}'}),
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
            ...alerts.map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _getAlertIcon(alert.type),
                    size: 18,
                    color: _getSeverityColor(alert.severity),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          alert.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Error view with retry button
class _ErrorView extends StatelessWidget {
  final String locale;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.locale,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = (String k) => Translations.of(locale, k);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              t('connection_error'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('unable_to_load'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(t('try_again')),
            ),
          ],
        ),
      ),
    );
  }
}
