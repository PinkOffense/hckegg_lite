import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// State for the health/vet feature
enum VetState { initial, loading, loaded, error }

/// Provider for vet records following clean architecture
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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == VetState.loading;
  bool get hasError => _state == VetState.error;

  /// Load all vet records
  Future<void> loadRecords() async {
    _state = VetState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _getVetRecords(const NoParams());

    result.fold(
      onSuccess: (data) {
        _records = data;
        _state = VetState.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = VetState.error;
      },
    );

    notifyListeners();
  }

  /// Get upcoming appointments
  Future<List<VetRecord>> getUpcomingAppointments() async {
    final result = await _getUpcomingAppointments(const NoParams());
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (_) => [],
    );
  }

  /// Get upcoming appointments (local filtering)
  List<VetRecord> getUpcomingAppointmentsLocal() {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _records.where((r) =>
      r.nextAppointment != null && r.nextAppointment!.compareTo(todayStr) >= 0
    ).toList();
  }

  /// Save a vet record (create or update)
  Future<bool> saveRecord(VetRecord record) async {
    _state = VetState.loading;
    notifyListeners();

    final Result<VetRecord> result;

    if (record.id.isEmpty || !_records.any((r) => r.id == record.id)) {
      result = await _createVetRecord(CreateVetRecordParams(record: record));
    } else {
      result = await _updateVetRecord(UpdateVetRecordParams(record: record));
    }

    final success = result.fold(
      onSuccess: (savedRecord) {
        final index = _records.indexWhere((r) => r.id == savedRecord.id);
        if (index >= 0) {
          _records[index] = savedRecord;
        } else {
          _records.insert(0, savedRecord);
        }
        _records.sort((a, b) => b.date.compareTo(a.date));
        _state = VetState.loaded;
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = VetState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
  }

  /// Delete a vet record
  Future<bool> deleteRecord(String id) async {
    _state = VetState.loading;
    notifyListeners();

    final result = await _deleteVetRecord(DeleteVetRecordParams(id: id));

    final success = result.fold(
      onSuccess: (_) {
        _records.removeWhere((r) => r.id == id);
        _state = VetState.loaded;
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = VetState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
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
    _state = VetState.initial;
    notifyListeners();
  }
}
