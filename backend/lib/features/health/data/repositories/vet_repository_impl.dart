import 'package:supabase/supabase.dart';
import '../../../../core/core.dart';
import '../../domain/entities/vet_record.dart';
import '../../domain/repositories/vet_repository.dart';

class VetRepositoryImpl implements VetRepository {
  VetRepositoryImpl(this._client);
  final SupabaseClient _client;
  static const _table = 'vet_records';

  @override
  Future<Result<List<VetRecord>>> getVetRecords(String userId, {String? farmId}) async {
    try {
      var query = _client.from(_table).select();

      // Filter by farm_id if provided, otherwise by user_id
      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query.order('date', ascending: false);
      return Result.success(
        (response as List)
            .map((j) => VetRecord.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<VetRecord>> getVetRecordById(String id) async {
    try {
      final response =
          await _client.from(_table).select().eq('id', id).single();
      return Result.success(VetRecord.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Result.failure(
          const NotFoundFailure(message: 'Vet record not found'),
        );
      }
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<VetRecord>>> getVetRecordsInRange(
    String userId,
    String startDate,
    String endDate, {
    String? farmId,
  }) async {
    try {
      var query = _client
          .from(_table)
          .select()
          .gte('date', startDate)
          .lte('date', endDate);

      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query.order('date', ascending: false);
      return Result.success(
        (response as List)
            .map((j) => VetRecord.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<VetRecord>>> getVetRecordsByType(
    String userId,
    VetRecordType type, {
    String? farmId,
  }) async {
    try {
      var query = _client.from(_table).select().eq('type', type.name);

      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query;
      return Result.success(
        (response as List)
            .map((j) => VetRecord.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<VetRecord>>> getUpcomingAppointments(String userId, {String? farmId}) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      var query = _client
          .from(_table)
          .select()
          .gte('next_action_date', today);

      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query.order('next_action_date', ascending: true);
      return Result.success(
        (response as List)
            .map((j) => VetRecord.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<VetRecord>> createVetRecord(VetRecord vetRecord) async {
    try {
      final now = DateTime.now().toUtc();
      final data = {
        'user_id': vetRecord.userId,
        'farm_id': vetRecord.farmId,
        'date': vetRecord.date,
        'type': vetRecord.type.name,
        'hens_affected': vetRecord.hensAffected,
        'description': vetRecord.description,
        'medication': vetRecord.medication,
        'cost': vetRecord.cost,
        'next_action_date': vetRecord.nextActionDate,
        'notes': vetRecord.notes,
        'severity': vetRecord.severity.name,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final response =
          await _client.from(_table).insert(data).select().single();
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
        'type': vetRecord.type.name,
        'hens_affected': vetRecord.hensAffected,
        'description': vetRecord.description,
        'medication': vetRecord.medication,
        'cost': vetRecord.cost,
        'next_action_date': vetRecord.nextActionDate,
        'notes': vetRecord.notes,
        'severity': vetRecord.severity.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', vetRecord.id)
          .select()
          .single();
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
  Future<Result<VetStatistics>> getStatistics(
    String userId,
    String startDate,
    String endDate, {
    String? farmId,
  }) async {
    try {
      var query = _client
          .from(_table)
          .select()
          .gte('date', startDate)
          .lte('date', endDate);

      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query;
      final vetRecords = (response as List)
          .map((j) => VetRecord.fromJson(j as Map<String, dynamic>))
          .toList();

      final byType = <String, VetTypeStats>{};
      var totalCost = 0.0;
      var totalHensAffected = 0;
      for (final v in vetRecords) {
        totalCost += v.cost ?? 0;
        totalHensAffected += v.hensAffected;
        final existing = byType[v.type.name];
        byType[v.type.name] = VetTypeStats(
          count: (existing?.count ?? 0) + 1,
          cost: (existing?.cost ?? 0) + (v.cost ?? 0),
          hensAffected: (existing?.hensAffected ?? 0) + v.hensAffected,
        );
      }

      return Result.success(
        VetStatistics(
          totalRecords: vetRecords.length,
          totalCost: totalCost,
          totalHensAffected: totalHensAffected,
          byType: byType,
        ),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
