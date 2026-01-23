import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/egg_sale.dart';

class RevenueVsExpensesChart extends StatelessWidget {
  final List<EggSale> sales;
  final String locale;

  const RevenueVsExpensesChart({
    super.key,
    required this.sales,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (sales.isEmpty) {
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

    // Sort sales by date
    final sortedSales = List<EggSale>.from(sales)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Get last 7 sales
    final displaySales = sortedSales.length > 7
        ? sortedSales.sublist(sortedSales.length - 7)
        : sortedSales;

    // Calculate max value for Y axis
    double maxRevenue = 0;

    for (var sale in displaySales) {
      if (sale.totalAmount > maxRevenue) maxRevenue = sale.totalAmount;
    }

    final maxY = maxRevenue * 1.2;
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
                  final sale = displaySales[groupIndex];
                  final value = sale.totalAmount;
                  final label = locale == 'pt' ? 'Venda' : 'Sale';

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
                        text: _formatDateShort(DateTime.parse(sale.date), locale),
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
                    if (value.toInt() >= 0 && value.toInt() < displaySales.length) {
                      final sale = displaySales[value.toInt()];
                      final date = DateTime.parse(sale.date);
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
              displaySales.length,
              (index) {
                final sale = displaySales[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    // Revenue bar
                    BarChartRodData(
                      toY: sale.totalAmount,
                      color: Colors.green,
                      width: 16,
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
