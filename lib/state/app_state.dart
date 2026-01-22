import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_egg_record.dart';

class AppState extends ChangeNotifier {
  final List<DailyEggRecord> _records = _generateMockData();

  List<DailyEggRecord> get records => List.unmodifiable(_records);

  // Get record for a specific date
  DailyEggRecord? getRecordByDate(String date) {
    try {
      return _records.firstWhere((r) => r.date == date);
    } catch (e) {
      return null;
    }
  }

  // Add or update a daily record
  void saveRecord(DailyEggRecord record) {
    final existingIndex = _records.indexWhere((r) => r.date == record.date);

    if (existingIndex != -1) {
      // Update existing record
      _records[existingIndex] = record;
    } else {
      // Add new record
      _records.insert(0, record);
    }

    // Keep records sorted by date (newest first)
    _records.sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  // Delete a record
  void deleteRecord(String date) {
    _records.removeWhere((r) => r.date == date);
    notifyListeners();
  }

  // Get records for date range
  List<DailyEggRecord> getRecordsInRange(DateTime start, DateTime end) {
    final startStr = _dateToString(start);
    final endStr = _dateToString(end);

    return _records.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList();
  }

  // Get last N days of records
  List<DailyEggRecord> getRecentRecords(int days) {
    return _records.take(days).toList();
  }

  // Statistics
  int get totalEggsCollected {
    return _records.fold(0, (sum, r) => sum + r.eggsCollected);
  }

  int get totalEggsSold {
    return _records.fold(0, (sum, r) => sum + r.eggsSold);
  }

  int get totalEggsConsumed {
    return _records.fold(0, (sum, r) => sum + r.eggsConsumed);
  }

  double get totalRevenue {
    return _records.fold(0.0, (sum, r) => sum + r.revenue);
  }

  // This week's statistics
  Map<String, dynamic> getWeekStats() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekRecords = getRecordsInRange(weekAgo, now);

    final revenue = weekRecords.fold(0.0, (sum, r) => sum + r.revenue);
    final expenses = weekRecords.fold(0.0, (sum, r) => sum + r.totalExpenses);

    return {
      'collected': weekRecords.fold(0, (sum, r) => sum + r.eggsCollected),
      'sold': weekRecords.fold(0, (sum, r) => sum + r.eggsSold),
      'consumed': weekRecords.fold(0, (sum, r) => sum + r.eggsConsumed),
      'revenue': revenue,
      'expenses': expenses,
      'net_profit': revenue - expenses,
    };
  }

  // Search records by notes
  List<DailyEggRecord> search(String query) {
    if (query.isEmpty) return records;
    return records.where((r) {
      final notesMatch = r.notes?.toLowerCase().contains(query.toLowerCase()) ?? false;
      final dateMatch = r.date.contains(query);
      return notesMatch || dateMatch;
    }).toList();
  }

  // Generate mock data for development
  static List<DailyEggRecord> _generateMockData() {
    final random = Random();
    final records = <DailyEggRecord>[];
    final now = DateTime.now();

    for (int i = 0; i < 14; i++) {
      final date = now.subtract(Duration(days: i));
      final collected = 8 + random.nextInt(8); // 8-15 eggs per day
      final sold = (collected * 0.6).floor() + random.nextInt(3);
      final consumed = random.nextInt(3);

      records.add(DailyEggRecord(
        id: 'mock-${i + 1}',
        date: _dateToString(date),
        eggsCollected: collected,
        eggsSold: sold,
        eggsConsumed: consumed,
        pricePerEgg: 0.50 + (random.nextDouble() * 0.30), // $0.50-$0.80
        notes: i % 3 == 0 ? 'Weather was good today' : null,
        henCount: 10 + random.nextInt(5),
        createdAt: date,
      ));
    }

    return records;
  }

  static String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
