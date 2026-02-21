import '../../../../core/core.dart';
import '../entities/egg_record.dart';
import '../repositories/egg_repository.dart';

/// Get all egg records for a user or farm
class GetEggRecords implements UseCase<List<EggRecord>, GetEggRecordsParams> {
  GetEggRecords(this.repository);

  final EggRepository repository;

  @override
  Future<Result<List<EggRecord>>> call(GetEggRecordsParams params) {
    return repository.getEggRecords(params.userId, farmId: params.farmId);
  }
}

class GetEggRecordsParams {
  const GetEggRecordsParams({required this.userId, this.farmId});
  final String userId;
  final String? farmId;
}

/// Get egg record by ID
class GetEggRecordById implements UseCase<EggRecord, GetEggRecordByIdParams> {
  GetEggRecordById(this.repository);

  final EggRepository repository;

  @override
  Future<Result<EggRecord>> call(GetEggRecordByIdParams params) {
    return repository.getEggRecordById(params.id);
  }
}

class GetEggRecordByIdParams {
  const GetEggRecordByIdParams({required this.id});
  final String id;
}

/// Get egg record by date
class GetEggRecordByDate
    implements UseCase<EggRecord?, GetEggRecordByDateParams> {
  GetEggRecordByDate(this.repository);

  final EggRepository repository;

  @override
  Future<Result<EggRecord?>> call(GetEggRecordByDateParams params) {
    return repository.getEggRecordByDate(params.userId, params.date, farmId: params.farmId);
  }
}

class GetEggRecordByDateParams {
  const GetEggRecordByDateParams({required this.userId, required this.date, this.farmId});
  final String userId;
  final String date;
  final String? farmId;
}

/// Get egg records in date range
class GetEggRecordsInRange
    implements UseCase<List<EggRecord>, GetEggRecordsInRangeParams> {
  GetEggRecordsInRange(this.repository);

  final EggRepository repository;

  @override
  Future<Result<List<EggRecord>>> call(GetEggRecordsInRangeParams params) {
    return repository.getEggRecordsInRange(
      params.userId,
      params.startDate,
      params.endDate,
      farmId: params.farmId,
    );
  }
}

class GetEggRecordsInRangeParams {
  const GetEggRecordsInRangeParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
    this.farmId,
  });

  final String userId;
  final String startDate;
  final String endDate;
  final String? farmId;
}

/// Create a new egg record
class CreateEggRecord implements UseCase<EggRecord, CreateEggRecordParams> {
  CreateEggRecord(this.repository);

  final EggRepository repository;

  @override
  Future<Result<EggRecord>> call(CreateEggRecordParams params) {
    return repository.createEggRecord(params.record);
  }
}

class CreateEggRecordParams {
  const CreateEggRecordParams({required this.record});
  final EggRecord record;
}

/// Update an egg record
class UpdateEggRecord implements UseCase<EggRecord, UpdateEggRecordParams> {
  UpdateEggRecord(this.repository);

  final EggRepository repository;

  @override
  Future<Result<EggRecord>> call(UpdateEggRecordParams params) {
    return repository.updateEggRecord(params.record);
  }
}

class UpdateEggRecordParams {
  const UpdateEggRecordParams({required this.record});
  final EggRecord record;
}

/// Delete an egg record
class DeleteEggRecord implements UseCase<void, DeleteEggRecordParams> {
  DeleteEggRecord(this.repository);

  final EggRepository repository;

  @override
  Future<Result<void>> call(DeleteEggRecordParams params) {
    return repository.deleteEggRecord(params.id);
  }
}

class DeleteEggRecordParams {
  const DeleteEggRecordParams({required this.id});
  final String id;
}

/// Get egg statistics
class GetEggStatistics
    implements UseCase<EggStatistics, GetEggStatisticsParams> {
  GetEggStatistics(this.repository);

  final EggRepository repository;

  @override
  Future<Result<EggStatistics>> call(GetEggStatisticsParams params) {
    return repository.getStatistics(
      params.userId,
      params.startDate,
      params.endDate,
      farmId: params.farmId,
    );
  }
}

class GetEggStatisticsParams {
  const GetEggStatisticsParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
    this.farmId,
  });

  final String userId;
  final String startDate;
  final String endDate;
  final String? farmId;
}
