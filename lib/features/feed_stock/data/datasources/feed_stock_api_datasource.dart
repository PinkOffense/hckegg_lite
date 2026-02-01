import '../../../../core/api/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../models/feed_stock_model.dart';
import 'feed_stock_remote_datasource.dart';

/// API implementation of FeedStockRemoteDataSource
class FeedStockApiDataSourceImpl implements FeedStockRemoteDataSource {
  final ApiClient _apiClient;
  static const _basePath = '/api/v1/feed_stock';

  FeedStockApiDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

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
  Future<List<FeedStockModel>> getFeedStocks() async {
    final response = await _apiClient.get<Map<String, dynamic>>(_basePath);
    final data = _extractList(response);
    return data.map((json) => FeedStockModel.fromJson(json)).toList();
  }

  @override
  Future<FeedStockModel> getFeedStockById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/$id');
    return FeedStockModel.fromJson(_extractMap(response));
  }

  @override
  Future<List<FeedStockModel>> getLowStockItems() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'low_stock': 'true'},
    );
    final data = _extractList(response);
    return data.map((json) => FeedStockModel.fromJson(json)).toList();
  }

  @override
  Future<FeedStockModel> createFeedStock(FeedStockModel stock) async {
    final data = stock.toJson();
    data.remove('id');
    data.remove('created_at');

    final response = await _apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: data,
    );
    return FeedStockModel.fromJson(_extractMap(response));
  }

  @override
  Future<FeedStockModel> updateFeedStock(FeedStockModel stock) async {
    final data = stock.toJson();
    data.remove('id');
    data.remove('created_at');
    data.remove('user_id');

    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/${stock.id}',
      data: data,
    );
    return FeedStockModel.fromJson(_extractMap(response));
  }

  @override
  Future<void> deleteFeedStock(String id) async {
    await _apiClient.delete('$_basePath/$id');
  }

  @override
  Future<List<FeedMovementModel>> getMovements(String feedStockId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/$feedStockId/movements',
    );
    final data = _extractList(response);
    return data.map((json) => FeedMovementModel.fromJson(json)).toList();
  }

  @override
  Future<FeedMovementModel> addMovement(FeedMovementModel movement) async {
    final data = movement.toJson();
    data.remove('id');
    data.remove('created_at');

    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/${movement.feedStockId}/movements',
      data: data,
    );
    return FeedMovementModel.fromJson(_extractMap(response));
  }
}
