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

/// Use case to get egg record by date
class GetEggRecordByDate implements UseCase<DailyEggRecord?, GetEggRecordByDateParams> {
  final EggRepository repository;

  GetEggRecordByDate(this.repository);

  @override
  Future<Result<DailyEggRecord?>> call(GetEggRecordByDateParams params) {
    return repository.getRecordByDate(params.date);
  }
}

class GetEggRecordByDateParams {
  final String date;

  const GetEggRecordByDateParams({required this.date});
}

/// Use case to get egg records by date range
class GetEggRecordsByDateRange implements UseCase<List<DailyEggRecord>, DateRangeParams> {
  final EggRepository repository;

  GetEggRecordsByDateRange(this.repository);

  @override
  Future<Result<List<DailyEggRecord>>> call(DateRangeParams params) {
    return repository.getRecordsByDateRange(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class DateRangeParams {
  final String startDate;
  final String endDate;

  const DateRangeParams({
    required this.startDate,
    required this.endDate,
  });
}
