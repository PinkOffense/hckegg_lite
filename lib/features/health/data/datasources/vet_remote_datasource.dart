import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/vet_record.dart';
import '../models/vet_record_model.dart';

abstract class VetRemoteDataSource {
  Future<List<VetRecordModel>> getRecords();
  Future<VetRecordModel> getRecordById(String id);
  Future<List<VetRecordModel>> getRecordsByType(VetRecordType type);
  Future<List<VetRecordModel>> getUpcomingAppointments();
  Future<List<VetRecordModel>> getTodayAppointments();
  Future<VetRecordModel> createRecord(VetRecordModel record);
  Future<VetRecordModel> updateRecord(VetRecordModel record);
  Future<void> deleteRecord(String id);
}

class VetRemoteDataSourceImpl implements VetRemoteDataSource {
  final SupabaseClient _client;
  static const _tableName = 'vet_records';

  VetRemoteDataSourceImpl(this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user. Please sign in again.');
    }
    return user.id;
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<VetRecordModel>> getRecords() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);
    return (response as List).map((j) => VetRecordModel.fromJson(j)).toList();
  }

  @override
  Future<VetRecordModel> getRecordById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .single();
    return VetRecordModel.fromJson(response);
  }

  @override
  Future<List<VetRecordModel>> getRecordsByType(VetRecordType type) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .eq('type', type.name)
        .order('date', ascending: false);
    return (response as List).map((j) => VetRecordModel.fromJson(j)).toList();
  }

  @override
  Future<List<VetRecordModel>> getUpcomingAppointments() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .not('next_action_date', 'is', null)
        .gte('next_action_date', _todayStr())
        .order('next_action_date', ascending: true);
    return (response as List).map((j) => VetRecordModel.fromJson(j)).toList();
  }

  @override
  Future<List<VetRecordModel>> getTodayAppointments() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .eq('next_action_date', _todayStr());
    return (response as List).map((j) => VetRecordModel.fromJson(j)).toList();
  }

  @override
  Future<VetRecordModel> createRecord(VetRecordModel record) async {
    final response = await _client
        .from(_tableName)
        .insert(record.toInsertJson(_userId))
        .select()
        .single();
    return VetRecordModel.fromJson(response);
  }

  @override
  Future<VetRecordModel> updateRecord(VetRecordModel record) async {
    final response = await _client
        .from(_tableName)
        .update(record.toInsertJson(_userId))
        .eq('id', record.id)
        .eq('user_id', _userId)
        .select()
        .single();
    return VetRecordModel.fromJson(response);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _client.from(_tableName).delete().eq('id', id).eq('user_id', _userId);
  }
}
