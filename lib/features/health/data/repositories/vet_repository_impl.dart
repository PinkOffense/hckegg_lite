import '../../../../core/core.dart';
import '../../domain/entities/vet_record.dart';
import '../../domain/repositories/vet_repository.dart';
import '../datasources/vet_remote_datasource.dart';
import '../models/vet_record_model.dart';

class VetRepositoryImpl implements VetRepository {
  final VetRemoteDataSource remoteDataSource;

  VetRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<VetRecord>>> getRecords() async {
    try {
      final records = await remoteDataSource.getRecords();
      return Success(records.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<VetRecord>> getRecordById(String id) async {
    try {
      final record = await remoteDataSource.getRecordById(id);
      return Success(record.toEntity());
    } catch (e) {
      return Fail(NotFoundFailure(message: 'Record not found'));
    }
  }

  @override
  Future<Result<List<VetRecord>>> getRecordsByType(VetRecordType type) async {
    try {
      final records = await remoteDataSource.getRecordsByType(type);
      return Success(records.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<VetRecord>>> getUpcomingAppointments() async {
    try {
      final records = await remoteDataSource.getUpcomingAppointments();
      return Success(records.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<VetRecord>>> getTodayAppointments() async {
    try {
      final records = await remoteDataSource.getTodayAppointments();
      return Success(records.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<VetRecord>> createRecord(VetRecord record) async {
    try {
      final model = VetRecordModel.fromEntity(record);
      final created = await remoteDataSource.createRecord(model);
      return Success(created.toEntity());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<VetRecord>> updateRecord(VetRecord record) async {
    try {
      final model = VetRecordModel.fromEntity(record);
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
}
