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
  Future<Result<List<VetRecord>>> getVetRecords() async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(recordsToReturn);
  }

  @override
  Future<Result<VetRecord>> getVetRecordById(String id) async {
    final record = recordsToReturn.firstWhere((r) => r.id == id);
    return Result.success(record);
  }

  @override
  Future<Result<List<VetRecord>>> getUpcomingAppointments() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final filtered = recordsToReturn.where((r) {
      return r.nextVisit != null && r.nextVisit!.compareTo(todayStr) >= 0;
    }).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<VetRecord>> createVetRecord(VetRecord record) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(record);
  }

  @override
  Future<Result<VetRecord>> updateVetRecord(VetRecord record) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(record);
  }

  @override
  Future<Result<void>> deleteVetRecord(String id) async {
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
          _createVetRecord('1', '2024-01-15', VetVisitType.checkup),
          _createVetRecord('2', '2024-01-14', VetVisitType.vaccination),
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
        final record = _createVetRecord('1', '2024-01-15', VetVisitType.checkup);

        final result = await provider.saveVetRecord(record);

        expect(result, true);
        expect(provider.vetRecords.length, 1);
      });

      test('updates existing record', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetVisitType.checkup),
        ];
        await provider.loadVetRecords();

        final updatedRecord = _createVetRecord('1', '2024-01-15', VetVisitType.treatment);
        await provider.saveVetRecord(updatedRecord);

        expect(provider.vetRecords.length, 1);
        expect(provider.vetRecords[0].visitType, VetVisitType.treatment);
      });

      test('returns false on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Save failed');
        final record = _createVetRecord('1', '2024-01-15', VetVisitType.checkup);

        final result = await provider.saveVetRecord(record);

        expect(result, false);
        expect(provider.state, VetState.error);
      });
    });

    group('deleteVetRecord', () {
      test('removes record from list', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetVisitType.checkup),
          _createVetRecord('2', '2024-01-14', VetVisitType.vaccination),
        ];
        await provider.loadVetRecords();
        mockRepository.failureToReturn = null;

        final result = await provider.deleteVetRecord('1');

        expect(result, true);
        expect(provider.vetRecords.length, 1);
        expect(provider.vetRecords[0].id, '2');
      });

      test('returns false on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Delete failed');

        final result = await provider.deleteVetRecord('1');

        expect(result, false);
        expect(provider.state, VetState.error);
      });
    });

    group('search', () {
      test('returns all records when query is empty', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetVisitType.checkup),
          _createVetRecord('2', '2024-01-14', VetVisitType.vaccination),
        ];
        await provider.loadVetRecords();

        final results = provider.search('');

        expect(results.length, 2);
      });

      test('filters by vet name', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetVisitType.checkup, vetName: 'Dr. Smith'),
          _createVetRecord('2', '2024-01-14', VetVisitType.vaccination, vetName: 'Dr. Jones'),
        ];
        await provider.loadVetRecords();

        final results = provider.search('smith');

        expect(results.length, 1);
        expect(results[0].vetName, 'Dr. Smith');
      });

      test('filters by notes', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetVisitType.checkup, notes: 'Annual checkup'),
          _createVetRecord('2', '2024-01-14', VetVisitType.vaccination, notes: 'Flu vaccine'),
        ];
        await provider.loadVetRecords();

        final results = provider.search('annual');

        expect(results.length, 1);
        expect(results[0].notes, 'Annual checkup');
      });
    });

    group('clearData', () {
      test('clears all records and resets state', () async {
        mockRepository.recordsToReturn = [
          _createVetRecord('1', '2024-01-15', VetVisitType.checkup),
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
  VetVisitType visitType, {
  String? vetName,
  String? notes,
}) {
  return VetRecord(
    id: id,
    date: date,
    visitType: visitType,
    vetName: vetName,
    notes: notes,
  );
}
