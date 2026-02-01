import '../../../../core/core.dart';
import '../entities/daily_egg_record.dart';
import '../repositories/egg_repository.dart';

/// Use case to get all egg records
class GetEggRecords implements UseCase<List<DailyEggRecord>, NoParams> {
  final EggRepository repository;

  GetEggRecords(this.repository);

  @override
  Future<Result<List<DailyEggRecord>>> call(NoParams params) {
    return repository.getRecords();
  }
}
