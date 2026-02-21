import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/context/farm_context.dart';
import '../models/daily_egg_record_model.dart';
import 'egg_remote_datasource.dart';

/// Supabase implementation of EggRemoteDataSource
/// Uses Supabase directly instead of the API backend
class EggSupabaseDataSourceImpl implements EggRemoteDataSource {
  final SupabaseClient _client;
  static const _tableName = 'daily_egg_records';

  EggSupabaseDataSourceImpl(this._client);

  String? get _farmId => FarmContext().farmId;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.id;
  }

  @override
  Future<List<DailyEggRecordModel>> getRecords() async {
    var query = _client.from(_tableName).select();

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query.order('date', ascending: false);

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
        .single();

    return DailyEggRecordModel.fromJson(response);
  }

  @override
  Future<DailyEggRecordModel?> getRecordByDate(String date) async {
    var query = _client.from(_tableName).select().eq('date', date);

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query.maybeSingle();

    if (response == null) return null;
    return DailyEggRecordModel.fromJson(response);
  }

  @override
  Future<List<DailyEggRecordModel>> getRecordsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    var query = _client
        .from(_tableName)
        .select()
        .gte('date', startDate)
        .lte('date', endDate);

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query.order('date', ascending: false);

    return (response as List)
        .map((json) => DailyEggRecordModel.fromJson(json))
        .toList();
  }

  @override
  Future<DailyEggRecordModel> createRecord(DailyEggRecordModel record) async {
    final data = record.toInsertJson(_userId);
    if (_farmId != null) {
      data['farm_id'] = _farmId;
    }

    final response = await _client
        .from(_tableName)
        .insert(data)
        .select()
        .single();

    return DailyEggRecordModel.fromJson(response);
  }

  @override
  Future<DailyEggRecordModel> updateRecord(DailyEggRecordModel record) async {
    final data = record.toUpdateJson();
    if (_farmId != null) {
      data['farm_id'] = _farmId;
    }

    final response = await _client
        .from(_tableName)
        .update(data)
        .eq('id', record.id)
        .select()
        .single();

    return DailyEggRecordModel.fromJson(response);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }
}
