import '../../domain/entities/expense.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../models/expense_model.dart';
import 'expense_remote_datasource.dart';

/// API implementation of ExpenseRemoteDataSource
class ExpenseApiDataSourceImpl implements ExpenseRemoteDataSource {
  final ApiClient _apiClient;
  static const _basePath = '/api/v1/expenses';

  ExpenseApiDataSourceImpl(this._apiClient);

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
  Future<List<ExpenseModel>> getExpenses() async {
    final response = await _apiClient.get<Map<String, dynamic>>(_basePath);
    final data = _extractList(response);
    return data.map((json) => ExpenseModel.fromJson(json)).toList();
  }

  @override
  Future<ExpenseModel> getExpenseById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/$id');
    return ExpenseModel.fromJson(_extractMap(response));
  }

  @override
  Future<List<ExpenseModel>> getExpensesByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'start_date': startDate, 'end_date': endDate},
    );
    final data = _extractList(response);
    return data.map((json) => ExpenseModel.fromJson(json)).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByCategory(ExpenseCategory category) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'category': category.name},
    );
    final data = _extractList(response);
    return data.map((json) => ExpenseModel.fromJson(json)).toList();
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: expense.toInsertJson(''),
    );
    return ExpenseModel.fromJson(_extractMap(response));
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/${expense.id}',
      data: expense.toInsertJson(''),
    );
    return ExpenseModel.fromJson(_extractMap(response));
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
