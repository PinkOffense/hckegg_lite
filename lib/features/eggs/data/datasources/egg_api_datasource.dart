import '../../../../core/api/api_client.dart';
import '../models/daily_egg_record_model.dart';
import 'egg_remote_datasource.dart';

/// API implementation of EggRemoteDataSource
class EggApiDataSourceImpl implements EggRemoteDataSource {
  final ApiClient _apiClient;
  static const _basePath = '/api/v1/eggs';

  EggApiDataSourceImpl(this._apiClient);

  @override
  Future<List<DailyEggRecordModel>> getRecords() async {
    final response = await _apiClient.get<Map<String, dynamic>>(_basePath);
    final data = response['data'] as List;
    return data.map((json) => DailyEggRecordModel.fromJson(json)).toList();
  }

  @override
  Future<DailyEggRecordModel> getRecordById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/$id');
    return DailyEggRecordModel.fromJson(response['data']);
  }

  @override
  Future<DailyEggRecordModel?> getRecordByDate(String date) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'start_date': date, 'end_date': date},
    );
    final data = response['data'] as List;
    if (data.isEmpty) return null;
    return DailyEggRecordModel.fromJson(data.first);
  }

  @override
  Future<List<DailyEggRecordModel>> getRecordsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'start_date': startDate, 'end_date': endDate},
    );
    final data = response['data'] as List;
    return data.map((json) => DailyEggRecordModel.fromJson(json)).toList();
  }

  @override
  Future<DailyEggRecordModel> createRecord(DailyEggRecordModel record) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: record.toInsertJson(''), // API handles user_id from token
    );
    return DailyEggRecordModel.fromJson(response['data']);
  }

  @override
  Future<DailyEggRecordModel> updateRecord(DailyEggRecordModel record) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/${record.id}',
      data: record.toUpdateJson(),
    );
    return DailyEggRecordModel.fromJson(response['data']);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
