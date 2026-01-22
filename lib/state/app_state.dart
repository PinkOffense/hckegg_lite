import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_egg_record.dart';
import '../models/vet_record.dart';

class AppState extends ChangeNotifier {
  final List<DailyEggRecord> _records = _generateMockData();
  final List<VetRecord> _vetRecords = _generateMockVetData();

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
    return _records.fold<int>(0, (sum, r) => sum + r.eggsCollected);
  }

  int get totalEggsSold {
    return _records.fold<int>(0, (sum, r) => sum + r.eggsSold);
  }

  int get totalEggsConsumed {
    return _records.fold<int>(0, (sum, r) => sum + r.eggsConsumed);
  }

  double get totalRevenue {
    return _records.fold<double>(0.0, (sum, r) => sum + r.revenue);
  }

  // This week's statistics
  Map<String, dynamic> getWeekStats() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekRecords = getRecordsInRange(weekAgo, now);

    final revenue = weekRecords.fold<double>(0.0, (sum, r) => sum + r.revenue);
    final expenses = weekRecords.fold<double>(0.0, (sum, r) => sum + r.totalExpenses);

    return {
      'collected': weekRecords.fold<int>(0, (sum, r) => sum + r.eggsCollected),
      'sold': weekRecords.fold<int>(0, (sum, r) => sum + r.eggsSold),
      'consumed': weekRecords.fold<int>(0, (sum, r) => sum + r.eggsConsumed),
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

  // ========== VET RECORDS MANAGEMENT ==========

  List<VetRecord> get vetRecords => List.unmodifiable(_vetRecords);

  List<VetRecord> getVetRecords() {
    // Return sorted by date (newest first)
    final sorted = List<VetRecord>.from(_vetRecords);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  // Add or update a vet record
  void saveVetRecord(VetRecord record) {
    final existingIndex = _vetRecords.indexWhere((r) => r.id == record.id);

    if (existingIndex != -1) {
      // Update existing record
      _vetRecords[existingIndex] = record;
    } else {
      // Add new record
      _vetRecords.add(record);
    }

    notifyListeners();
  }

  // Delete a vet record
  void deleteVetRecord(String id) {
    _vetRecords.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // Get vet records by type
  List<VetRecord> getVetRecordsByType(VetRecordType type) {
    return _vetRecords.where((r) => r.type == type).toList();
  }

  // Get upcoming vet actions
  List<VetRecord> getUpcomingVetActions() {
    final now = DateTime.now();
    return _vetRecords
        .where((r) => r.nextActionDate != null)
        .where((r) {
          final nextDate = DateTime.parse(r.nextActionDate!);
          return nextDate.isAfter(now);
        })
        .toList()
      ..sort((a, b) => a.nextActionDate!.compareTo(b.nextActionDate!));
  }

  // Vet statistics
  int get totalVetRecords => _vetRecords.length;

  int get totalDeaths => _vetRecords.where((r) => r.type == VetRecordType.death).length;

  double get totalVetCosts => _vetRecords.fold<double>(0.0, (sum, r) => sum + (r.cost ?? 0.0));

  int get totalHensAffected => _vetRecords.fold<int>(0, (sum, r) => sum + r.hensAffected);

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

  // Generate mock vet data for development
  static List<VetRecord> _generateMockVetData() {
    final now = DateTime.now();
    final records = <VetRecord>[];

    // Vaccine record
    records.add(VetRecord(
      id: 'vet-1',
      date: _dateToString(now.subtract(const Duration(days: 30))),
      type: VetRecordType.vaccine,
      hensAffected: 15,
      description: 'Annual Newcastle disease vaccination',
      medication: 'Newcastle Disease Vaccine',
      cost: 45.00,
      nextActionDate: _dateToString(now.add(const Duration(days: 335))),
      notes: 'All hens vaccinated successfully',
      severity: VetRecordSeverity.low,
      createdAt: now.subtract(const Duration(days: 30)),
    ));

    // Disease record
    records.add(VetRecord(
      id: 'vet-2',
      date: _dateToString(now.subtract(const Duration(days: 15))),
      type: VetRecordType.disease,
      hensAffected: 3,
      description: 'Respiratory infection symptoms observed',
      medication: 'Tylosin antibiotic',
      cost: 28.50,
      nextActionDate: _dateToString(now.add(const Duration(days: 5))),
      notes: 'Monitor closely, separate affected hens if needed',
      severity: VetRecordSeverity.medium,
      createdAt: now.subtract(const Duration(days: 15)),
    ));

    // Treatment record
    records.add(VetRecord(
      id: 'vet-3',
      date: _dateToString(now.subtract(const Duration(days: 7))),
      type: VetRecordType.treatment,
      hensAffected: 1,
      description: 'Treatment for bumblefoot',
      medication: 'Betadine solution + bandage',
      cost: 12.00,
      notes: 'Hen responding well to treatment',
      severity: VetRecordSeverity.low,
      createdAt: now.subtract(const Duration(days: 7)),
    ));

    // Checkup record
    records.add(VetRecord(
      id: 'vet-4',
      date: _dateToString(now.subtract(const Duration(days: 60))),
      type: VetRecordType.checkup,
      hensAffected: 15,
      description: 'Routine flock health check',
      cost: 55.00,
      nextActionDate: _dateToString(now.add(const Duration(days: 125))),
      notes: 'Overall flock health is good',
      severity: VetRecordSeverity.low,
      createdAt: now.subtract(const Duration(days: 60)),
    ));

    // Death record
    records.add(VetRecord(
      id: 'vet-5',
      date: _dateToString(now.subtract(const Duration(days: 90))),
      type: VetRecordType.death,
      hensAffected: 1,
      description: 'Natural death - old age',
      notes: 'Hen was 6 years old, died peacefully',
      severity: VetRecordSeverity.high,
      createdAt: now.subtract(const Duration(days: 90)),
    ));

    return records;
  }
}
