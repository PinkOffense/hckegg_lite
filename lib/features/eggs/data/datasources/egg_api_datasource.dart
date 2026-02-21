import '../../../../core/api/api_client.dart';
import '../../../../core/context/farm_context.dart';
import '../../../../core/errors/failures.dart';
import '../models/daily_egg_record_model.dart';
import 'egg_remote_datasource.dart';

/// API implementation of EggRemoteDataSource
class EggApiDataSourceImpl implements EggRemoteDataSource {
  final ApiClient _apiClient;
  static const _basePath = '/api/v1/eggs';

  EggApiDataSourceImpl(this._apiClient);

  String? get _farmId => FarmContext().farmId;

  Map<String, String> get _farmIdParam => _farmId != null ? {'farm_id': _farmId!} : {};

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data == null || data is! List) {
      throw const ServerFailure(message: 'Invalid response: expected data array', code: 'INVALID_RESPONSE');
    }
    return data;
  }

  Map<String, dynamic> _extractMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data == null || data is! Map<String, dynamic>) {
      throw const ServerFailure(message: 'Invalid response: expected data object', code: 'INVALID_RESPONSE');
    }
    return data;
  }

  @override
  Future<List<DailyEggRecordModel>> getRecords() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: _farmIdParam,
    );
    final data = _extractList(response);
    return data.map((json) => DailyEggRecordModel.fromJson(json)).toList();
  }

  @override
  Future<DailyEggRecordModel> getRecordById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/$id');
    return DailyEggRecordModel.fromJson(_extractMap(response));
  }

  @override
  Future<DailyEggRecordModel?> getRecordByDate(String date) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'start_date': date, 'end_date': date, ..._farmIdParam},
    );
    final data = _extractList(response);
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
      queryParameters: {'start_date': startDate, 'end_date': endDate, ..._farmIdParam},
    );
    final data = _extractList(response);
    return data.map((json) => DailyEggRecordModel.fromJson(json)).toList();
  }

  @override
  Future<DailyEggRecordModel> createRecord(DailyEggRecordModel record) async {
    final data = record.toInsertJson(''); // API handles user_id from token
    if (_farmId != null) {
      data['farm_id'] = _farmId;
    }
    final response = await _apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: data,
    );
    return DailyEggRecordModel.fromJson(_extractMap(response));
  }

  @override
  Future<DailyEggRecordModel> updateRecord(DailyEggRecordModel record) async {
    final data = record.toUpdateJson();
    if (_farmId != null) {
      data['farm_id'] = _farmId;
    }
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/${record.id}',
      data: data,
    );
    return DailyEggRecordModel.fromJson(_extractMap(response));
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
