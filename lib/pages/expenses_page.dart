import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/providers/providers.dart';
import '../widgets/app_scaffold.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../models/expense.dart';
import '../dialogs/expense_dialog.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final theme = Theme.of(context);

    return AppScaffold(
      title: t('expenses'),
      body: Consumer3<SaleProvider, ExpenseProvider, VetRecordProvider>(
        builder: (context, saleProvider, expenseProvider, vetProvider, _) {
          final sales = saleProvider.sales;
          final standaloneExpenses = expenseProvider.expenses;
          final vetRecords = vetProvider.vetRecords;

          // Calculate total revenue from egg sales
          double totalRevenue = sales.fold(0.0, (sum, s) => sum + s.totalAmount);

          // Calculate totals from standalone expenses
          double totalFeedStandalone = 0;
          double totalMaintenanceStandalone = 0;
          double totalEquipmentStandalone = 0;
          double totalUtilitiesStandalone = 0;
          double totalOtherStandalone = 0;

          for (var expense in standaloneExpenses) {
            switch (expense.category) {
              case ExpenseCategory.feed:
                totalFeedStandalone += expense.amount;
                break;
              case ExpenseCategory.maintenance:
                totalMaintenanceStandalone += expense.amount;
                break;
              case ExpenseCategory.equipment:
                totalEquipmentStandalone += expense.amount;
                break;
              case ExpenseCategory.utilities:
                totalUtilitiesStandalone += expense.amount;
                break;
              case ExpenseCategory.other:
                totalOtherStandalone += expense.amount;
                break;
            }
          }

          // Calculate veterinary costs from vet_records
          double totalVetCosts = vetProvider.totalVetCosts;

          // Combined totals
          final totalFeed = totalFeedStandalone;
          final totalVet = totalVetCosts;
          final totalOther = totalOtherStandalone +
              totalMaintenanceStandalone + totalEquipmentStandalone + totalUtilitiesStandalone;
          final totalExpenses = totalFeed + totalVet + totalOther;
          final netProfit = totalRevenue - totalExpenses;

          // Sort standalone expenses
          final sortedStandaloneExpenses = List<Expense>.from(standaloneExpenses)
            ..sort((a, b) => b.date.compareTo(a.date));

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0).copyWith(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Financial Overview Card
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
                              theme.colorScheme.secondaryContainer.withOpacity(0.3),
                              theme.colorScheme.secondaryContainer.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 32,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  t('financial_overview'),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _FinancialStat(
                                  label: t('total_revenue'),
                                  value: '€${totalRevenue.toStringAsFixed(2)}',
                                  color: Colors.green,
                                  icon: Icons.trending_up,
                                ),
                                _FinancialStat(
                                  label: t('total_expenses'),
                                  value: '€${totalExpenses.toStringAsFixed(2)}',
                                  color: Colors.orange,
                                  icon: Icons.trending_down,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: netProfit >= 0
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: netProfit >= 0
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.red.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    t('net_profit'),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        netProfit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                        color: netProfit >= 0 ? Colors.green : Colors.red,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '€${netProfit.abs().toStringAsFixed(2)}',
                                        style: theme.textTheme.displaySmall?.copyWith(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: netProfit >= 0 ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    netProfit >= 0 ? t('profit') : t('loss'),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: netProfit >= 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Expense Breakdown
                    if (totalExpenses > 0) ...[
                      Text(
                        t('expense_breakdown'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 50,
                                    sections: [
                                      if (totalFeed > 0)
                                        PieChartSectionData(
                                          value: totalFeed,
                                          title: '${(totalFeed / totalExpenses * 100).toStringAsFixed(1)}%',
                                          color: Colors.green,
                                          radius: 50,
                                          titleStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      if (totalVet > 0)
                                        PieChartSectionData(
                                          value: totalVet,
                                          title: '${(totalVet / totalExpenses * 100).toStringAsFixed(1)}%',
                                          color: Colors.red,
                                          radius: 50,
                                          titleStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      if (totalOther > 0)
                                        PieChartSectionData(
                                          value: totalOther,
                                          title: '${(totalOther / totalExpenses * 100).toStringAsFixed(1)}%',
                                          color: Colors.orange,
                                          radius: 50,
                                          titleStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _ExpenseLegendItem(
                                color: Colors.green,
                                label: t('feed'),
                                value: '€${totalFeed.toStringAsFixed(2)}',
                              ),
                              const SizedBox(height: 8),
                              _ExpenseLegendItem(
                                color: Colors.red,
                                label: locale == 'pt' ? 'Veterinário' : 'Veterinary',
                                value: '€${totalVet.toStringAsFixed(2)}',
                              ),
                              const SizedBox(height: 8),
                              _ExpenseLegendItem(
                                color: Colors.orange,
                                label: t('other'),
                                value: '€${totalOther.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Standalone Expenses Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          locale == 'pt' ? 'Despesas Independentes' : 'Standalone Expenses',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '€${standaloneExpenses.fold<double>(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (sortedStandaloneExpenses.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 64,
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  locale == 'pt'
                                      ? 'Nenhuma despesa independente'
                                      : 'No standalone expenses',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  locale == 'pt'
                                      ? 'Toque no + para adicionar'
                                      : 'Tap + to add',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...sortedStandaloneExpenses.map((expense) => _StandaloneExpenseCard(
                            expense: expense,
                            locale: locale,
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => ExpenseDialog(existingExpense: expense),
                            ),
                            onDelete: () => _deleteExpense(context, expense, t),
                          )),
                  ],
                ),
              ),

              // FAB
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const ExpenseDialog(),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(t('add_expense')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteExpense(BuildContext context, Expense expense, String Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_record')),
        content: Text(t('delete_record_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<ExpenseProvider>().deleteExpense(expense.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
  }
}

class _FinancialStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _FinancialStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 32),
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
    );
  }
}

class _ExpenseLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _ExpenseLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StandaloneExpenseCard extends StatelessWidget {
  final Expense expense;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StandaloneExpenseCard({
    required this.expense,
    required this.locale,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    if (locale == 'pt') {
      final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  IconData _getCategoryIcon() {
    switch (expense.category) {
      case ExpenseCategory.feed:
        return Icons.grass;
      case ExpenseCategory.maintenance:
        return Icons.build;
      case ExpenseCategory.equipment:
        return Icons.hardware;
      case ExpenseCategory.utilities:
        return Icons.electrical_services;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor() {
    switch (expense.category) {
      case ExpenseCategory.feed:
        return Colors.green;
      case ExpenseCategory.maintenance:
        return Colors.orange;
      case ExpenseCategory.equipment:
        return Colors.purple;
      case ExpenseCategory.utilities:
        return Colors.amber;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: _getCategoryColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.category.displayName(locale),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDate(expense.date),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '€${expense.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                expense.description,
                style: theme.textTheme.bodyMedium,
              ),
              if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  expense.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
