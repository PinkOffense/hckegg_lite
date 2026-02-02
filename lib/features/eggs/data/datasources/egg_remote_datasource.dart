import '../models/daily_egg_record_model.dart';

/// Remote data source interface for egg records
/// Implemented by EggApiDataSourceImpl which uses the backend API
abstract class EggRemoteDataSource {
  Future<List<DailyEggRecordModel>> getRecords();
  Future<DailyEggRecordModel> getRecordById(String id);
  Future<DailyEggRecordModel?> getRecordByDate(String date);
  Future<List<DailyEggRecordModel>> getRecordsByDateRange({
    required String startDate,
    required String endDate,
  });
  Future<DailyEggRecordModel> createRecord(DailyEggRecordModel record);
  Future<DailyEggRecordModel> updateRecord(DailyEggRecordModel record);
  Future<void> deleteRecord(String id);
}
