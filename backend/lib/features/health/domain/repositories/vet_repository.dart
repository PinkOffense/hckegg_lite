import '../../../../core/core.dart';
import '../entities/vet_record.dart';

abstract class VetRepository {
  Future<Result<List<VetRecord>>> getVetRecords(String userId);
  Future<Result<VetRecord>> getVetRecordById(String id);
  Future<Result<List<VetRecord>>> getVetRecordsInRange(
    String userId,
    String startDate,
    String endDate,
  );
  Future<Result<List<VetRecord>>> getVetRecordsByType(
    String userId,
    VetRecordType type,
  );
  Future<Result<List<VetRecord>>> getUpcomingAppointments(String userId);
  Future<Result<VetRecord>> createVetRecord(VetRecord vetRecord);
  Future<Result<VetRecord>> updateVetRecord(VetRecord vetRecord);
  Future<Result<void>> deleteVetRecord(String id);
  Future<Result<VetStatistics>> getStatistics(
    String userId,
    String startDate,
    String endDate,
  );
}

class VetStatistics {
  const VetStatistics({
    required this.totalRecords,
    required this.totalCost,
    required this.totalHensAffected,
    required this.byType,
  });

  final int totalRecords;
  final double totalCost;
  final int totalHensAffected;
  final Map<String, VetTypeStats> byType;

  Map<String, dynamic> toJson() => {
        'total_records': totalRecords,
        'total_cost': totalCost,
        'total_hens_affected': totalHensAffected,
        'by_type': byType.map((k, v) => MapEntry(k, v.toJson())),
      };
}

class VetTypeStats {
  const VetTypeStats({
    required this.count,
    required this.cost,
    required this.hensAffected,
  });

  final int count;
  final double cost;
  final int hensAffected;

  Map<String, dynamic> toJson() => {
        'count': count,
        'cost': cost,
        'hens_affected': hensAffected,
      };
}
