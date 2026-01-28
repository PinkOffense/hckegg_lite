import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/date_constants.dart';
import '../../models/daily_egg_record.dart';

/// Chart widget data computed once and cached
class _ChartData {
  final List<DailyEggRecord> displayRecords;
  final double maxY;
  final double adjustedMaxY;

  _ChartData({
    required this.displayRecords,
    required this.maxY,
    required this.adjustedMaxY,
  });

  factory _ChartData.fromRecords(List<DailyEggRecord> records) {
    if (records.isEmpty) {
      return _ChartData(displayRecords: [], maxY: 0, adjustedMaxY: 10);
    }

    // Sort records by date
    final sortedRecords = List<DailyEggRecord>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Get last 7 records
    final displayRecords = sortedRecords.length > 7
        ? sortedRecords.sublist(sortedRecords.length - 7)
        : sortedRecords;

    // Calculate max values
    int maxEggs = 0;
    for (final r in displayRecords) {
      if (r.eggsCollected > maxEggs) maxEggs = r.eggsCollected;
    }
    final maxY = maxEggs.toDouble();
    final adjustedMaxY = (maxY * 1.2).ceil().toDouble();

    return _ChartData(
      displayRecords: displayRecords,
      maxY: maxY,
      adjustedMaxY: adjustedMaxY > 0 ? adjustedMaxY : 10,
    );
  }
}

class ProductionChart extends StatelessWidget {
  final List<DailyEggRecord> records;
  final String locale;

  const ProductionChart({
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
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    // Compute chart data once
    final chartData = _ChartData.fromRecords(records);
    final displayRecords = chartData.displayRecords;
    final adjustedMaxY = chartData.adjustedMaxY;

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
                  return BarTooltipItem(
                    '${record.eggsCollected} ${locale == 'pt' ? 'ovos' : 'eggs'}\n',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: _formatDateShort(DateTime.parse(record.date), locale),
                        style: const TextStyle(
                          fontSize: 12,
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
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
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
                  color: theme.dividerColor.withValues(alpha: 0.2),
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
                    BarChartRodData(
                      toY: record.eggsCollected.toDouble(),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 20,
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
    return locale == 'pt'
        ? DateConstants.formatDayMonth(date, locale)
        : DateConstants.formatMonthDay(date, locale);
  }
}
