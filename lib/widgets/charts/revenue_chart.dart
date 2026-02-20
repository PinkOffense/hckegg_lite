import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/date_constants.dart';
import '../../models/egg_sale.dart';

/// Pre-computed chart data for revenue chart
class _RevenueChartData {
  final List<EggSale> displaySales;
  final double adjustedMaxY;

  _RevenueChartData({required this.displaySales, required this.adjustedMaxY});

  factory _RevenueChartData.fromSales(List<EggSale> sales) {
    if (sales.isEmpty) {
      return _RevenueChartData(displaySales: [], adjustedMaxY: 10);
    }

    // Sort sales by date
    final sortedSales = List<EggSale>.from(sales)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Get last 7 sales
    final displaySales = sortedSales.length > 7
        ? sortedSales.sublist(sortedSales.length - 7)
        : sortedSales;

    // Calculate max using a simple loop (avoids map/reduce overhead)
    double maxY = 0;
    for (final s in displaySales) {
      if (s.totalAmount > maxY) maxY = s.totalAmount;
    }
    final adjustedMaxY = (maxY * 1.2).ceil().toDouble();

    return _RevenueChartData(
      displaySales: displaySales,
      adjustedMaxY: adjustedMaxY > 0 ? adjustedMaxY : 10,
    );
  }
}

class RevenueChart extends StatelessWidget {
  final List<EggSale> sales;
  final String locale;

  const RevenueChart({
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
            locale == 'pt' ? 'Sem dados de vendas disponíveis' : 'No sales data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    // Compute chart data once
    final chartData = _RevenueChartData.fromSales(sales);
    final displaySales = chartData.displaySales;
    final adjustedMaxY = chartData.adjustedMaxY;

    // Compute totals for accessibility
    final totalRevenue = displaySales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final avgRevenue = displaySales.isNotEmpty ? totalRevenue / displaySales.length : 0;
    final semanticLabel = locale == 'pt'
        ? 'Gráfico de receita: ${displaySales.length} vendas, total €${totalRevenue.toStringAsFixed(2)}, média €${avgRevenue.toStringAsFixed(2)}'
        : 'Revenue chart: ${displaySales.length} sales, total €${totalRevenue.toStringAsFixed(2)}, average €${avgRevenue.toStringAsFixed(2)}';

    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        height: 250,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: adjustedMaxY / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  strokeWidth: 1,
                );
              },
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
                      '€${value.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall,
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (displaySales.length - 1).toDouble(),
            minY: 0,
            maxY: adjustedMaxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final sale = displaySales[spot.x.toInt()];
                    return LineTooltipItem(
                      '€${sale.totalAmount.toStringAsFixed(2)}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: _formatDateShort(DateTime.parse(sale.date), locale),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  displaySales.length,
                  (index) => FlSpot(index.toDouble(), displaySales[index].totalAmount),
                ),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.secondary.withValues(alpha: 0.7),
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: theme.colorScheme.secondary,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.secondary.withValues(alpha: 0.3),
                      theme.colorScheme.secondary.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _formatDateShort(DateTime date, String locale) {
    return locale == 'pt'
        ? DateConstants.formatDayMonth(date, locale)
        : DateConstants.formatMonthDay(date, locale);
  }
}
