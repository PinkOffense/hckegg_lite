// test/features/eggs/domain/usecases/egg_usecases_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/core.dart';
import 'package:hckegg_lite/features/eggs/domain/domain.dart';
import 'package:hckegg_lite/models/daily_egg_record.dart';

// Mock Repository for use case testing
class MockEggRepository implements EggRepository {
  List<DailyEggRecord> records = [];
  Failure? failureToReturn;
  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;
  String? lastDeletedId;

  @override
  Future<Result<List<DailyEggRecord>>> getRecords() async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(List.from(records));
  }

  @override
  Future<Result<DailyEggRecord>> getRecordById(String id) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    try {
      final record = records.firstWhere((r) => r.id == id);
      return Result.success(record);
    } catch (_) {
      return Result.fail(const NotFoundFailure(message: 'Record not found'));
    }
  }

  @override
  Future<Result<DailyEggRecord?>> getRecordByDate(String date) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    try {
      final record = records.firstWhere((r) => r.date == date);
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
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    final filtered = records.where((r) {
      return r.date.compareTo(startDate) >= 0 && r.date.compareTo(endDate) <= 0;
    }).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<DailyEggRecord>> createRecord(DailyEggRecord record) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    createCalled = true;
    records.add(record);
    return Result.success(record);
  }

  @override
  Future<Result<DailyEggRecord>> updateRecord(DailyEggRecord record) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    updateCalled = true;
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      records[index] = record;
    }
    return Result.success(record);
  }

  @override
  Future<Result<void>> deleteRecord(String id) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    deleteCalled = true;
    lastDeletedId = id;
    records.removeWhere((r) => r.id == id);
    return Result.success(null);
  }

  @override
  Future<Result<int>> getTotalEggsCollected({
    required String startDate,
    required String endDate,
  }) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    final total = records
        .where((r) =>
            r.date.compareTo(startDate) >= 0 &&
            r.date.compareTo(endDate) <= 0)
        .fold<int>(0, (sum, r) => sum + r.eggsCollected);
    return Result.success(total);
  }

  void reset() {
    records.clear();
    failureToReturn = null;
    createCalled = false;
    updateCalled = false;
    deleteCalled = false;
    lastDeletedId = null;
  }
}

void main() {
  late MockEggRepository mockRepository;

  setUp(() {
    mockRepository = MockEggRepository();
  });

  group('GetEggRecords', () {
    late GetEggRecords useCase;

    setUp(() {
      useCase = GetEggRecords(mockRepository);
    });

    test('returns success with records when repository succeeds', () async {
      mockRepository.records = [
        _createRecord('1', '2024-01-15', 10, 2),
        _createRecord('2', '2024-01-14', 8, 1),
      ];

      final result = await useCase(NoParams());

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 2);
    });

    test('returns empty list when no records exist', () async {
      mockRepository.records = [];

      final result = await useCase(NoParams());

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });

    test('returns failure when repository fails', () async {
      mockRepository.failureToReturn = ServerFailure(message: 'Server error');

      final result = await useCase(NoParams());

      expect(result.isFailure, isTrue);
      expect(result.failure!.message, 'Server error');
    });
  });

  group('GetEggRecordByDate', () {
    late GetEggRecordByDate useCase;

    setUp(() {
      useCase = GetEggRecordByDate(mockRepository);
    });

    test('returns record when found', () async {
      mockRepository.records = [
        _createRecord('1', '2024-01-15', 10, 2),
      ];

      final result = await useCase(
        const GetEggRecordByDateParams(date: '2024-01-15'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.eggsCollected, 10);
    });

    test('returns null when not found', () async {
      mockRepository.records = [
        _createRecord('1', '2024-01-15', 10, 2),
      ];

      final result = await useCase(
        const GetEggRecordByDateParams(date: '2024-01-16'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('returns failure when repository fails', () async {
      mockRepository.failureToReturn = ServerFailure(message: 'Network error');

      final result = await useCase(
        const GetEggRecordByDateParams(date: '2024-01-15'),
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('GetEggRecordsByDateRange', () {
    late GetEggRecordsByDateRange useCase;

    setUp(() {
      useCase = GetEggRecordsByDateRange(mockRepository);
    });

    test('returns records within date range', () async {
      mockRepository.records = [
        _createRecord('1', '2024-01-10', 10, 2),
        _createRecord('2', '2024-01-15', 8, 1),
        _createRecord('3', '2024-01-20', 12, 0),
        _createRecord('4', '2024-01-25', 9, 3),
      ];

      final result = await useCase(
        const DateRangeParams(startDate: '2024-01-12', endDate: '2024-01-22'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 2);
      expect(result.data!.any((r) => r.date == '2024-01-15'), isTrue);
      expect(result.data!.any((r) => r.date == '2024-01-20'), isTrue);
    });

    test('returns empty list when no records in range', () async {
      mockRepository.records = [
        _createRecord('1', '2024-01-10', 10, 2),
      ];

      final result = await useCase(
        const DateRangeParams(startDate: '2024-02-01', endDate: '2024-02-28'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });

    test('includes records on boundary dates', () async {
      mockRepository.records = [
        _createRecord('1', '2024-01-15', 10, 2),
        _createRecord('2', '2024-01-20', 8, 1),
      ];

      final result = await useCase(
        const DateRangeParams(startDate: '2024-01-15', endDate: '2024-01-20'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 2);
    });
  });

  group('CreateEggRecord', () {
    late CreateEggRecord useCase;

    setUp(() {
      useCase = CreateEggRecord(mockRepository);
    });

    test('creates record successfully', () async {
      final record = _createRecord('1', '2024-01-15', 10, 2);

      final result = await useCase(CreateEggRecordParams(record: record));

      expect(result.isSuccess, isTrue);
      expect(mockRepository.createCalled, isTrue);
      expect(mockRepository.records.length, 1);
    });

    test('returns created record data', () async {
      final record = _createRecord('1', '2024-01-15', 10, 2);

      final result = await useCase(CreateEggRecordParams(record: record));

      expect(result.data!.id, '1');
      expect(result.data!.eggsCollected, 10);
    });

    test('returns failure when repository fails', () async {
      mockRepository.failureToReturn = ServerFailure(message: 'Create failed');
      final record = _createRecord('1', '2024-01-15', 10, 2);

      final result = await useCase(CreateEggRecordParams(record: record));

      expect(result.isFailure, isTrue);
      expect(mockRepository.createCalled, isFalse);
    });
  });

  group('UpdateEggRecord', () {
    late UpdateEggRecord useCase;

    setUp(() {
      useCase = UpdateEggRecord(mockRepository);
    });

    test('updates record successfully', () async {
      mockRepository.records = [
        _createRecord('1', '2024-01-15', 10, 2),
      ];
      final updatedRecord = _createRecord('1', '2024-01-15', 15, 3);

      final result = await useCase(
        UpdateEggRecordParams(record: updatedRecord),
      );

      expect(result.isSuccess, isTrue);
      expect(mockRepository.updateCalled, isTrue);
      expect(mockRepository.records[0].eggsCollected, 15);
    });

    test('returns updated record data', () async {
      mockRepository.records = [
        _createRecord('1', '2024-01-15', 10, 2),
      ];
      final updatedRecord = _createRecord('1', '2024-01-15', 20, 5);

      final result = await useCase(
        UpdateEggRecordParams(record: updatedRecord),
      );

      expect(result.data!.eggsCollected, 20);
      expect(result.data!.eggsConsumed, 5);
    });

    test('returns failure when repository fails', () async {
      mockRepository.failureToReturn = ServerFailure(message: 'Update failed');
      final record = _createRecord('1', '2024-01-15', 10, 2);

      final result = await useCase(UpdateEggRecordParams(record: record));

      expect(result.isFailure, isTrue);
    });
  });

  group('DeleteEggRecord', () {
    late DeleteEggRecord useCase;

    setUp(() {
      useCase = DeleteEggRecord(mockRepository);
    });

    test('deletes record successfully', () async {
      mockRepository.records = [
        _createRecord('1', '2024-01-15', 10, 2),
      ];

      final result = await useCase(const DeleteEggRecordParams(id: '1'));

      expect(result.isSuccess, isTrue);
      expect(mockRepository.deleteCalled, isTrue);
      expect(mockRepository.lastDeletedId, '1');
      expect(mockRepository.records, isEmpty);
    });

    test('returns failure when repository fails', () async {
      mockRepository.failureToReturn = ServerFailure(message: 'Delete failed');

      final result = await useCase(const DeleteEggRecordParams(id: '1'));

      expect(result.isFailure, isTrue);
      expect(mockRepository.deleteCalled, isFalse);
    });
  });
}

DailyEggRecord _createRecord(
  String id,
  String date,
  int collected,
  int consumed, {
  String? notes,
  int? henCount,
}) {
  return DailyEggRecord(
    id: id,
    date: date,
    eggsCollected: collected,
    eggsConsumed: consumed,
    notes: notes,
    henCount: henCount,
  );
}
