import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// State for the egg feature
enum EggState { initial, loading, loaded, error }

/// Provider for egg records following clean architecture
///
/// Uses use cases from the domain layer instead of directly accessing repositories
class EggProvider extends ChangeNotifier {
  final GetEggRecords _getEggRecords;
  final GetEggRecordByDate _getEggRecordByDate;
  final CreateEggRecord _createEggRecord;
  final UpdateEggRecord _updateEggRecord;
  final DeleteEggRecord _deleteEggRecord;

  EggProvider({
    required GetEggRecords getEggRecords,
    required GetEggRecordByDate getEggRecordByDate,
    required CreateEggRecord createEggRecord,
    required UpdateEggRecord updateEggRecord,
    required DeleteEggRecord deleteEggRecord,
  })  : _getEggRecords = getEggRecords,
        _getEggRecordByDate = getEggRecordByDate,
        _createEggRecord = createEggRecord,
        _updateEggRecord = updateEggRecord,
        _deleteEggRecord = deleteEggRecord;

  // State
  EggState _state = EggState.initial;
  EggState get state => _state;

  List<DailyEggRecord> _records = [];
  List<DailyEggRecord> get records => _records;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == EggState.loading;
  bool get hasError => _state == EggState.error;

  /// Load all egg records
  Future<void> loadRecords() async {
    _state = EggState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _getEggRecords(const NoParams());

    result.fold(
      onSuccess: (data) {
        _records = data;
        _state = EggState.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = EggState.error;
      },
    );

    notifyListeners();
  }

  /// Get record for a specific date
  Future<DailyEggRecord?> getRecordByDate(String date) async {
    final result = await _getEggRecordByDate(
      GetEggRecordByDateParams(date: date),
    );

    return result.fold(
      onSuccess: (data) => data,
      onFailure: (_) => null,
    );
  }

  /// Create or update a record
  Future<bool> saveRecord(DailyEggRecord record) async {
    _state = EggState.loading;
    notifyListeners();

    final Result<DailyEggRecord> result;

    // Check if this is a new record (no id or empty id) or update
    if (record.id.isEmpty || !_records.any((r) => r.id == record.id)) {
      result = await _createEggRecord(CreateEggRecordParams(record: record));
    } else {
      result = await _updateEggRecord(UpdateEggRecordParams(record: record));
    }

    final success = result.fold(
      onSuccess: (savedRecord) {
        // Update local list
        final index = _records.indexWhere((r) => r.id == savedRecord.id);
        if (index >= 0) {
          _records[index] = savedRecord;
        } else {
          _records.insert(0, savedRecord);
        }
        _records.sort((a, b) => b.date.compareTo(a.date));
        _state = EggState.loaded;
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = EggState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
  }

  /// Delete a record
  Future<bool> deleteRecord(String id) async {
    _state = EggState.loading;
    notifyListeners();

    final result = await _deleteEggRecord(DeleteEggRecordParams(id: id));

    final success = result.fold(
      onSuccess: (_) {
        _records.removeWhere((r) => r.id == id);
        _state = EggState.loaded;
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = EggState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
  }

  /// Get today's record
  DailyEggRecord? get todayRecord {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _records.cast<DailyEggRecord?>().firstWhere(
      (r) => r?.date == todayStr,
      orElse: () => null,
    );
  }

  /// Get total eggs collected today
  int get todayEggs => todayRecord?.eggsCollected ?? 0;

  /// Get records for the last N days
  List<DailyEggRecord> getRecentRecords(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    return _records.where((r) => r.date.compareTo(cutoffStr) >= 0).toList();
  }
}
