import '../../../../core/core.dart';
import '../entities/vet_record.dart';
import '../repositories/vet_repository.dart';

class GetVetRecords implements UseCase<List<VetRecord>, NoParams> {
  final VetRepository repository;
  GetVetRecords(this.repository);

  @override
  Future<Result<List<VetRecord>>> call(NoParams params) => repository.getRecords();
}

class GetUpcomingAppointments implements UseCase<List<VetRecord>, NoParams> {
  final VetRepository repository;
  GetUpcomingAppointments(this.repository);

  @override
  Future<Result<List<VetRecord>>> call(NoParams params) => repository.getUpcomingAppointments();
}

class GetTodayAppointments implements UseCase<List<VetRecord>, NoParams> {
  final VetRepository repository;
  GetTodayAppointments(this.repository);

  @override
  Future<Result<List<VetRecord>>> call(NoParams params) => repository.getTodayAppointments();
}

class CreateVetRecord implements UseCase<VetRecord, CreateVetRecordParams> {
  final VetRepository repository;
  CreateVetRecord(this.repository);

  @override
  Future<Result<VetRecord>> call(CreateVetRecordParams params) =>
      repository.createRecord(params.record);
}

class CreateVetRecordParams {
  final VetRecord record;
  const CreateVetRecordParams({required this.record});
}

class UpdateVetRecord implements UseCase<VetRecord, UpdateVetRecordParams> {
  final VetRepository repository;
  UpdateVetRecord(this.repository);

  @override
  Future<Result<VetRecord>> call(UpdateVetRecordParams params) =>
      repository.updateRecord(params.record);
}

class UpdateVetRecordParams {
  final VetRecord record;
  const UpdateVetRecordParams({required this.record});
}

class DeleteVetRecord implements UseCase<void, DeleteVetRecordParams> {
  final VetRepository repository;
  DeleteVetRecord(this.repository);

  @override
  Future<Result<void>> call(DeleteVetRecordParams params) =>
      repository.deleteRecord(params.id);
}

class DeleteVetRecordParams {
  final String id;
  const DeleteVetRecordParams({required this.id});
}
