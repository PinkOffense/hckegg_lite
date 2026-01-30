import '../../../../core/core.dart';
import '../entities/daily_egg_record.dart';

/// Repository interface for egg records
/// This defines the contract that the data layer must implement
abstract class EggRepository {
  /// Get all egg records for the current user
  Future<Result<List<DailyEggRecord>>> getRecords();

  /// Get a single record by ID
  Future<Result<DailyEggRecord>> getRecordById(String id);

  /// Get record for a specific date
  Future<Result<DailyEggRecord?>> getRecordByDate(String date);

  /// Get records for a date range
  Future<Result<List<DailyEggRecord>>> getRecordsByDateRange({
    required String startDate,
    required String endDate,
  });

  /// Create a new egg record
  Future<Result<DailyEggRecord>> createRecord(DailyEggRecord record);

  /// Update an existing egg record
  Future<Result<DailyEggRecord>> updateRecord(DailyEggRecord record);

  /// Delete an egg record by ID
  Future<Result<void>> deleteRecord(String id);

  /// Get total eggs collected in a date range
  Future<Result<int>> getTotalEggsCollected({
    required String startDate,
    required String endDate,
  });
}
