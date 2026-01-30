import '../../../../core/core.dart';
import '../../domain/entities/daily_egg_record.dart';
import '../../domain/repositories/egg_repository.dart';
import '../datasources/egg_remote_datasource.dart';
import '../models/daily_egg_record_model.dart';

/// Implementation of EggRepository
class EggRepositoryImpl implements EggRepository {
  final EggRemoteDataSource remoteDataSource;

  EggRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<DailyEggRecord>>> getRecords() async {
    try {
      final records = await remoteDataSource.getRecords();
      return Success(records.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<DailyEggRecord>> getRecordById(String id) async {
    try {
      final record = await remoteDataSource.getRecordById(id);
      return Success(record.toEntity());
    } catch (e) {
      return Fail(NotFoundFailure(message: 'Record not found'));
    }
  }

  @override
  Future<Result<DailyEggRecord?>> getRecordByDate(String date) async {
    try {
      final record = await remoteDataSource.getRecordByDate(date);
      return Success(record?.toEntity());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<DailyEggRecord>>> getRecordsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final records = await remoteDataSource.getRecordsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      return Success(records.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<DailyEggRecord>> createRecord(DailyEggRecord record) async {
    try {
      final model = DailyEggRecordModel.fromEntity(record);
      final created = await remoteDataSource.createRecord(model);
      return Success(created.toEntity());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<DailyEggRecord>> updateRecord(DailyEggRecord record) async {
    try {
      final model = DailyEggRecordModel.fromEntity(record);
      final updated = await remoteDataSource.updateRecord(model);
      return Success(updated.toEntity());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteRecord(String id) async {
    try {
      await remoteDataSource.deleteRecord(id);
      return const Success(null);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> getTotalEggsCollected({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final records = await remoteDataSource.getRecordsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      final total = records.fold<int>(0, (sum, r) => sum + r.eggsCollected);
      return Success(total);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }
}
