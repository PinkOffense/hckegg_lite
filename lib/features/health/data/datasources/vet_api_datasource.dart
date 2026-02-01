import '../../domain/entities/vet_record.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/date_utils.dart';
import '../../../../core/errors/failures.dart';
import '../models/vet_record_model.dart';
import 'vet_remote_datasource.dart';

/// API implementation of VetRemoteDataSource
class VetApiDataSourceImpl implements VetRemoteDataSource {
  final ApiClient _apiClient;
  static const _basePath = '/api/v1/health';

  VetApiDataSourceImpl(this._apiClient);

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data == null) {
      throw const ServerFailure(message: 'Invalid response: missing data', code: 'INVALID_RESPONSE');
    }
    return data as List;
  }

  Map<String, dynamic> _extractMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data == null) {
      throw const ServerFailure(message: 'Invalid response: missing data', code: 'INVALID_RESPONSE');
    }
    return data as Map<String, dynamic>;
  }

  @override
  Future<List<VetRecordModel>> getRecords() async {
    final response = await _apiClient.get<Map<String, dynamic>>(_basePath);
    final data = _extractList(response);
    return data.map((json) => VetRecordModel.fromJson(json)).toList();
  }

  @override
  Future<VetRecordModel> getRecordById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/$id');
    return VetRecordModel.fromJson(_extractMap(response));
  }

  @override
  Future<List<VetRecordModel>> getRecordsByType(VetRecordType type) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'type': type.name},
    );
    final data = _extractList(response);
    return data.map((json) => VetRecordModel.fromJson(json)).toList();
  }

  @override
  Future<List<VetRecordModel>> getUpcomingAppointments() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'upcoming': 'true', 'from_date': AppDateUtils.todayString()},
    );
    final data = _extractList(response);
    return data.map((json) => VetRecordModel.fromJson(json)).toList();
  }

  @override
  Future<List<VetRecordModel>> getTodayAppointments() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'next_action_date': AppDateUtils.todayString()},
    );
    final data = _extractList(response);
    return data.map((json) => VetRecordModel.fromJson(json)).toList();
  }

  @override
  Future<VetRecordModel> createRecord(VetRecordModel record) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: record.toInsertJson(''),
    );
    return VetRecordModel.fromJson(_extractMap(response));
  }

  @override
  Future<VetRecordModel> updateRecord(VetRecordModel record) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/${record.id}',
      data: record.toInsertJson(''),
    );
    return VetRecordModel.fromJson(_extractMap(response));
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
