// test/features/health/presentation/providers/vet_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/core.dart';
import 'package:hckegg_lite/features/health/domain/domain.dart';
import 'package:hckegg_lite/features/health/presentation/providers/vet_provider.dart';
import 'package:hckegg_lite/models/vet_record.dart';

// Mock Repository
class MockVetRepository implements VetRepository {
  List<VetRecord> recordsToReturn = [];
  Failure? failureToReturn;

  @override
  Future<Result<List<VetRecord>>> getRecords() async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(recordsToReturn);
  }

  @override
  Future<Result<VetRecord>> getRecordById(String id) async {
    final record = recordsToReturn.firstWhere((r) => r.id == id);
    return Result.success(record);
  }

  @override
  Future<Result<List<VetRecord>>> getRecordsByType(VetRecordType type) async {
    final filtered = recordsToReturn.where((r) => r.type == type).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<VetRecord>>> getUpcomingAppointments() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final filtered = recordsToReturn.where((r) {
      return r.nextActionDate != null && r.nextActionDate!.compareTo(todayStr) >= 0;
    }).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<VetRecord>>> getTodayAppointments() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final filtered = recordsToReturn.where((r) => r.nextActionDate == todayStr).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<VetRecord>> createRecord(VetRecord record) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(record);
  }

  @override
  Future<Result<VetRecord>> updateRecord(VetRecord record) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(record);
  }

  @override
  Future<Result<void>> deleteRecord(String id) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(null);
  }
}

void main() {
  late MockVetRepository mockRepository;
  late VetProvider provider;

  setUp(() {
    mockRepository = MockVetRepository();

    provider = VetProvider(
      getVetRecords: GetVetRecords(mockRepository),
      getUpcomingAppointments: GetUpcomingAppointments(mockRepository),
      createVetRecord: CreateVetRecord(mockRepository),
      updateVetRecord: UpdateVetRecord(mockRepository),
      deleteVetRecord: DeleteVetRecord(mockRepository),
    );
  });

  group('VetProvider', () {
    group('initial state', () {
      test('starts with empty records list', () {
        expect(provider.vetRecords, isEmpty);
      });

      test('starts with initial state', () {
        expect(provider.state, VetState.initial);
      });

      test('starts with no error', () {
        expect(provider.errorMessage, isNull);
      });
    });

    group('loadVetRecords', () {
      test('loads records successfully', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetRecordType.checkup),
          _createVetRecord('2', '2024-01-14', VetRecordType.vaccine),
        ];

        await provider.loadVetRecords();

        expect(provider.vetRecords.length, 2);
        expect(provider.state, VetState.loaded);
      });

      test('sets error state on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Network error');

        await provider.loadVetRecords();

        expect(provider.state, VetState.error);
        expect(provider.errorMessage, 'Network error');
      });
    });

    group('saveVetRecord', () {
      test('creates new record successfully', () async {
        final record = _createVetRecord('1', '2024-01-15', VetRecordType.checkup);

        await provider.saveVetRecord(record);

        expect(provider.vetRecords.length, 1);
        expect(provider.state, VetState.loaded);
      });

      test('updates existing record', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetRecordType.checkup),
        ];
        await provider.loadVetRecords();
        mockRepository.failureToReturn = null;

        final updatedRecord = _createVetRecord('1', '2024-01-15', VetRecordType.treatment);
        await provider.saveVetRecord(updatedRecord);

        expect(provider.vetRecords.length, 1);
        expect(provider.vetRecords[0].type, VetRecordType.treatment);
      });

      test('sets error state on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Save failed');
        final record = _createVetRecord('1', '2024-01-15', VetRecordType.checkup);

        await provider.saveVetRecord(record);

        expect(provider.state, VetState.error);
      });
    });

    group('deleteVetRecord', () {
      test('removes record from list', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetRecordType.checkup),
          _createVetRecord('2', '2024-01-14', VetRecordType.vaccine),
        ];
        await provider.loadVetRecords();
        mockRepository.failureToReturn = null;

        await provider.deleteVetRecord('1');

        expect(provider.vetRecords.length, 1);
        expect(provider.vetRecords[0].id, '2');
      });

      test('sets error state on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Delete failed');

        await provider.deleteVetRecord('1');

        expect(provider.state, VetState.error);
      });
    });

    group('search', () {
      test('returns all records when query is empty', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetRecordType.checkup),
          _createVetRecord('2', '2024-01-14', VetRecordType.vaccine),
        ];
        await provider.loadVetRecords();

        final results = provider.search('');

        expect(results.length, 2);
      });

      test('filters by type name', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetRecordType.checkup),
          _createVetRecord('2', '2024-01-14', VetRecordType.vaccine),
        ];
        await provider.loadVetRecords();

        final results = provider.search('vaccine');

        expect(results.length, 1);
        expect(results[0].type, VetRecordType.vaccine);
      });

      test('filters by notes', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetRecordType.checkup, notes: 'Annual checkup'),
          _createVetRecord('2', '2024-01-14', VetRecordType.vaccine, notes: 'Flu vaccine'),
        ];
        await provider.loadVetRecords();

        final results = provider.search('annual');

        expect(results.length, 1);
        expect(results[0].notes, 'Annual checkup');
      });
    });

    group('statistics', () {
      test('calculates totalDeaths as sum of hensAffected', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetRecordType.death, hensAffected: 3),
          _createVetRecord('2', '2024-01-14', VetRecordType.death, hensAffected: 5),
          _createVetRecord('3', '2024-01-13', VetRecordType.checkup, hensAffected: 10),
        ];
        await provider.loadVetRecords();

        // Should be 3 + 5 = 8 (only death records count)
        expect(provider.totalDeaths, 8);
      });

      test('calculates totalVetCosts correctly', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetRecordType.checkup, cost: 50.0),
          _createVetRecord('2', '2024-01-14', VetRecordType.treatment, cost: 30.0),
        ];
        await provider.loadVetRecords();

        expect(provider.totalVetCosts, closeTo(80.0, 0.01));
      });

      test('calculates totalHensAffected correctly', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetRecordType.disease, hensAffected: 5),
          _createVetRecord('2', '2024-01-14', VetRecordType.treatment, hensAffected: 3),
        ];
        await provider.loadVetRecords();

        expect(provider.totalHensAffected, 8);
      });
    });

    group('clearData', () {
      test('clears all records and resets state', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetRecordType.checkup),
        ];
        await provider.loadVetRecords();
        expect(provider.vetRecords.length, 1);

        provider.clearData();

        expect(provider.vetRecords, isEmpty);
        expect(provider.state, VetState.initial);
        expect(provider.errorMessage, isNull);
      });
    });
  });
}

VetRecord _createVetRecord(
  String id,
  String date,
  VetRecordType type, {
  String? notes,
  double? cost,
  int hensAffected = 1,
}) {
  return VetRecord(
    id: id,
    date: date,
    type: type,
    hensAffected: hensAffected,
    description: 'Test record',
    notes: notes,
    cost: cost,
  );
}
