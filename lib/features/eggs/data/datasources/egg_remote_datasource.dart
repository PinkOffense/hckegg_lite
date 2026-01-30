import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_egg_record_model.dart';

/// Remote data source for egg records (Supabase)
abstract class EggRemoteDataSource {
  Future<List<DailyEggRecordModel>> getRecords();
  Future<DailyEggRecordModel> getRecordById(String id);
  Future<DailyEggRecordModel?> getRecordByDate(String date);
  Future<List<DailyEggRecordModel>> getRecordsByDateRange({
    required String startDate,
    required String endDate,
  });
  Future<DailyEggRecordModel> createRecord(DailyEggRecordModel record);
  Future<DailyEggRecordModel> updateRecord(DailyEggRecordModel record);
  Future<void> deleteRecord(String id);
}

/// Implementation of EggRemoteDataSource using Supabase
class EggRemoteDataSourceImpl implements EggRemoteDataSource {
  final SupabaseClient _client;
  static const _tableName = 'daily_egg_records';

  EggRemoteDataSourceImpl(this._client);

  String get _userId => _client.auth.currentUser!.id;

  @override
  Future<List<DailyEggRecordModel>> getRecords() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => DailyEggRecordModel.fromJson(json))
        .toList();
  }

  @override
  Future<DailyEggRecordModel> getRecordById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .single();

    return DailyEggRecordModel.fromJson(response);
  }

  @override
  Future<DailyEggRecordModel?> getRecordByDate(String date) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .eq('date', date)
        .maybeSingle();

    if (response == null) return null;
    return DailyEggRecordModel.fromJson(response);
  }

  @override
  Future<List<DailyEggRecordModel>> getRecordsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => DailyEggRecordModel.fromJson(json))
        .toList();
  }

  @override
  Future<DailyEggRecordModel> createRecord(DailyEggRecordModel record) async {
    final response = await _client
        .from(_tableName)
        .insert(record.toInsertJson(_userId))
        .select()
        .single();

    return DailyEggRecordModel.fromJson(response);
  }

  @override
  Future<DailyEggRecordModel> updateRecord(DailyEggRecordModel record) async {
    final response = await _client
        .from(_tableName)
        .update(record.toUpdateJson())
        .eq('id', record.id)
        .eq('user_id', _userId)
        .select()
        .single();

    return DailyEggRecordModel.fromJson(response);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _client
        .from(_tableName)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
