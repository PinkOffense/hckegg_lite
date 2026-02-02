import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../features/analytics/domain/entities/analytics_data.dart';
import '../models/daily_egg_record.dart';

class DashboardExportService {
  /// Export dashboard to PDF using backend analytics data
  Future<void> exportToPdfFromAnalytics({
    required String locale,
    required int todayEggs,
    required List<DailyEggRecord> recentRecords,
    required DashboardAnalytics dashboard,
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
          if (dashboard.alerts.isNotEmpty) ...[
            _buildAlertsSection(locale, dashboard.alerts),
            pw.SizedBox(height: 20),
          ],
          if (dashboard.production.prediction != null) ...[
            _buildPredictionSection(locale, dashboard.production.prediction!),
            pw.SizedBox(height: 20),
          ],
          _buildProductionStatsSection(locale, dashboard.production),
          pw.SizedBox(height: 20),
          _buildSalesStatsSection(locale, dashboard.sales),
          pw.SizedBox(height: 20),
          _buildExpensesStatsSection(locale, dashboard.expenses),
          pw.SizedBox(height: 20),
          _buildFeedStatsSection(locale, dashboard.feed),
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

  /// Generate PDF bytes for testing or custom handling
  Future<Uint8List> generatePdfBytesFromAnalytics({
    required String locale,
    required int todayEggs,
    required List<DailyEggRecord> recentRecords,
    required DashboardAnalytics dashboard,
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
          if (dashboard.alerts.isNotEmpty) ...[
            _buildAlertsSection(locale, dashboard.alerts),
            pw.SizedBox(height: 20),
          ],
          if (dashboard.production.prediction != null) ...[
            _buildPredictionSection(locale, dashboard.production.prediction!),
            pw.SizedBox(height: 20),
          ],
          _buildProductionStatsSection(locale, dashboard.production),
          pw.SizedBox(height: 20),
          _buildSalesStatsSection(locale, dashboard.sales),
          pw.SizedBox(height: 20),
          _buildExpensesStatsSection(locale, dashboard.expenses),
          pw.SizedBox(height: 20),
          _buildFeedStatsSection(locale, dashboard.feed),
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

  pw.Widget _buildProductionStatsSection(String locale, ProductionSummary production) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          locale == 'pt' ? 'Produção' : 'Production',
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
              _tableCell(locale == 'pt' ? 'Total Recolhido' : 'Total Collected'),
              _tableCell('${production.totalCollected}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Total Consumido' : 'Total Consumed'),
              _tableCell('${production.totalConsumed}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Disponíveis' : 'Available'),
              _tableCell('${production.totalRemaining}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Média Semanal' : 'Week Average'),
              _tableCell(production.weekAverage.toStringAsFixed(1)),
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSalesStatsSection(String locale, SalesSummary sales) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          locale == 'pt' ? 'Vendas' : 'Sales',
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
              _tableCell(locale == 'pt' ? 'Quantidade Vendida' : 'Quantity Sold'),
              _tableCell('${sales.totalQuantity}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Receita Total' : 'Total Revenue'),
              _tableCell('€${sales.totalRevenue.toStringAsFixed(2)}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Preço Médio/Ovo' : 'Avg Price/Egg'),
              _tableCell('€${sales.averagePricePerEgg.toStringAsFixed(2)}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Pago' : 'Paid'),
              _tableCell('€${sales.paidAmount.toStringAsFixed(2)}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Pendente' : 'Pending'),
              _tableCell('€${sales.pendingAmount.toStringAsFixed(2)}'),
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildExpensesStatsSection(String locale, ExpensesSummary expenses) {
    final netProfit = expenses.netProfit;
    final hasProfit = netProfit >= 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          locale == 'pt' ? 'Despesas e Lucro' : 'Expenses & Profit',
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
              _tableCell(locale == 'pt' ? 'Total Despesas' : 'Total Expenses'),
              _tableCell('€${expenses.totalExpenses.toStringAsFixed(2)}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Semana' : 'This Week'),
              _tableCell('€${expenses.weekExpenses.toStringAsFixed(2)}'),
            ]),
            pw.TableRow(children: [
              _tableCell(locale == 'pt' ? 'Mês' : 'This Month'),
              _tableCell('€${expenses.monthExpenses.toStringAsFixed(2)}'),
            ]),
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: hasProfit ? PdfColors.green50 : PdfColors.red50,
              ),
              children: [
                _tableCell(
                  locale == 'pt' ? 'Lucro Líquido' : 'Net Profit',
                  isBold: true,
                ),
                _tableCell(
                  '€${netProfit.toStringAsFixed(2)}',
                  isBold: true,
                  color: hasProfit ? PdfColors.green700 : PdfColors.red700,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFeedStatsSection(String locale, FeedSummary feed) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          locale == 'pt' ? 'Stock de Ração' : 'Feed Stock',
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
                  color: PdfColors.orange50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.orange200),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '${feed.totalStockKg.toStringAsFixed(1)} kg',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange700,
                      ),
                    ),
                    pw.Text(
                      locale == 'pt' ? 'Stock Total' : 'Total Stock',
                      style: const pw.TextStyle(fontSize: 10),
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
                  color: feed.lowStockCount > 0 ? PdfColors.red50 : PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: feed.lowStockCount > 0 ? PdfColors.red200 : PdfColors.green200,
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '${feed.estimatedDaysRemaining}',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: feed.lowStockCount > 0 ? PdfColors.red700 : PdfColors.green700,
                      ),
                    ),
                    pw.Text(
                      locale == 'pt' ? 'Dias Restantes' : 'Days Left',
                      style: const pw.TextStyle(fontSize: 10),
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

  pw.Widget _buildPredictionSection(String locale, ProductionPrediction prediction) {
    String trendArrow;
    switch (prediction.trend) {
      case 'up':
        trendArrow = '↑';
        break;
      case 'down':
        trendArrow = '↓';
        break;
      default:
        trendArrow = '→';
    }

    String confidenceLabel;
    if (prediction.confidence >= 0.8) {
      confidenceLabel = locale == 'pt' ? 'Alta' : 'High';
    } else if (prediction.confidence >= 0.5) {
      confidenceLabel = locale == 'pt' ? 'Média' : 'Medium';
    } else {
      confidenceLabel = locale == 'pt' ? 'Baixa' : 'Low';
    }

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
              trendArrow,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
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
                      ? 'Intervalo: ${prediction.minEggs}-${prediction.maxEggs} • Confiança: $confidenceLabel'
                      : 'Range: ${prediction.minEggs}-${prediction.maxEggs} • Confidence: $confidenceLabel',
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

  pw.Widget _buildAlertsSection(String locale, List<DashboardAlert> alerts) {
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
                  '!',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo700,
                  ),
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
                        ? '${alerts.length} ${alerts.length == 1 ? 'item' : 'itens'} a verificar'
                        : '${alerts.length} ${alerts.length == 1 ? 'item' : 'items'} to check',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          ...alerts.map((alert) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 8,
                  height: 8,
                  margin: const pw.EdgeInsets.only(top: 4),
                  decoration: pw.BoxDecoration(
                    color: _getSeverityColor(alert.severity),
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        alert.title,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        alert.message,
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
          )),
        ],
      ),
    );
  }

  PdfColor _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return PdfColors.red;
      case 'medium':
        return PdfColors.orange;
      default:
        return PdfColors.amber;
    }
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
}
