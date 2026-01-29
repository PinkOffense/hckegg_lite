// test/mocks/mock_vet_repository.dart

import 'package:hckegg_lite/domain/repositories/vet_repository.dart';
import 'package:hckegg_lite/models/vet_record.dart';

/// Mock implementation of VetRepository for testing
class MockVetRepository implements VetRepository {
  final List<VetRecord> _records = [];

  // Control flags for simulating errors
  bool shouldThrowOnSave = false;
  bool shouldThrowOnDelete = false;
  bool shouldThrowOnLoad = false;

  // Track method calls
  int saveCallCount = 0;
  int deleteCallCount = 0;
  int getAllCallCount = 0;

  void seedRecords(List<VetRecord> records) {
    _records.clear();
    _records.addAll(records);
  }

  void clear() {
    _records.clear();
    saveCallCount = 0;
    deleteCallCount = 0;
    getAllCallCount = 0;
  }

  @override
  Future<List<VetRecord>> getAll() async {
    getAllCallCount++;
    if (shouldThrowOnLoad) {
      throw Exception('Simulated load error');
    }
    return List.from(_records);
  }

  @override
  Future<VetRecord?> getById(String id) async {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<VetRecord>> getByType(VetRecordType type) async {
    return _records.where((r) => r.type == type).toList();
  }

  @override
  Future<List<VetRecord>> getBySeverity(VetRecordSeverity severity) async {
    return _records.where((r) => r.severity == severity).toList();
  }

  @override
  Future<List<VetRecord>> getUpcomingActions() async {
    final now = DateTime.now();
    return _records
        .where((r) => r.nextActionDate != null)
        .where((r) {
          final nextDate = DateTime.parse(r.nextActionDate!);
          return nextDate.isAfter(now);
        })
        .toList();
  }

  @override
  Future<List<VetRecord>> getByDateRange(DateTime start, DateTime end) async {
    final startStr = _toIsoDate(start);
    final endStr = _toIsoDate(end);
    return _records.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList();
  }

  @override
  Future<VetRecord> save(VetRecord record) async {
    saveCallCount++;
    if (shouldThrowOnSave) {
      throw Exception('Simulated save error');
    }

    final existingIndex = _records.indexWhere((r) => r.id == record.id);
    if (existingIndex != -1) {
      _records[existingIndex] = record;
    } else {
      _records.add(record);
    }
    return record;
  }

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    if (shouldThrowOnDelete) {
      throw Exception('Simulated delete error');
    }
    _records.removeWhere((r) => r.id == id);
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return {
      'total_records': _records.length,
      'total_deaths': _records.where((r) => r.type == VetRecordType.death).length,
      'total_cost': _records.fold<double>(0.0, (sum, r) => sum + (r.cost ?? 0.0)),
    };
  }

  String _toIsoDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
