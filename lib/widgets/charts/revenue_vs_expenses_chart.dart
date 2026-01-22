import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/daily_egg_record.dart';

class RevenueVsExpensesChart extends StatelessWidget {
  final List<DailyEggRecord> records;
  final String locale;

  const RevenueVsExpensesChart({
    super.key,
    required this.records,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (records.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            locale == 'pt' ? 'Sem dados disponíveis' : 'No data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    // Sort records by date
    final sortedRecords = List<DailyEggRecord>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Get last 7 records
    final displayRecords = sortedRecords.length > 7
        ? sortedRecords.sublist(sortedRecords.length - 7)
        : sortedRecords;

    // Calculate max value for Y axis
    double maxRevenue = 0;
    double maxExpense = 0;

    for (var record in displayRecords) {
      if (record.revenue > maxRevenue) maxRevenue = record.revenue;
      if (record.totalExpenses > maxExpense) maxExpense = record.totalExpenses;
    }

    final maxY = (maxRevenue > maxExpense ? maxRevenue : maxExpense) * 1.2;
    final adjustedMaxY = maxY > 0 ? maxY : 10.0;

    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: adjustedMaxY,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final record = displayRecords[groupIndex];
                  final isRevenue = rodIndex == 0;
                  final value = isRevenue ? record.revenue : record.totalExpenses;
                  final label = isRevenue
                      ? (locale == 'pt' ? 'Receita' : 'Revenue')
                      : (locale == 'pt' ? 'Despesas' : 'Expenses');

                  return BarTooltipItem(
                    '$label\n',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: '€${value.toStringAsFixed(2)}\n',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: _formatDateShort(DateTime.parse(record.date), locale),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < displayRecords.length) {
                      final record = displayRecords[value.toInt()];
                      final date = DateTime.parse(record.date);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${date.day}',
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '€${value.toInt()}',
                      style: theme.textTheme.bodySmall,
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: adjustedMaxY / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.dividerColor.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              displayRecords.length,
              (index) {
                final record = displayRecords[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    // Revenue bar
                    BarChartRodData(
                      toY: record.revenue,
                      color: Colors.green,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    // Expenses bar
                    BarChartRodData(
                      toY: record.totalExpenses,
                      color: Colors.red,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateShort(DateTime date, String locale) {
    if (locale == 'pt') {
      final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return '${date.day} ${months[date.month - 1]}';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}
