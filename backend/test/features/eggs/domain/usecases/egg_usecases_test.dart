import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:hckegg_api/core/core.dart';
import 'package:hckegg_api/features/eggs/domain/entities/egg_record.dart';
import 'package:hckegg_api/features/eggs/domain/repositories/egg_repository.dart';
import 'package:hckegg_api/features/eggs/domain/usecases/egg_usecases.dart';

class MockEggRepository extends Mock implements EggRepository {}

void main() {
  late MockEggRepository mockRepository;

  final testRecord = EggRecord(
    id: 'test-id',
    userId: 'user-123',
    date: '2024-01-15',
    eggsCollected: 30,
    eggsBroken: 2,
    eggsConsumed: 4,
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
  );

  setUp(() {
    mockRepository = MockEggRepository();
  });

  group('GetEggRecords', () {
    late GetEggRecords useCase;

    setUp(() {
      useCase = GetEggRecords(mockRepository);
    });

    test('should return list of egg records from repository', () async {
      final records = [testRecord];
      when(() => mockRepository.getEggRecords('user-123'))
          .thenAnswer((_) async => Result.success(records));

      final result = await useCase(const GetEggRecordsParams(userId: 'user-123'));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, records);
      verify(() => mockRepository.getEggRecords('user-123')).called(1);
    });

    test('should return failure when repository fails', () async {
      when(() => mockRepository.getEggRecords('user-123'))
          .thenAnswer((_) async => Result.failure(const ServerFailure(message: 'Error')));

      final result = await useCase(const GetEggRecordsParams(userId: 'user-123'));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, 'Error');
    });
  });

  group('GetEggRecordById', () {
    late GetEggRecordById useCase;

    setUp(() {
      useCase = GetEggRecordById(mockRepository);
    });

    test('should return egg record from repository', () async {
      when(() => mockRepository.getEggRecordById('test-id'))
          .thenAnswer((_) async => Result.success(testRecord));

      final result = await useCase(const GetEggRecordByIdParams(id: 'test-id'));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, testRecord);
    });

    test('should return NotFoundFailure when record not found', () async {
      when(() => mockRepository.getEggRecordById('invalid-id'))
          .thenAnswer((_) async => Result.failure(const NotFoundFailure(message: 'Not found')));

      final result = await useCase(const GetEggRecordByIdParams(id: 'invalid-id'));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('GetEggRecordByDate', () {
    late GetEggRecordByDate useCase;

    setUp(() {
      useCase = GetEggRecordByDate(mockRepository);
    });

    test('should return egg record for date', () async {
      when(() => mockRepository.getEggRecordByDate('user-123', '2024-01-15'))
          .thenAnswer((_) async => Result.success(testRecord));

      final result = await useCase(const GetEggRecordByDateParams(
        userId: 'user-123',
        date: '2024-01-15',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, testRecord);
    });

    test('should return null when no record for date', () async {
      when(() => mockRepository.getEggRecordByDate('user-123', '2024-01-20'))
          .thenAnswer((_) async => const Result.success(null));

      final result = await useCase(const GetEggRecordByDateParams(
        userId: 'user-123',
        date: '2024-01-20',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });

  group('CreateEggRecord', () {
    late CreateEggRecord useCase;

    setUp(() {
      useCase = CreateEggRecord(mockRepository);
    });

    test('should create egg record successfully', () async {
      when(() => mockRepository.createEggRecord(testRecord))
          .thenAnswer((_) async => Result.success(testRecord));

      final result = await useCase(CreateEggRecordParams(record: testRecord));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, testRecord);
      verify(() => mockRepository.createEggRecord(testRecord)).called(1);
    });

    test('should return ValidationFailure for duplicate date', () async {
      when(() => mockRepository.createEggRecord(testRecord))
          .thenAnswer((_) async => Result.failure(
                const ValidationFailure(message: 'Record for this date already exists'),
              ));

      final result = await useCase(CreateEggRecordParams(record: testRecord));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('UpdateEggRecord', () {
    late UpdateEggRecord useCase;

    setUp(() {
      useCase = UpdateEggRecord(mockRepository);
    });

    test('should update egg record successfully', () async {
      final updatedRecord = testRecord.copyWith(eggsCollected: 50);
      when(() => mockRepository.updateEggRecord(updatedRecord))
          .thenAnswer((_) async => Result.success(updatedRecord));

      final result = await useCase(UpdateEggRecordParams(record: updatedRecord));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.eggsCollected, 50);
    });

    test('should return NotFoundFailure when record not found', () async {
      when(() => mockRepository.updateEggRecord(testRecord))
          .thenAnswer((_) async => Result.failure(const NotFoundFailure(message: 'Not found')));

      final result = await useCase(UpdateEggRecordParams(record: testRecord));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('DeleteEggRecord', () {
    late DeleteEggRecord useCase;

    setUp(() {
      useCase = DeleteEggRecord(mockRepository);
    });

    test('should delete egg record successfully', () async {
      when(() => mockRepository.deleteEggRecord('test-id'))
          .thenAnswer((_) async => const Result.success(null));

      final result = await useCase(const DeleteEggRecordParams(id: 'test-id'));

      expect(result.isSuccess, isTrue);
      verify(() => mockRepository.deleteEggRecord('test-id')).called(1);
    });
  });

  group('GetEggStatistics', () {
    late GetEggStatistics useCase;

    setUp(() {
      useCase = GetEggStatistics(mockRepository);
    });

    test('should return statistics for date range', () async {
      const stats = EggStatistics(
        totalCollected: 100,
        totalBroken: 5,
        totalConsumed: 10,
        totalAvailable: 85,
        averageDaily: 14.28,
        recordCount: 7,
      );

      when(() => mockRepository.getStatistics('user-123', '2024-01-01', '2024-01-07'))
          .thenAnswer((_) async => Result.success(stats));

      final result = await useCase(const GetEggStatisticsParams(
        userId: 'user-123',
        startDate: '2024-01-01',
        endDate: '2024-01-07',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.totalCollected, 100);
      expect(result.valueOrNull?.recordCount, 7);
    });
  });
}
