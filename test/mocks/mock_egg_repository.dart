// test/mocks/mock_egg_repository.dart

import 'package:hckegg_lite/domain/repositories/egg_repository.dart';
import 'package:hckegg_lite/models/daily_egg_record.dart';

/// Mock implementation of EggRepository for testing
class MockEggRepository implements EggRepository {
  final List<DailyEggRecord> _records = [];

  // Control flags for simulating errors
  bool shouldThrowOnSave = false;
  bool shouldThrowOnDelete = false;
  bool shouldThrowOnLoad = false;

  // Track method calls for verification
  int saveCallCount = 0;
  int deleteCallCount = 0;
  int getAllCallCount = 0;

  /// Pre-populate with test data
  void seedRecords(List<DailyEggRecord> records) {
    _records.clear();
    _records.addAll(records);
  }

  /// Clear all records
  void clear() {
    _records.clear();
    saveCallCount = 0;
    deleteCallCount = 0;
    getAllCallCount = 0;
  }

  @override
  Future<List<DailyEggRecord>> getAll() async {
    getAllCallCount++;
    if (shouldThrowOnLoad) {
      throw Exception('Simulated load error');
    }
    return List.from(_records);
  }

  @override
  Future<DailyEggRecord?> getByDate(String date) async {
    try {
      return _records.firstWhere((r) => r.date == date);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DailyEggRecord>> getByDateRange(DateTime start, DateTime end) async {
    final startStr = _toIsoDate(start);
    final endStr = _toIsoDate(end);

    return _records.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList();
  }

  @override
  Future<List<DailyEggRecord>> getRecent(int count) async {
    final sorted = List<DailyEggRecord>.from(_records)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(count).toList();
  }

  @override
  Future<DailyEggRecord> save(DailyEggRecord record) async {
    saveCallCount++;
    if (shouldThrowOnSave) {
      throw Exception('Simulated save error');
    }

    final existingIndex = _records.indexWhere((r) => r.date == record.date);
    if (existingIndex != -1) {
      _records[existingIndex] = record;
    } else {
      _records.add(record);
    }
    return record;
  }

  @override
  Future<void> deleteByDate(String date) async {
    deleteCallCount++;
    if (shouldThrowOnDelete) {
      throw Exception('Simulated delete error');
    }
    _records.removeWhere((r) => r.date == date);
  }

  @override
  Future<void> deleteById(String id) async {
    deleteCallCount++;
    if (shouldThrowOnDelete) {
      throw Exception('Simulated delete error');
    }
    _records.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<DailyEggRecord>> search(String query) async {
    final normalizedQuery = query.toLowerCase();
    return _records.where((r) {
      final notesMatch = r.notes?.toLowerCase().contains(normalizedQuery) ?? false;
      final dateMatch = r.date.contains(query);
      return notesMatch || dateMatch;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    int totalCollected = 0;
    int totalConsumed = 0;

    for (final record in _records) {
      totalCollected += record.eggsCollected;
      totalConsumed += record.eggsConsumed;
    }

    return {
      'total_collected': totalCollected,
      'total_consumed': totalConsumed,
      'record_count': _records.length,
    };
  }

  String _toIsoDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
