import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// State for the health/vet feature
enum VetState { initial, loading, loaded, error }

/// Provider for vet records following clean architecture
/// Maintains backward compatibility with VetRecordProvider interface
class VetProvider extends ChangeNotifier {
  final GetVetRecords _getVetRecords;
  final GetUpcomingAppointments _getUpcomingAppointments;
  final CreateVetRecord _createVetRecord;
  final UpdateVetRecord _updateVetRecord;
  final DeleteVetRecord _deleteVetRecord;

  VetProvider({
    required GetVetRecords getVetRecords,
    required GetUpcomingAppointments getUpcomingAppointments,
    required CreateVetRecord createVetRecord,
    required UpdateVetRecord updateVetRecord,
    required DeleteVetRecord deleteVetRecord,
  })  : _getVetRecords = getVetRecords,
        _getUpcomingAppointments = getUpcomingAppointments,
        _createVetRecord = createVetRecord,
        _updateVetRecord = updateVetRecord,
        _deleteVetRecord = deleteVetRecord;

  // State
  VetState _state = VetState.initial;
  VetState get state => _state;

  List<VetRecord> _records = [];
  List<VetRecord> get records => List.unmodifiable(_records);

  // Backward compatibility alias
  List<VetRecord> get vetRecords => records;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Backward compatibility

  bool get isLoading => _state == VetState.loading;
  bool get hasError => _state == VetState.error;

  // --- Cached computed values ---
  List<VetRecord>? _sortedRecordsCache;
  List<VetRecord>? _todayAppointmentsCache;
  String? _todayAppointmentsCacheDate;
  int? _totalDeathsCache;
  double? _totalVetCostsCache;
  int? _totalHensAffectedCache;
  int? _upcomingActionsCache;

  void _invalidateCache() {
    _sortedRecordsCache = null;
    _todayAppointmentsCache = null;
    _todayAppointmentsCacheDate = null;
    _totalDeathsCache = null;
    _totalVetCostsCache = null;
    _totalHensAffectedCache = null;
    _upcomingActionsCache = null;
  }

  // Statistics (cached)
  int get totalVetRecords => _records.length;

  int get totalDeaths {
    _totalDeathsCache ??= _records
        .where((r) => r.type == VetRecordType.death)
        .fold<int>(0, (sum, r) => sum + r.hensAffected);
    return _totalDeathsCache!;
  }

  double get totalVetCosts {
    _totalVetCostsCache ??= _records.fold<double>(0.0, (sum, r) => sum + (r.cost ?? 0.0));
    return _totalVetCostsCache!;
  }

  int get totalHensAffected {
    _totalHensAffectedCache ??= _records.fold<int>(0, (sum, r) => sum + r.hensAffected);
    return _totalHensAffectedCache!;
  }

  int get upcomingActionsCount {
    if (_upcomingActionsCache == null) {
      final now = DateTime.now();
      _upcomingActionsCache = _records
          .where((r) => r.nextActionDate != null)
          .where((r) {
            try {
              return DateTime.parse(r.nextActionDate!).isAfter(now);
            } catch (_) {
              return false;
            }
          })
          .length;
    }
    return _upcomingActionsCache!;
  }

  String _toIsoDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Load all vet records
  Future<void> loadRecords() async {
    _state = VetState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _getVetRecords(const NoParams());

    result.fold(
      onSuccess: (data) {
        _records = data;
        _invalidateCache();
        _state = VetState.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = VetState.error;
      },
    );

    notifyListeners();
  }

  /// Backward compatibility alias
  Future<void> loadVetRecords() => loadRecords();

  /// Get today's appointments (cached per date)
  List<VetRecord> getTodayAppointments() {
    final todayStr = _toIsoDateString(DateTime.now());
    if (_todayAppointmentsCache != null && _todayAppointmentsCacheDate == todayStr) {
      return _todayAppointmentsCache!;
    }
    _todayAppointmentsCacheDate = todayStr;
    _todayAppointmentsCache = _records.where((r) => r.nextActionDate == todayStr).toList();
    return _todayAppointmentsCache!;
  }

  /// Get all vet records sorted by date (cached)
  List<VetRecord> getVetRecords() {
    if (_sortedRecordsCache == null) {
      _sortedRecordsCache = List<VetRecord>.from(_records);
      _sortedRecordsCache!.sort((a, b) => b.date.compareTo(a.date));
    }
    return _sortedRecordsCache!;
  }

  /// Get records by type
  List<VetRecord> getVetRecordsByType(VetRecordType type) {
    return _records.where((r) => r.type == type).toList();
  }

  /// Get upcoming vet actions
  List<VetRecord> getUpcomingVetActions() {
    final now = DateTime.now();
    return _records
        .where((r) => r.nextActionDate != null)
        .where((r) {
          try {
            final nextDate = DateTime.parse(r.nextActionDate!);
            return nextDate.isAfter(now);
          } catch (_) {
            return false;
          }
        })
        .toList()
      ..sort((a, b) => a.nextActionDate!.compareTo(b.nextActionDate!));
  }

  /// Get upcoming appointments (async)
  Future<List<VetRecord>> getUpcomingAppointments() async {
    final result = await _getUpcomingAppointments(const NoParams());
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (_) => [],
    );
  }

  /// Get upcoming appointments (local filtering)
  List<VetRecord> getUpcomingAppointmentsLocal() {
    final todayStr = _toIsoDateString(DateTime.now());
    return _records.where((r) =>
      r.nextActionDate != null && r.nextActionDate!.compareTo(todayStr) >= 0
    ).toList();
  }

  /// Search vet records by type, notes, medication, or date
  List<VetRecord> search(String query) {
    if (query.isEmpty) return getVetRecords();
    final q = query.toLowerCase();
    final sorted = _records.where((r) {
      final typeMatch = r.type.name.toLowerCase().contains(q);
      final notesMatch = r.notes?.toLowerCase().contains(q) ?? false;
      final medicationMatch = r.medication?.toLowerCase().contains(q) ?? false;
      final dateMatch = r.date.toLowerCase().contains(q);
      return typeMatch || notesMatch || medicationMatch || dateMatch;
    }).toList();
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// Save a vet record (create or update)
  Future<void> saveVetRecord(VetRecord record) async {
    _state = VetState.loading;
    notifyListeners();

    final Result<VetRecord> result;

    if (record.id.isEmpty || !_records.any((r) => r.id == record.id)) {
      result = await _createVetRecord(CreateVetRecordParams(record: record));
    } else {
      result = await _updateVetRecord(UpdateVetRecordParams(record: record));
    }

    result.fold(
      onSuccess: (savedRecord) {
        final index = _records.indexWhere((r) => r.id == savedRecord.id);
        if (index >= 0) {
          _records[index] = savedRecord;
        } else {
          _records.insert(0, savedRecord);
        }
        _records.sort((a, b) => b.date.compareTo(a.date));
        _invalidateCache();
        _state = VetState.loaded;
        _errorMessage = null;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = VetState.error;
      },
    );

    notifyListeners();
  }

  /// Alias for backward compatibility
  Future<bool> saveRecord(VetRecord record) async {
    await saveVetRecord(record);
    return !hasError;
  }

  /// Delete a vet record
  Future<void> deleteVetRecord(String id) async {
    _state = VetState.loading;
    notifyListeners();

    final result = await _deleteVetRecord(DeleteVetRecordParams(id: id));

    result.fold(
      onSuccess: (_) {
        _records.removeWhere((r) => r.id == id);
        _invalidateCache();
        _state = VetState.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = VetState.error;
      },
    );

    notifyListeners();
  }

  /// Alias for backward compatibility
  Future<bool> deleteRecord(String id) async {
    await deleteVetRecord(id);
    return !hasError;
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data (used on logout)
  void clearData() {
    _records = [];
    _errorMessage = null;
    _invalidateCache();
    _state = VetState.initial;
    notifyListeners();
  }
}

/// Type alias for backward compatibility
typedef VetRecordProvider = VetProvider;
