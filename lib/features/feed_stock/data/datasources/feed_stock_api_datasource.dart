import '../../../../core/api/api_client.dart';
import '../models/feed_stock_model.dart';
import 'feed_stock_remote_datasource.dart';

/// API implementation of FeedStockRemoteDataSource
class FeedStockApiDataSourceImpl implements FeedStockRemoteDataSource {
  final ApiClient apiClient;
  static const _basePath = '/api/v1/feed_stock';

  FeedStockApiDataSourceImpl({required this.apiClient});

  @override
  Future<List<FeedStockModel>> getFeedStocks() async {
    final response = await apiClient.get<Map<String, dynamic>>(_basePath);
    final data = response['data'] as List;
    return data.map((json) => FeedStockModel.fromJson(json)).toList();
  }

  @override
  Future<FeedStockModel> getFeedStockById(String id) async {
    final response = await apiClient.get<Map<String, dynamic>>('$_basePath/$id');
    return FeedStockModel.fromJson(response['data']);
  }

  @override
  Future<List<FeedStockModel>> getLowStockItems() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'low_stock': 'true'},
    );
    final data = response['data'] as List;
    return data.map((json) => FeedStockModel.fromJson(json)).toList();
  }

  @override
  Future<FeedStockModel> createFeedStock(FeedStockModel stock) async {
    final data = stock.toJson();
    data.remove('id');
    data.remove('created_at');

    final response = await apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: data,
    );
    return FeedStockModel.fromJson(response['data']);
  }

  @override
  Future<FeedStockModel> updateFeedStock(FeedStockModel stock) async {
    final data = stock.toJson();
    data.remove('id');
    data.remove('created_at');
    data.remove('user_id');

    final response = await apiClient.put<Map<String, dynamic>>(
      '$_basePath/${stock.id}',
      data: data,
    );
    return FeedStockModel.fromJson(response['data']);
  }

  @override
  Future<void> deleteFeedStock(String id) async {
    await apiClient.delete('$_basePath/$id');
  }

  @override
  Future<List<FeedMovementModel>> getMovements(String feedStockId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '$_basePath/$feedStockId/movements',
    );
    final data = response['data'] as List;
    return data.map((json) => FeedMovementModel.fromJson(json)).toList();
  }

  @override
  Future<FeedMovementModel> addMovement(FeedMovementModel movement) async {
    final data = movement.toJson();
    data.remove('id');
    data.remove('created_at');

    final response = await apiClient.post<Map<String, dynamic>>(
      '$_basePath/${movement.feedStockId}/movements',
      data: data,
    );
    return FeedMovementModel.fromJson(response['data']);
  }
}
