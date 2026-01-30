import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/models/week_stats.dart';
import '../models/daily_egg_record.dart';
import '../pages/dashboard_page.dart' show TodayAlertsData, FeedStockAlertItem, ReservationAlertItem, VetAppointmentAlertItem;
import 'production_analytics_service.dart';

class DashboardExportService {
  Future<void> exportToPdf({
    required String locale,
    required int todayEggs,
    required WeekStats weekStats,
    required List<DailyEggRecord> recentRecords,
    required int availableEggs,
    required int reservedEggs,
    ProductionPrediction? prediction,
    ProductionAlert? alert,
    TodayAlertsData? todayAlerts,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(locale, dateStr),
        footer: (context) => _buildFooter(context, locale),
        build: (context) => [
          _buildTodaySection(locale, todayEggs, dateStr),
          pw.SizedBox(height: 20),
          if (alert != null) ...[
            _buildAlertSection(locale, alert),
            pw.SizedBox(height: 20),
          ],
          if (prediction != null) ...[
            _buildPredictionSection(locale, prediction),
            pw.SizedBox(height: 20),
          ],
          if (todayAlerts != null && todayAlerts.hasAlerts) ...[
            _buildTodayAlertsSection(locale, todayAlerts),
            pw.SizedBox(height: 20),
          ],
          _buildWeekStatsSection(locale, weekStats),
          pw.SizedBox(height: 20),
          _buildInventorySection(locale, availableEggs, reservedEggs),
          pw.SizedBox(height: 20),
          _buildRecentRecordsSection(locale, recentRecords),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'dashboard_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf',
    );
  }

  Future<Uint8List> generatePdfBytes({
    required String locale,
    required int todayEggs,
    required WeekStats weekStats,
    required List<DailyEggRecord> recentRecords,
    required int availableEggs,
    required int reservedEggs,
    ProductionPrediction? prediction,
    ProductionAlert? alert,
    TodayAlertsData? todayAlerts,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(locale, dateStr),
        footer: (context) => _buildFooter(context, locale),
        build: (context) => [
          _buildTodaySection(locale, todayEggs, dateStr),
          pw.SizedBox(height: 20),
          if (alert != null) ...[
            _buildAlertSection(locale, alert),
            pw.SizedBox(height: 20),
          ],
          if (prediction != null) ...[
            _buildPredictionSection(locale, prediction),
            pw.SizedBox(height: 20),
          ],
          if (todayAlerts != null && todayAlerts.hasAlerts) ...[
            _buildTodayAlertsSection(locale, todayAlerts),
            pw.SizedBox(height: 20),
          ],
          _buildWeekStatsSection(locale, weekStats),
          pw.SizedBox(height: 20),
          _buildInventorySection(locale, availableEggs, reservedEggs),
          pw.SizedBox(height: 20),
          _buildRecentRecordsSection(locale, recentRecords),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String locale, String dateStr) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'HCKEgg Aviculture 360',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.pink,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                locale == 'pt' ? 'Relatório do Dashboard' : 'Dashboard Report',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            dateStr,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, String locale) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            locale == 'pt'
              ? 'Gerado por HCKEgg Aviculture 360'
              : 'Generated by HCKEgg Aviculture 360',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey500,
            ),
          ),
          pw.Text(
            '${locale == 'pt' ? 'Página' : 'Page'} ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTodaySection(String locale, int todayEggs, String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.amber200),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            locale == 'pt' ? 'Recolha de Hoje' : "Today's Collection",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '$todayEggs',
            style: pw.TextStyle(
              fontSize: 48,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber800,
            ),
          ),
          pw.Text(
            locale == 'pt' ? 'ovos' : 'eggs',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildWeekStatsSection(String locale, WeekStats weekStats) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          locale == 'pt' ? 'Estatísticas da Semana' : 'Week Statistics',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableCell(locale == 'pt' ? 'Métrica' : 'Metric', isHeader: true),
                _tableCell(locale == 'pt' ? 'Valor' : 'Value', isHeader: true),
              ],
            ),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Ovos Recolhidos' : 'Eggs Collected'),
              _tableCell('${weekStats.collected}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Ovos Vendidos' : 'Eggs Sold'),
              _tableCell('${weekStats.sold}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Ovos Consumidos' : 'Eggs Consumed'),
              _tableCell('${weekStats.consumed}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Receita' : 'Revenue'),
              _tableCell('€${weekStats.revenue.toStringAsFixed(2)}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Despesas' : 'Expenses'),
              _tableCell('€${weekStats.expenses.toStringAsFixed(2)}'),
            ]),
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: weekStats.hasProfit ? PdfColors.green50 : PdfColors.red50,
              ),
              children: [
                _tableCell(
                  locale == 'pt' ? 'Lucro Líquido' : 'Net Profit',
                  isBold: true,
                ),
                _tableCell(
                  '€${weekStats.netProfit.toStringAsFixed(2)}',
                  isBold: true,
                  color: weekStats.hasProfit ? PdfColors.green700 : PdfColors.red700,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInventorySection(String locale, int availableEggs, int reservedEggs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          locale == 'pt' ? 'Inventário' : 'Inventory',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.purple200),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '$availableEggs',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.purple700,
                      ),
                    ),
                    pw.Text(
                      locale == 'pt' ? 'Disponíveis' : 'Available',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '$reservedEggs',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue700,
                      ),
                    ),
                    pw.Text(
                      locale == 'pt' ? 'Reservados' : 'Reserved',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildRecentRecordsSection(String locale, List<DailyEggRecord> records) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          locale == 'pt' ? 'Últimos 7 Dias' : 'Last 7 Days',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableCell(locale == 'pt' ? 'Data' : 'Date', isHeader: true),
                _tableCell(locale == 'pt' ? 'Recolhidos' : 'Collected', isHeader: true),
                _tableCell(locale == 'pt' ? 'Consumidos' : 'Consumed', isHeader: true),
              ],
            ),
            ...records.map((record) => pw.TableRow(children: [
              _tableCell(_formatDate(record.date, locale)),
              _tableCell('${record.eggsCollected}'),
              _tableCell('${record.eggsConsumed}'),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false, bool isBold = false, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : null,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  String _formatDate(String dateStr, String locale) {
    final date = DateTime.parse(dateStr);
    if (locale == 'pt') {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } else {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  pw.Widget _buildPredictionSection(String locale, ProductionPrediction prediction) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              '📈',
              style: const pw.TextStyle(fontSize: 24),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  locale == 'pt' ? 'Previsão para Amanhã' : "Tomorrow's Prediction",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '~${prediction.predictedEggs} ${locale == 'pt' ? 'ovos' : 'eggs'}',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  locale == 'pt'
                      ? 'Intervalo: ${prediction.minRange}-${prediction.maxRange} • Confiança: ${prediction.confidence.displayName(locale)}'
                      : 'Range: ${prediction.minRange}-${prediction.maxRange} • Confidence: ${prediction.confidence.displayName(locale)}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAlertSection(String locale, ProductionAlert alert) {
    PdfColor alertColor;
    String alertEmoji;

    switch (alert.severity) {
      case AlertSeverity.high:
        alertColor = PdfColors.red;
        alertEmoji = '🔴';
        break;
      case AlertSeverity.medium:
        alertColor = PdfColors.orange;
        alertEmoji = '🟠';
        break;
      case AlertSeverity.low:
        alertColor = PdfColors.amber;
        alertEmoji = '🟡';
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(alertColor.toInt()).shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: alertColor),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(alertColor.toInt()).shade(0.2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              alertEmoji,
              style: const pw.TextStyle(fontSize: 24),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  locale == 'pt' ? 'Alerta de Produção' : 'Production Alert',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: alertColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  locale == 'pt' ? alert.messagePt : alert.message,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  locale == 'pt'
                      ? 'Hoje: ${alert.todayValue} ovos • Média: ${alert.averageValue} ovos'
                      : 'Today: ${alert.todayValue} eggs • Average: ${alert.averageValue} eggs',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTodayAlertsSection(String locale, TodayAlertsData alerts) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  '🔔',
                  style: const pw.TextStyle(fontSize: 20),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    locale == 'pt' ? 'Alertas do Dia' : "Today's Alerts",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo800,
                    ),
                  ),
                  pw.Text(
                    locale == 'pt'
                        ? '${alerts.totalAlerts} ${alerts.totalAlerts == 1 ? 'item' : 'itens'} a verificar'
                        : '${alerts.totalAlerts} ${alerts.totalAlerts == 1 ? 'item' : 'items'} to check',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Feed Stock Alerts
          if (alerts.feedAlerts.isNotEmpty) ...[
            _buildAlertSubsection(
              locale == 'pt' ? 'Stock de Ração' : 'Feed Stock',
              PdfColors.orange,
              alerts.feedAlerts.map((a) => locale == 'pt'
                  ? '${a.feedType}: ${a.currentKg.toStringAsFixed(1)}kg (~${a.estimatedDaysRemaining} dias)${a.isLowStock ? " ⚠️" : ""}'
                  : '${a.feedType}: ${a.currentKg.toStringAsFixed(1)}kg (~${a.estimatedDaysRemaining} days)${a.isLowStock ? " ⚠️" : ""}'
              ).toList(),
            ),
            pw.SizedBox(height: 12),
          ],

          // Reservation Alerts
          if (alerts.reservationAlerts.isNotEmpty) ...[
            _buildAlertSubsection(
              locale == 'pt' ? 'Reservas Pendentes' : 'Pending Reservations',
              PdfColors.blue,
              alerts.reservationAlerts.map((a) => locale == 'pt'
                  ? '${a.customerName}: ${a.quantity} ovos ${a.isToday ? "(HOJE)" : "(amanhã)"}'
                  : '${a.customerName}: ${a.quantity} eggs ${a.isToday ? "(TODAY)" : "(tomorrow)"}'
              ).toList(),
            ),
            pw.SizedBox(height: 12),
          ],

          // Vet Appointment Alerts
          if (alerts.vetAlerts.isNotEmpty) ...[
            _buildAlertSubsection(
              locale == 'pt' ? 'Consultas Veterinárias' : 'Vet Appointments',
              PdfColors.red,
              alerts.vetAlerts.map((a) => locale == 'pt'
                  ? '${a.description} (${a.hensAffected} galinhas)'
                  : '${a.description} (${a.hensAffected} hens)'
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildAlertSubsection(String title, PdfColor color, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 8,
              height: 8,
              decoration: pw.BoxDecoration(
                color: color,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        ...items.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, top: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: const pw.TextStyle(fontSize: 10)),
              pw.Expanded(
                child: pw.Text(
                  item,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
