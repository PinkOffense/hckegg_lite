import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/date_constants.dart';
import '../core/models/week_stats.dart';
import '../state/providers/providers.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
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

  // Cache today's date string (computed once per page lifecycle)
  late final String _todayString = _computeTodayString();

  String _computeTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date, String locale) {
    return DateConstants.formatMonthDay(date, locale);
  }

  Future<void> _exportDashboard(BuildContext context, String locale) async {
    final eggProvider = context.read<EggRecordProvider>();
    final saleProvider = context.read<SaleProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final reservationProvider = context.read<ReservationProvider>();

    final todayRecord = eggProvider.getRecordByDate(_todayString);
    final weekStats = eggProvider.getWeekStats(
      sales: saleProvider.sales,
      expenses: expenseProvider.expenses,
    );
    final recentRecords = eggProvider.getRecentRecords(7);
    final availableEggs = eggProvider.totalEggsCollected - eggProvider.totalEggsConsumed - saleProvider.totalEggsSold;
    final reservedEggs = reservationProvider.reservations.fold<int>(0, (sum, r) => sum + r.quantity);

    try {
      final exportService = DashboardExportService();
      await exportService.exportToPdf(
        locale: locale,
        todayEggs: todayRecord?.eggsCollected ?? 0,
        weekStats: weekStats,
        recentRecords: recentRecords,
        availableEggs: availableEggs,
        reservedEggs: reservedEggs,
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Consumer4<EggRecordProvider, SaleProvider, ExpenseProvider, ReservationProvider>(
            builder: (context, eggProvider, saleProvider, expenseProvider, reservationProvider, _) {
              final records = eggProvider.records;
              final sales = saleProvider.sales;
              final todayRecord = eggProvider.getRecordByDate(_todayString);
              final weekStats = eggProvider.getWeekStats(
                sales: sales,
                expenses: expenseProvider.expenses,
              );
              final recentRecords = eggProvider.getRecentRecords(7);
              final recentSales = saleProvider.getRecentSales(7);

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

            return SingleChildScrollView(
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
                  const SizedBox(height: 20),

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
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
