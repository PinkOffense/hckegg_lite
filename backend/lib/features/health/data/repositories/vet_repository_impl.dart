import 'package:supabase/supabase.dart';
import '../../../../core/core.dart';
import '../../domain/entities/vet_record.dart';
import '../../domain/repositories/vet_repository.dart';

class VetRepositoryImpl implements VetRepository {
  VetRepositoryImpl(this._client);
  final SupabaseClient _client;
  static const _table = 'vet_records';

  @override
  Future<Result<List<VetRecord>>> getVetRecords(String userId) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).order('date', ascending: false);
      return Result.success((response as List).map((j) => VetRecord.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<VetRecord>> getVetRecordById(String id) async {
    try {
      final response = await _client.from(_table).select().eq('id', id).single();
      return Result.success(VetRecord.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return Result.failure(const NotFoundFailure(message: 'Vet record not found'));
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<VetRecord>>> getVetRecordsInRange(String userId, String startDate, String endDate) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).gte('date', startDate).lte('date', endDate).order('date', ascending: false);
      return Result.success((response as List).map((j) => VetRecord.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<VetRecord>>> getVetRecordsByType(String userId, VetRecordType recordType) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).eq('record_type', recordType.name);
      return Result.success((response as List).map((j) => VetRecord.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<VetRecord>> createVetRecord(VetRecord vetRecord) async {
    try {
      final data = {
        'user_id': vetRecord.userId,
        'date': vetRecord.date,
        'record_type': vetRecord.recordType.name,
        'hens_affected': vetRecord.hensAffected,
        'description': vetRecord.description,
        'vet_name': vetRecord.vetName,
        'cost': vetRecord.cost,
        'notes': vetRecord.notes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      final response = await _client.from(_table).insert(data).select().single();
      return Result.success(VetRecord.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<VetRecord>> updateVetRecord(VetRecord vetRecord) async {
    try {
      final data = {
        'date': vetRecord.date,
        'record_type': vetRecord.recordType.name,
        'hens_affected': vetRecord.hensAffected,
        'description': vetRecord.description,
        'vet_name': vetRecord.vetName,
        'cost': vetRecord.cost,
        'notes': vetRecord.notes,
      };
      final response = await _client.from(_table).update(data).eq('id', vetRecord.id).select().single();
      return Result.success(VetRecord.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteVetRecord(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<VetStatistics>> getStatistics(String userId, String startDate, String endDate) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).gte('date', startDate).lte('date', endDate);
      final vetRecords = (response as List).map((j) => VetRecord.fromJson(j as Map<String, dynamic>)).toList();

      final byRecordType = <String, VetTypeStats>{};
      var totalCost = 0.0;
      var totalHensAffected = 0;
      for (final v in vetRecords) {
        totalCost += v.cost;
        totalHensAffected += v.hensAffected;
        final existing = byRecordType[v.recordType.name];
        byRecordType[v.recordType.name] = VetTypeStats(
          count: (existing?.count ?? 0) + 1,
          cost: (existing?.cost ?? 0) + v.cost,
          hensAffected: (existing?.hensAffected ?? 0) + v.hensAffected,
        );
      }

      return Result.success(VetStatistics(
        totalRecords: vetRecords.length,
        totalCost: totalCost,
        totalHensAffected: totalHensAffected,
        byRecordType: byRecordType,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
