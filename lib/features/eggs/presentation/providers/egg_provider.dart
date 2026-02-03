import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../../../core/date_utils.dart';
import '../../domain/domain.dart';

/// State for the egg feature
enum EggState { initial, loading, loaded, error }

/// Provider for egg records following clean architecture
///
/// Uses use cases from the domain layer instead of directly accessing repositories
class EggProvider extends ChangeNotifier {
  final GetEggRecords _getEggRecords;
  final CreateEggRecord _createEggRecord;
  final UpdateEggRecord _updateEggRecord;
  final DeleteEggRecord _deleteEggRecord;

  EggProvider({
    required GetEggRecords getEggRecords,
    required CreateEggRecord createEggRecord,
    required UpdateEggRecord updateEggRecord,
    required DeleteEggRecord deleteEggRecord,
  })  : _getEggRecords = getEggRecords,
        _createEggRecord = createEggRecord,
        _updateEggRecord = updateEggRecord,
        _deleteEggRecord = deleteEggRecord;

  // State
  EggState _state = EggState.initial;
  EggState get state => _state;

  List<DailyEggRecord> _records = [];
  List<DailyEggRecord> get records => List.unmodifiable(_records);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;

  bool get isLoading => _state == EggState.loading;
  bool get hasError => _state == EggState.error;

  // Cached statistics
  int? _cachedTotalCollected;
  int? _cachedTotalConsumed;
  int? _cachedTotalRemaining;

  /// Total eggs collected (all records)
  int get totalEggsCollected {
    _cachedTotalCollected ??= _records.fold<int>(0, (sum, r) => sum + r.eggsCollected);
    return _cachedTotalCollected!;
  }

  /// Total eggs consumed (all records)
  int get totalEggsConsumed {
    _cachedTotalConsumed ??= _records.fold<int>(0, (sum, r) => sum + r.eggsConsumed);
    return _cachedTotalConsumed!;
  }

  /// Total eggs remaining (all records)
  int get totalEggsRemaining {
    _cachedTotalRemaining ??= _records.fold<int>(0, (sum, r) => sum + r.eggsRemaining);
    return _cachedTotalRemaining!;
  }

  /// Number of records
  int get recordCount => _records.length;

  void _invalidateCache() {
    _cachedTotalCollected = null;
    _cachedTotalConsumed = null;
    _cachedTotalRemaining = null;
  }

  /// Load all egg records
  Future<bool> loadRecords() async {
    _state = EggState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _getEggRecords(const NoParams());

      if (result.isSuccess) {
        _records = List.from(result.value);
        _records.sort((a, b) => b.date.compareTo(a.date));
        _invalidateCache();
        _state = EggState.loaded;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.failure.message;
        _state = EggState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = EggState.error;
      notifyListeners();
      return false;
    }
  }

  /// Get record for a specific date (from local cache)
  DailyEggRecord? getRecordByDate(String date) {
    if (date.isEmpty) return null;
    try {
      return _records.firstWhere((r) => r.date == date);
    } catch (_) {
      return null;
    }
  }

  /// Create or update a record
  Future<void> saveRecord(DailyEggRecord record) async {
    _validateRecord(record);

    try {
      final Result<DailyEggRecord> result;

      // Check if this is a new record or update
      final isNew = record.id.isEmpty || !_records.any((r) => r.id == record.id);

      if (isNew) {
        result = await _createEggRecord(CreateEggRecordParams(record: record));
      } else {
        result = await _updateEggRecord(UpdateEggRecordParams(record: record));
      }

      if (result.isSuccess) {
        final savedRecord = result.value;
        final index = _records.indexWhere((r) => r.id == savedRecord.id);
        _records = List.from(_records);
        if (index >= 0) {
          _records[index] = savedRecord;
        } else {
          _records.insert(0, savedRecord);
        }
        _records.sort((a, b) => b.date.compareTo(a.date));
        _invalidateCache();
        _errorMessage = null;
        notifyListeners();
      } else {
        _errorMessage = result.failure.message;
        notifyListeners();
        throw Exception(result.failure.message);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a record by date
  Future<void> deleteRecord(String date) async {
    if (date.isEmpty) {
      throw ArgumentError('Data não pode estar vazia');
    }

    try {
      // Find the record by date to get its ID
      final record = _records.firstWhere(
        (r) => r.date == date,
        orElse: () => throw Exception('Record not found'),
      );

      final result = await _deleteEggRecord(DeleteEggRecordParams(id: record.id));

      if (result.isSuccess) {
        _records = _records.where((r) => r.date != date).toList();
        _invalidateCache();
        _errorMessage = null;
        notifyListeners();
      } else {
        _errorMessage = result.failure.message;
        notifyListeners();
        throw Exception(result.failure.message);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get records in a date range
  List<DailyEggRecord> getRecordsInRange(DateTime start, DateTime end) {
    if (start.isAfter(end)) return [];

    final startStr = AppDateUtils.toIsoDateString(start);
    final endStr = AppDateUtils.toIsoDateString(end);

    return _records.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList();
  }

  /// Get recent records
  List<DailyEggRecord> getRecentRecords(int count) {
    if (count <= 0) return [];
    return _records.take(count).toList();
  }

  /// Search records by text (date or notes)
  List<DailyEggRecord> search(String query) {
    if (query.isEmpty) return List.unmodifiable(_records);

    final normalizedQuery = query.toLowerCase().trim();

    return _records.where((r) {
      final notesMatch = r.notes?.toLowerCase().contains(normalizedQuery) ?? false;
      final dateMatch = r.date.contains(query);
      return notesMatch || dateMatch;
    }).toList();
  }

  /// Get today's record
  DailyEggRecord? get todayRecord {
    final todayStr = AppDateUtils.todayString();
    return getRecordByDate(todayStr);
  }

  /// Get total eggs collected today
  int get todayEggs => todayRecord?.eggsCollected ?? 0;

  /// Clear all data (used on logout)
  void clearData() {
    _records = [];
    _errorMessage = null;
    _state = EggState.initial;
    _invalidateCache();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private helpers
  void _validateRecord(DailyEggRecord record) {
    if (record.eggsCollected < 0) {
      throw ArgumentError('Número de ovos recolhidos não pode ser negativo');
    }
    if (record.eggsConsumed < 0) {
      throw ArgumentError('Número de ovos consumidos não pode ser negativo');
    }
    if (record.date.isEmpty) {
      throw ArgumentError('Data não pode estar vazia');
    }
  }
}
