import '../../../../core/api/api_client.dart';
import '../models/egg_sale_model.dart';
import 'sale_remote_datasource.dart';

/// API implementation of SaleRemoteDataSource
class SaleApiDataSourceImpl implements SaleRemoteDataSource {
  final ApiClient _apiClient;
  static const _basePath = '/api/v1/sales';

  SaleApiDataSourceImpl(this._apiClient);

  @override
  Future<List<EggSaleModel>> getSales() async {
    final response = await _apiClient.get<Map<String, dynamic>>(_basePath);
    final data = response['data'] as List;
    return data.map((json) => EggSaleModel.fromJson(json)).toList();
  }

  @override
  Future<EggSaleModel> getSaleById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/$id');
    return EggSaleModel.fromJson(response['data']);
  }

  @override
  Future<List<EggSaleModel>> getSalesByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'start_date': startDate, 'end_date': endDate},
    );
    final data = response['data'] as List;
    return data.map((json) => EggSaleModel.fromJson(json)).toList();
  }

  @override
  Future<List<EggSaleModel>> getPendingPayments() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'payment_status': 'pending', 'is_lost': 'false'},
    );
    final data = response['data'] as List;
    return data.map((json) => EggSaleModel.fromJson(json)).toList();
  }

  @override
  Future<List<EggSaleModel>> getLostSales() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'is_lost': 'true'},
    );
    final data = response['data'] as List;
    return data.map((json) => EggSaleModel.fromJson(json)).toList();
  }

  @override
  Future<EggSaleModel> createSale(EggSaleModel sale) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: sale.toInsertJson(''),
    );
    return EggSaleModel.fromJson(response['data']);
  }

  @override
  Future<EggSaleModel> updateSale(EggSaleModel sale) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/${sale.id}',
      data: sale.toInsertJson(''),
    );
    return EggSaleModel.fromJson(response['data']);
  }

  @override
  Future<void> deleteSale(String id) async {
    await _apiClient.delete('$_basePath/$id');
  }

  @override
  Future<void> markAsPaid(String id, String paymentDate) async {
    await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/$id',
      data: {'payment_status': 'paid', 'payment_date': paymentDate},
    );
  }

  @override
  Future<void> markAsLost(String id) async {
    await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/$id',
      data: {'is_lost': true},
    );
  }
}
