// test/features/eggs/presentation/providers/egg_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/core.dart';
import 'package:hckegg_lite/features/eggs/domain/domain.dart';
import 'package:hckegg_lite/features/eggs/presentation/providers/egg_provider.dart';
import 'package:hckegg_lite/models/daily_egg_record.dart';

// Mock Repository
class MockEggRepository implements EggRepository {
  List<DailyEggRecord> recordsToReturn = [];
  Failure? failureToReturn;

  @override
  Future<Result<List<DailyEggRecord>>> getRecords() async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(recordsToReturn);
  }

  @override
  Future<Result<DailyEggRecord>> getRecordById(String id) async {
    final record = recordsToReturn.firstWhere((r) => r.id == id);
    return Result.success(record);
  }

  @override
  Future<Result<DailyEggRecord?>> getRecordByDate(String date) async {
    try {
      final record = recordsToReturn.firstWhere((r) => r.date == date);
      return Result.success(record);
    } catch (_) {
      return Result.success(null);
    }
  }

  @override
  Future<Result<List<DailyEggRecord>>> getRecordsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final filtered = recordsToReturn.where((r) {
      return r.date.compareTo(startDate) >= 0 && r.date.compareTo(endDate) <= 0;
    }).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<DailyEggRecord>> createRecord(DailyEggRecord record) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(record);
  }

  @override
  Future<Result<DailyEggRecord>> updateRecord(DailyEggRecord record) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(record);
  }

  @override
  Future<Result<void>> deleteRecord(String id) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(null);
  }

  @override
  Future<Result<int>> getTotalEggsCollected({
    required String startDate,
    required String endDate,
  }) async {
    final total = recordsToReturn
        .where((r) => r.date.compareTo(startDate) >= 0 && r.date.compareTo(endDate) <= 0)
        .fold<int>(0, (sum, r) => sum + r.eggsCollected);
    return Result.success(total);
  }
}

void main() {
  late MockEggRepository mockRepository;
  late EggProvider provider;

  setUp(() {
    mockRepository = MockEggRepository();

    provider = EggProvider(
      getEggRecords: GetEggRecords(mockRepository),
      getEggRecordByDate: GetEggRecordByDate(mockRepository),
      createEggRecord: CreateEggRecord(mockRepository),
      updateEggRecord: UpdateEggRecord(mockRepository),
      deleteEggRecord: DeleteEggRecord(mockRepository),
    );
  });

  group('EggProvider', () {
    group('initial state', () {
      test('starts with empty records list', () {
        expect(provider.records, isEmpty);
      });

      test('starts with initial state', () {
        expect(provider.state, EggState.initial);
      });

      test('starts with no error', () {
        expect(provider.errorMessage, isNull);
      });

      test('statistics are zero initially', () {
        expect(provider.totalEggsCollected, 0);
        expect(provider.totalEggsConsumed, 0);
        expect(provider.totalEggsRemaining, 0);
      });
    });

    group('loadRecords', () {
      test('loads records successfully', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
          _createRecord('2', '2024-01-14', 8, 1),
        ];

        await provider.loadRecords();

        expect(provider.records.length, 2);
        expect(provider.state, EggState.loaded);
      });

      test('sets error state on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Network error');

        await provider.loadRecords();

        expect(provider.state, EggState.error);
        expect(provider.errorMessage, 'Network error');
      });

      test('sorts records by date descending', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-10', 10, 2),
          _createRecord('2', '2024-01-15', 8, 1),
          _createRecord('3', '2024-01-12', 12, 0),
        ];

        await provider.loadRecords();

        expect(provider.records[0].date, '2024-01-15');
        expect(provider.records[1].date, '2024-01-12');
        expect(provider.records[2].date, '2024-01-10');
      });
    });

    group('saveRecord', () {
      test('creates new record successfully', () async {
        final record = _createRecord('1', '2024-01-15', 10, 2);

        await provider.saveRecord(record);

        expect(provider.records.length, 1);
      });

      test('updates existing record', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
        ];
        await provider.loadRecords();

        final updatedRecord = _createRecord('1', '2024-01-15', 15, 3);
        await provider.saveRecord(updatedRecord);

        expect(provider.records.length, 1);
        expect(provider.records[0].eggsCollected, 15);
      });

      test('throws on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Save failed');
        final record = _createRecord('1', '2024-01-15', 10, 2);

        expect(
          () => provider.saveRecord(record),
          throwsException,
        );
      });

      test('validates record before saving', () {
        final invalidRecord = DailyEggRecord(
          id: '1',
          date: '2024-01-15',
          eggsCollected: -5, // Invalid: negative
          eggsConsumed: 0,
        );

        expect(
          () => provider.saveRecord(invalidRecord),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('deleteRecord', () {
      test('removes record from list', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
          _createRecord('2', '2024-01-14', 8, 1),
        ];
        await provider.loadRecords();
        mockRepository.failureToReturn = null;

        await provider.deleteRecord('2024-01-15');

        expect(provider.records.length, 1);
        expect(provider.records[0].date, '2024-01-14');
      });

      test('throws on failure', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
        ];
        await provider.loadRecords();
        mockRepository.failureToReturn = ServerFailure(message: 'Delete failed');

        expect(
          () => provider.deleteRecord('2024-01-15'),
          throwsException,
        );
      });
    });

    group('statistics', () {
      test('calculates totalEggsCollected correctly', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
          _createRecord('2', '2024-01-14', 8, 1),
          _createRecord('3', '2024-01-13', 12, 3),
        ];
        await provider.loadRecords();

        expect(provider.totalEggsCollected, 30);
      });

      test('calculates totalEggsConsumed correctly', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
          _createRecord('2', '2024-01-14', 8, 1),
          _createRecord('3', '2024-01-13', 12, 3),
        ];
        await provider.loadRecords();

        expect(provider.totalEggsConsumed, 6);
      });

      test('calculates totalEggsRemaining correctly', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
          _createRecord('2', '2024-01-14', 8, 1),
        ];
        await provider.loadRecords();

        // remaining = collected - consumed = 18 - 3 = 15
        expect(provider.totalEggsRemaining, 15);
      });
    });

    group('search', () {
      test('returns all records when query is empty', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
          _createRecord('2', '2024-01-14', 8, 1),
        ];
        await provider.loadRecords();

        final results = provider.search('');

        expect(results.length, 2);
      });

      test('filters by date', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
          _createRecord('2', '2024-01-14', 8, 1),
          _createRecord('3', '2024-02-01', 12, 0),
        ];
        await provider.loadRecords();

        final results = provider.search('2024-01');

        expect(results.length, 2);
      });

      test('filters by notes', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2, notes: 'Rainy day'),
          _createRecord('2', '2024-01-14', 8, 1, notes: 'Sunny'),
        ];
        await provider.loadRecords();

        final results = provider.search('rainy');

        expect(results.length, 1);
        expect(results[0].notes, 'Rainy day');
      });

      test('search is case insensitive', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2, notes: 'SPECIAL day'),
        ];
        await provider.loadRecords();

        final results = provider.search('special');

        expect(results.length, 1);
      });
    });

    group('getRecentRecords', () {
      test('returns requested number of records', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
          _createRecord('2', '2024-01-14', 8, 1),
          _createRecord('3', '2024-01-13', 12, 0),
          _createRecord('4', '2024-01-12', 9, 1),
        ];
        await provider.loadRecords();

        final recent = provider.getRecentRecords(2);

        expect(recent.length, 2);
      });

      test('returns empty list for zero count', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
        ];
        await provider.loadRecords();

        final recent = provider.getRecentRecords(0);

        expect(recent, isEmpty);
      });
    });

    group('clearData', () {
      test('clears all records and resets state', () async {
        mockRepository.recordsToReturn = [
          _createRecord('1', '2024-01-15', 10, 2),
        ];
        await provider.loadRecords();
        expect(provider.records.length, 1);

        provider.clearData();

        expect(provider.records, isEmpty);
        expect(provider.state, EggState.initial);
        expect(provider.errorMessage, isNull);
      });
    });
  });
}

DailyEggRecord _createRecord(
  String id,
  String date,
  int collected,
  int consumed, {
  String? notes,
}) {
  return DailyEggRecord(
    id: id,
    date: date,
    eggsCollected: collected,
    eggsConsumed: consumed,
    notes: notes,
  );
}
