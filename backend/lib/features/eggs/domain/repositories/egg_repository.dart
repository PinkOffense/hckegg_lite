import '../../../../core/core.dart';
import '../entities/egg_record.dart';

/// Repository interface for egg records
/// Defines the contract for data operations
abstract class EggRepository {
  /// Get all egg records for a user
  Future<Result<List<EggRecord>>> getEggRecords(String userId);

  /// Get egg record by ID
  Future<Result<EggRecord>> getEggRecordById(String id);

  /// Get egg record by date for a user
  Future<Result<EggRecord?>> getEggRecordByDate(String userId, String date);

  /// Get egg records in date range
  Future<Result<List<EggRecord>>> getEggRecordsInRange(
    String userId,
    String startDate,
    String endDate,
  );

  /// Create a new egg record
  Future<Result<EggRecord>> createEggRecord(EggRecord record);

  /// Update an existing egg record
  Future<Result<EggRecord>> updateEggRecord(EggRecord record);

  /// Delete an egg record
  Future<Result<void>> deleteEggRecord(String id);

  /// Get total eggs collected for a user
  Future<Result<int>> getTotalEggsCollected(String userId);

  /// Get statistics for a date range
  Future<Result<EggStatistics>> getStatistics(
    String userId,
    String startDate,
    String endDate,
  );
}

/// Statistics for egg records
class EggStatistics {
  const EggStatistics({
    required this.totalCollected,
    required this.totalBroken,
    required this.totalConsumed,
    required this.totalAvailable,
    required this.averageDaily,
    required this.recordCount,
  });

  final int totalCollected;
  final int totalBroken;
  final int totalConsumed;
  final int totalAvailable;
  final double averageDaily;
  final int recordCount;

  Map<String, dynamic> toJson() => {
        'total_collected': totalCollected,
        'total_broken': totalBroken,
        'total_consumed': totalConsumed,
        'total_available': totalAvailable,
        'average_daily': averageDaily,
        'record_count': recordCount,
      };
}
