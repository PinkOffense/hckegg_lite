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
  Future<Result<List<EggRecord>>> getEggRecords(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

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
    String date,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .eq('date', date)
          .maybeSingle();

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
    String endDate,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', ascending: false);

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
        'date': record.date,
        'eggs_collected': record.eggsCollected,
        'eggs_broken': record.eggsBroken,
        'eggs_consumed': record.eggsConsumed,
        'notes': record.notes,
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
        'eggs_broken': record.eggsBroken,
        'eggs_consumed': record.eggsConsumed,
        'notes': record.notes,
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
  Future<Result<int>> getTotalEggsCollected(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select('eggs_collected')
          .eq('user_id', userId);

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
    String endDate,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .gte('date', startDate)
          .lte('date', endDate);

      final records = response as List;

      if (records.isEmpty) {
        return Result.success(
          EggStatistics(
            totalCollected: 0,
            totalBroken: 0,
            totalConsumed: 0,
            totalAvailable: 0,
            averageDaily: 0,
            recordCount: 0,
          ),
        );
      }

      var totalCollected = 0;
      var totalBroken = 0;
      var totalConsumed = 0;

      for (final record in records) {
        totalCollected += record['eggs_collected'] as int;
        totalBroken += (record['eggs_broken'] as int?) ?? 0;
        totalConsumed += (record['eggs_consumed'] as int?) ?? 0;
      }

      final totalAvailable = totalCollected - totalBroken - totalConsumed;
      final averageDaily = totalCollected / records.length;

      return Result.success(
        EggStatistics(
          totalCollected: totalCollected,
          totalBroken: totalBroken,
          totalConsumed: totalConsumed,
          totalAvailable: totalAvailable,
          averageDaily: averageDaily,
          recordCount: records.length,
        ),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
