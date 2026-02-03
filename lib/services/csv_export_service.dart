// lib/services/csv_export_service.dart
import 'package:flutter/material.dart';
import 'csv_download_stub.dart'
    if (dart.library.html) 'csv_download_web.dart';

import '../models/daily_egg_record.dart';
import '../models/egg_sale.dart';
import '../models/expense.dart';

class CsvExportService {
  /// Generates CSV content from headers and rows, then triggers a download.
  static void export({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
    required BuildContext context,
    required String locale,
  }) {
    final csv = _generateCsv(headers, rows);
    downloadCsvFile(csv, filename);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale == 'pt'
              ? 'Ficheiro CSV exportado: $filename'
              : 'CSV file exported: $filename',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String _generateCsv(List<String> headers, List<List<String>> rows) {
    final buffer = StringBuffer();
    // BOM for Excel UTF-8 compatibility
    buffer.write('\uFEFF');
    buffer.writeln(headers.map(_escapeCsvField).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvField).join(','));
    }
    return buffer.toString();
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Export egg records to CSV
  static void exportEggRecords({
    required List<DailyEggRecord> records,
    required BuildContext context,
    required String locale,
  }) {
    final headers = locale == 'pt'
        ? ['Data', 'Ovos Recolhidos', 'Ovos Consumidos', 'Restantes', 'N. Galinhas', 'Notas']
        : ['Date', 'Eggs Collected', 'Eggs Consumed', 'Remaining', 'Hen Count', 'Notes'];

    final rows = records.map((r) => [
      r.date,
      r.eggsCollected.toString(),
      r.eggsConsumed.toString(),
      r.eggsRemaining.toString(),
      r.henCount?.toString() ?? '',
      r.notes ?? '',
    ]).toList();

    final date = DateTime.now().toIso8601String().split('T').first;
    export(
      filename: 'egg_records_$date.csv',
      headers: headers,
      rows: rows,
      context: context,
      locale: locale,
    );
  }

  /// Export sales to CSV
  static void exportSales({
    required List<EggSale> sales,
    required BuildContext context,
    required String locale,
  }) {
    final headers = locale == 'pt'
        ? ['Data', 'Quantidade', 'Preço/Ovo', 'Total', 'Cliente', 'Estado', 'Notas']
        : ['Date', 'Quantity', 'Price/Egg', 'Total', 'Customer', 'Status', 'Notes'];

    final rows = sales.map((s) => [
      s.date,
      s.quantitySold.toString(),
      s.pricePerEgg.toStringAsFixed(2),
      s.totalAmount.toStringAsFixed(2),
      s.customerName ?? '',
      s.paymentStatus.name,
      s.notes ?? '',
    ]).toList();

    final date = DateTime.now().toIso8601String().split('T').first;
    export(
      filename: 'sales_$date.csv',
      headers: headers,
      rows: rows,
      context: context,
      locale: locale,
    );
  }

  /// Export expenses to CSV
  static void exportExpenses({
    required List<Expense> expenses,
    required BuildContext context,
    required String locale,
  }) {
    final headers = locale == 'pt'
        ? ['Data', 'Categoria', 'Montante', 'Descrição', 'Notas']
        : ['Date', 'Category', 'Amount', 'Description', 'Notes'];

    final rows = expenses.map((e) => [
      e.date,
      e.category.displayName(locale),
      e.amount.toStringAsFixed(2),
      e.description,
      e.notes ?? '',
    ]).toList();

    final date = DateTime.now().toIso8601String().split('T').first;
    export(
      filename: 'expenses_$date.csv',
      headers: headers,
      rows: rows,
      context: context,
      locale: locale,
    );
  }
}
