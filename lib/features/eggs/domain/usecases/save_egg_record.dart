import '../../../../core/core.dart';
import '../entities/daily_egg_record.dart';
import '../repositories/egg_repository.dart';

/// Use case to create a new egg record
class CreateEggRecord implements UseCase<DailyEggRecord, CreateEggRecordParams> {
  final EggRepository repository;

  CreateEggRecord(this.repository);

  @override
  Future<Result<DailyEggRecord>> call(CreateEggRecordParams params) {
    return repository.createRecord(params.record);
  }
}

class CreateEggRecordParams {
  final DailyEggRecord record;

  const CreateEggRecordParams({required this.record});
}

/// Use case to update an existing egg record
class UpdateEggRecord implements UseCase<DailyEggRecord, UpdateEggRecordParams> {
  final EggRepository repository;

  UpdateEggRecord(this.repository);

  @override
  Future<Result<DailyEggRecord>> call(UpdateEggRecordParams params) {
    return repository.updateRecord(params.record);
  }
}

class UpdateEggRecordParams {
  final DailyEggRecord record;

  const UpdateEggRecordParams({required this.record});
}

/// Use case to delete an egg record
class DeleteEggRecord implements UseCase<void, DeleteEggRecordParams> {
  final EggRepository repository;

  DeleteEggRecord(this.repository);

  @override
  Future<Result<void>> call(DeleteEggRecordParams params) {
    return repository.deleteRecord(params.id);
  }
}

class DeleteEggRecordParams {
  final String id;

  const DeleteEggRecordParams({required this.id});
}
