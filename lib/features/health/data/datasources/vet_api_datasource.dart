import '../../domain/entities/vet_record.dart';
import '../../../../core/api/api_client.dart';
import '../models/vet_record_model.dart';
import 'vet_remote_datasource.dart';

/// API implementation of VetRemoteDataSource
class VetApiDataSourceImpl implements VetRemoteDataSource {
  final ApiClient _apiClient;
  static const _basePath = '/api/v1/health';

  VetApiDataSourceImpl(this._apiClient);

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<VetRecordModel>> getRecords() async {
    final response = await _apiClient.get<Map<String, dynamic>>(_basePath);
    final data = response['data'] as List;
    return data.map((json) => VetRecordModel.fromJson(json)).toList();
  }

  @override
  Future<VetRecordModel> getRecordById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/$id');
    return VetRecordModel.fromJson(response['data']);
  }

  @override
  Future<List<VetRecordModel>> getRecordsByType(VetRecordType type) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'type': type.name},
    );
    final data = response['data'] as List;
    return data.map((json) => VetRecordModel.fromJson(json)).toList();
  }

  @override
  Future<List<VetRecordModel>> getUpcomingAppointments() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'upcoming': 'true', 'from_date': _todayStr()},
    );
    final data = response['data'] as List;
    return data.map((json) => VetRecordModel.fromJson(json)).toList();
  }

  @override
  Future<List<VetRecordModel>> getTodayAppointments() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'next_action_date': _todayStr()},
    );
    final data = response['data'] as List;
    return data.map((json) => VetRecordModel.fromJson(json)).toList();
  }

  @override
  Future<VetRecordModel> createRecord(VetRecordModel record) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: record.toInsertJson(''),
    );
    return VetRecordModel.fromJson(response['data']);
  }

  @override
  Future<VetRecordModel> updateRecord(VetRecordModel record) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/${record.id}',
      data: record.toInsertJson(''),
    );
    return VetRecordModel.fromJson(response['data']);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
