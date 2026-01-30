import '../../../../core/core.dart';
import '../entities/vet_record.dart';

abstract class VetRepository {
  Future<Result<List<VetRecord>>> getRecords();
  Future<Result<VetRecord>> getRecordById(String id);
  Future<Result<List<VetRecord>>> getRecordsByType(VetRecordType type);
  Future<Result<List<VetRecord>>> getUpcomingAppointments();
  Future<Result<List<VetRecord>>> getTodayAppointments();
  Future<Result<VetRecord>> createRecord(VetRecord record);
  Future<Result<VetRecord>> updateRecord(VetRecord record);
  Future<Result<void>> deleteRecord(String id);
}
