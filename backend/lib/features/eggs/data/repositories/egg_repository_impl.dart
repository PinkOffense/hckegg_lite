import 'package:supabase/supabase.dart';

import '../../../../core/core.dart';
import '../../domain/entities/egg_record.dart';
import '../../domain/repositories/egg_repository.dart';

/// Implementation of EggRepository using Supabase
class EggRepositoryImpl implements EggRepository {
  EggRepositoryImpl(this._client);

  final SupabaseClient _client;
  static const _table = 'daily_egg_records';

  @override
  Future<Result<List<EggRecord>>> getEggRecords(
    String userId, {
    String? farmId,
  }) async {
    try {
      var query = _client.from(_table).select();

      // Filter by farm_id if provided, otherwise by user_id
      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query.order('date', ascending: false);

      final records = (response as List)
          .map((json) => EggRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(records);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggRecord>> getEggRecordById(String id) async {
    try {
      final response =
          await _client.from(_table).select().eq('id', id).single();

      return Result.success(EggRecord.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Result.failure(
          const NotFoundFailure(message: 'Egg record not found'),
        );
      }
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggRecord?>> getEggRecordByDate(
    String userId,
    String date, {
    String? farmId,
  }) async {
    try {
      var query = _client.from(_table).select().eq('date', date);

      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query.maybeSingle();

      if (response == null) {
        return Result.success(null);
      }

      return Result.success(EggRecord.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<EggRecord>>> getEggRecordsInRange(
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

      final records = (response as List)
          .map((json) => EggRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(records);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggRecord>> createEggRecord(EggRecord record) async {
    try {
      final now = DateTime.now().toUtc();
      final data = {
        'user_id': record.userId,
        'farm_id': record.farmId,
        'date': record.date,
        'eggs_collected': record.eggsCollected,
        'eggs_consumed': record.eggsConsumed,
        'notes': record.notes,
        'hen_count': record.henCount,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response =
          await _client.from(_table).insert(data).select().single();

      return Result.success(EggRecord.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return Result.failure(
          const ValidationFailure(
            message: 'A record for this date already exists',
          ),
        );
      }
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggRecord>> updateEggRecord(EggRecord record) async {
    try {
      final data = {
        'eggs_collected': record.eggsCollected,
        'eggs_consumed': record.eggsConsumed,
        'notes': record.notes,
        'hen_count': record.henCount,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', record.id)
          .select()
          .single();

      return Result.success(EggRecord.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Result.failure(
          const NotFoundFailure(message: 'Egg record not found'),
        );
      }
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteEggRecord(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> getTotalEggsCollected(
    String userId, {
    String? farmId,
  }) async {
    try {
      var query = _client.from(_table).select('eggs_collected');

      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query;

      final total = (response as List).fold<int>(
        0,
        (sum, record) => sum + (record['eggs_collected'] as int),
      );

      return Result.success(total);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggStatistics>> getStatistics(
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

      final records = response as List;

      if (records.isEmpty) {
        return Result.success(
          const EggStatistics(
            totalCollected: 0,
            totalConsumed: 0,
            totalRemaining: 0,
            averageDaily: 0,
            recordCount: 0,
          ),
        );
      }

      var totalCollected = 0;
      var totalConsumed = 0;

      for (final record in records) {
        totalCollected += record['eggs_collected'] as int;
        totalConsumed += (record['eggs_consumed'] as int?) ?? 0;
      }

      final totalRemaining = totalCollected - totalConsumed;
      final averageDaily = totalCollected / records.length;

      return Result.success(
        EggStatistics(
          totalCollected: totalCollected,
          totalConsumed: totalConsumed,
          totalRemaining: totalRemaining,
          averageDaily: averageDaily,
          recordCount: records.length,
        ),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
