// test/state/providers/vet_record_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/core.dart';
import 'package:hckegg_lite/models/vet_record.dart';
import 'package:hckegg_lite/features/health/domain/usecases/vet_usecases.dart';
import 'package:hckegg_lite/features/health/domain/repositories/vet_repository.dart';
import 'package:hckegg_lite/state/providers/vet_record_provider.dart';

// Mock Use Cases
class MockGetVetRecords implements GetVetRecords {
  @override
  VetRepository get repository => throw UnimplementedError();

  List<VetRecord> records = [];
  bool shouldFail = false;
  int callCount = 0;

  @override
  Future<Result<List<VetRecord>>> call(NoParams params) async {
    callCount++;
    if (shouldFail) {
      return Result.fail(ServerFailure(message: 'Simulated load error'));
    }
    return Result.success(List.from(records));
  }
}

class MockGetUpcomingAppointments implements GetUpcomingAppointments {
  @override
  VetRepository get repository => throw UnimplementedError();

  List<VetRecord> records = [];

  @override
  Future<Result<List<VetRecord>>> call(NoParams params) async {
    return Result.success(records);
  }
}

class MockCreateVetRecord implements CreateVetRecord {
  @override
  VetRepository get repository => throw UnimplementedError();

  bool shouldFail = false;
  int callCount = 0;

  @override
  Future<Result<VetRecord>> call(CreateVetRecordParams params) async {
    callCount++;
    if (shouldFail) {
      return Result.fail(ServerFailure(message: 'Simulated save error'));
    }
    return Result.success(params.record);
  }
}

class MockUpdateVetRecord implements UpdateVetRecord {
  @override
  VetRepository get repository => throw UnimplementedError();

  bool shouldFail = false;
  int callCount = 0;

  @override
  Future<Result<VetRecord>> call(UpdateVetRecordParams params) async {
    callCount++;
    if (shouldFail) {
      return Result.fail(ServerFailure(message: 'Simulated update error'));
    }
    return Result.success(params.record);
  }
}

class MockDeleteVetRecord implements DeleteVetRecord {
  @override
  VetRepository get repository => throw UnimplementedError();

  bool shouldFail = false;
  int callCount = 0;

  @override
  Future<Result<void>> call(DeleteVetRecordParams params) async {
    callCount++;
    if (shouldFail) {
      return Result.fail(ServerFailure(message: 'Simulated delete error'));
    }
    return Result.success(null);
  }
}

void main() {
  late MockGetVetRecords mockGetVetRecords;
  late MockGetUpcomingAppointments mockGetUpcomingAppointments;
  late MockCreateVetRecord mockCreateVetRecord;
  late MockUpdateVetRecord mockUpdateVetRecord;
  late MockDeleteVetRecord mockDeleteVetRecord;
  late VetRecordProvider provider;

  setUp(() {
    mockGetVetRecords = MockGetVetRecords();
    mockGetUpcomingAppointments = MockGetUpcomingAppointments();
    mockCreateVetRecord = MockCreateVetRecord();
    mockUpdateVetRecord = MockUpdateVetRecord();
    mockDeleteVetRecord = MockDeleteVetRecord();

    provider = VetRecordProvider(
      getVetRecords: mockGetVetRecords,
      getUpcomingAppointments: mockGetUpcomingAppointments,
      createVetRecord: mockCreateVetRecord,
      updateVetRecord: mockUpdateVetRecord,
      deleteVetRecord: mockDeleteVetRecord,
    );
  });

  group('VetRecordProvider', () {
    group('initial state', () {
      test('starts with empty records list', () {
        expect(provider.vetRecords, isEmpty);
      });

      test('starts with isLoading false', () {
        expect(provider.isLoading, false);
      });

      test('starts with no error', () {
        expect(provider.error, isNull);
      });

      test('statistics are zero initially', () {
        expect(provider.totalVetRecords, 0);
        expect(provider.totalDeaths, 0);
        expect(provider.totalVetCosts, 0.0);
        expect(provider.totalHensAffected, 0);
      });
    });

    group('loadVetRecords', () {
      test('loads records from use case', () async {
        final testRecords = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.checkup),
        ];
        mockGetVetRecords.records = testRecords;

        await provider.loadVetRecords();

        expect(provider.vetRecords.length, 2);
        expect(mockGetVetRecords.callCount, 1);
      });

      test('sets error on failure', () async {
        mockGetVetRecords.shouldFail = true;

        await provider.loadVetRecords();

        expect(provider.error, isNotNull);
        expect(provider.error, contains('Simulated load error'));
      });
    });

    group('saveVetRecord', () {
      test('adds new record to list', () async {
        final record = _createVetRecord('1', '2024-01-15', VetRecordType.vaccine);

        await provider.saveVetRecord(record);

        expect(provider.vetRecords.length, 1);
        expect(provider.vetRecords[0].type, VetRecordType.vaccine);
        expect(mockCreateVetRecord.callCount, 1);
      });

      test('updates existing record with same id', () async {
        // First load records
        mockGetVetRecords.records = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
        ];
        await provider.loadVetRecords();

        // Then update
        final record2 = _createVetRecord('1', '2024-01-15', VetRecordType.treatment);
        await provider.saveVetRecord(record2);

        expect(provider.vetRecords.length, 1);
        expect(provider.vetRecords[0].type, VetRecordType.treatment);
        expect(mockUpdateVetRecord.callCount, 1);
      });

      test('sets error on save failure', () async {
        mockCreateVetRecord.shouldFail = true;
        final record = _createVetRecord('1', '2024-01-15', VetRecordType.vaccine);

        await provider.saveVetRecord(record);

        expect(provider.error, isNotNull);
        expect(provider.hasError, true);
      });
    });

    group('deleteVetRecord', () {
      test('removes record from list', () async {
        mockGetVetRecords.records = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.checkup),
        ];
        await provider.loadVetRecords();

        await provider.deleteVetRecord('1');

        expect(provider.vetRecords.length, 1);
        expect(provider.vetRecords[0].id, '2');
        expect(mockDeleteVetRecord.callCount, 1);
      });

      test('sets error on delete failure', () async {
        mockDeleteVetRecord.shouldFail = true;

        await provider.deleteVetRecord('1');

        expect(provider.error, isNotNull);
        expect(provider.hasError, true);
      });
    });

    group('statistics', () {
      test('calculates totalVetRecords correctly', () async {
        mockGetVetRecords.records = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.checkup),
          _createVetRecord('3', '2024-01-17', VetRecordType.treatment),
        ];
        await provider.loadVetRecords();

        expect(provider.totalVetRecords, 3);
      });

      test('calculates totalDeaths correctly', () async {
        mockGetVetRecords.records = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.death),
          _createVetRecord('3', '2024-01-17', VetRecordType.death),
        ];
        await provider.loadVetRecords();

        expect(provider.totalDeaths, 2);
      });

      test('calculates totalVetCosts correctly', () async {
        mockGetVetRecords.records = [
          _createVetRecordWithCost('1', '2024-01-15', 50.0),
          _createVetRecordWithCost('2', '2024-01-16', 75.50),
          _createVetRecordWithCost('3', '2024-01-17', 25.0),
        ];
        await provider.loadVetRecords();

        expect(provider.totalVetCosts, closeTo(150.50, 0.01));
      });

      test('calculates totalHensAffected correctly', () async {
        mockGetVetRecords.records = [
          _createVetRecordWithHens('1', '2024-01-15', 5),
          _createVetRecordWithHens('2', '2024-01-16', 10),
          _createVetRecordWithHens('3', '2024-01-17', 3),
        ];
        await provider.loadVetRecords();

        expect(provider.totalHensAffected, 18);
      });

      test('handles records with null cost', () async {
        mockGetVetRecords.records = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine), // no cost
          _createVetRecordWithCost('2', '2024-01-16', 50.0),
        ];
        await provider.loadVetRecords();

        expect(provider.totalVetCosts, closeTo(50.0, 0.01));
      });
    });

    group('getVetRecords', () {
      test('returns records sorted by date descending', () async {
        mockGetVetRecords.records = [
          _createVetRecord('1', '2024-01-10', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-20', VetRecordType.checkup),
          _createVetRecord('3', '2024-01-15', VetRecordType.treatment),
        ];
        await provider.loadVetRecords();

        final sorted = provider.getVetRecords();

        expect(sorted[0].date, '2024-01-20');
        expect(sorted[1].date, '2024-01-15');
        expect(sorted[2].date, '2024-01-10');
      });
    });

    group('getVetRecordsByType', () {
      test('returns records of specified type', () async {
        mockGetVetRecords.records = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.checkup),
          _createVetRecord('3', '2024-01-17', VetRecordType.vaccine),
          _createVetRecord('4', '2024-01-18', VetRecordType.treatment),
        ];
        await provider.loadVetRecords();

        final vaccines = provider.getVetRecordsByType(VetRecordType.vaccine);

        expect(vaccines.length, 2);
        expect(vaccines.every((r) => r.type == VetRecordType.vaccine), true);
      });

      test('returns empty list when no records of type', () async {
        mockGetVetRecords.records = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
        ];
        await provider.loadVetRecords();

        final deaths = provider.getVetRecordsByType(VetRecordType.death);

        expect(deaths, isEmpty);
      });
    });

    group('getUpcomingVetActions', () {
      test('returns records with future nextActionDate', () async {
        final futureDate = DateTime.now().add(const Duration(days: 10));
        final futureDateStr = _toIsoDate(futureDate);
        final pastDate = DateTime.now().subtract(const Duration(days: 10));
        final pastDateStr = _toIsoDate(pastDate);

        mockGetVetRecords.records = [
          _createVetRecordWithNextAction('1', '2024-01-15', futureDateStr),
          _createVetRecordWithNextAction('2', '2024-01-16', pastDateStr),
          _createVetRecord('3', '2024-01-17', VetRecordType.checkup), // no next action
        ];
        await provider.loadVetRecords();

        final upcoming = provider.getUpcomingVetActions();

        expect(upcoming.length, 1);
        expect(upcoming[0].id, '1');
      });

      test('returns sorted by nextActionDate ascending', () async {
        final future1 = DateTime.now().add(const Duration(days: 5));
        final future2 = DateTime.now().add(const Duration(days: 15));
        final future3 = DateTime.now().add(const Duration(days: 10));

        mockGetVetRecords.records = [
          _createVetRecordWithNextAction('1', '2024-01-15', _toIsoDate(future2)),
          _createVetRecordWithNextAction('2', '2024-01-16', _toIsoDate(future1)),
          _createVetRecordWithNextAction('3', '2024-01-17', _toIsoDate(future3)),
        ];
        await provider.loadVetRecords();

        final upcoming = provider.getUpcomingVetActions();

        expect(upcoming.length, 3);
        expect(upcoming[0].id, '2'); // 5 days
        expect(upcoming[1].id, '3'); // 10 days
        expect(upcoming[2].id, '1'); // 15 days
      });
    });

    group('getTodayAppointments', () {
      test('returns records scheduled for today', () async {
        final todayStr = _toIsoDate(DateTime.now());
        final tomorrowStr = _toIsoDate(DateTime.now().add(const Duration(days: 1)));

        mockGetVetRecords.records = [
          _createVetRecordWithNextAction('1', '2024-01-15', todayStr),
          _createVetRecordWithNextAction('2', '2024-01-16', tomorrowStr),
          _createVetRecordWithNextAction('3', '2024-01-17', todayStr),
        ];
        await provider.loadVetRecords();

        final today = provider.getTodayAppointments();

        expect(today.length, 2);
        expect(today.every((r) => r.nextActionDate == todayStr), true);
      });

      test('returns empty list when no appointments today', () async {
        final tomorrowStr = _toIsoDate(DateTime.now().add(const Duration(days: 1)));

        mockGetVetRecords.records = [
          _createVetRecordWithNextAction('1', '2024-01-15', tomorrowStr),
        ];
        await provider.loadVetRecords();

        final today = provider.getTodayAppointments();

        expect(today, isEmpty);
      });
    });

    group('clearData', () {
      test('clears all records', () async {
        mockGetVetRecords.records = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.checkup),
        ];
        await provider.loadVetRecords();
        expect(provider.vetRecords.length, 2);

        provider.clearData();

        expect(provider.vetRecords, isEmpty);
        expect(provider.error, isNull);
        expect(provider.isLoading, false);
      });
    });

    group('records immutability', () {
      test('records getter returns unmodifiable list', () async {
        mockGetVetRecords.records = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
        ];
        await provider.loadVetRecords();

        final records = provider.records;

        expect(
          () => (records as List).add(_createVetRecord('2', '2024-01-16', VetRecordType.checkup)),
          throwsUnsupportedError,
        );
      });
    });
  });
}

VetRecord _createVetRecord(String id, String date, VetRecordType type) {
  return VetRecord(
    id: id,
    date: date,
    type: type,
    hensAffected: 1,
    description: 'Test record',
  );
}

VetRecord _createVetRecordWithCost(String id, String date, double cost) {
  return VetRecord(
    id: id,
    date: date,
    type: VetRecordType.treatment,
    hensAffected: 1,
    description: 'Test record',
    cost: cost,
  );
}

VetRecord _createVetRecordWithHens(String id, String date, int hensAffected) {
  return VetRecord(
    id: id,
    date: date,
    type: VetRecordType.vaccine,
    hensAffected: hensAffected,
    description: 'Test record',
  );
}

VetRecord _createVetRecordWithNextAction(String id, String date, String nextActionDate) {
  return VetRecord(
    id: id,
    date: date,
    type: VetRecordType.checkup,
    hensAffected: 1,
    description: 'Test record',
    nextActionDate: nextActionDate,
  );
}

String _toIsoDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
