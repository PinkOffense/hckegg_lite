import '../../../../core/api/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/analytics_data.dart';

/// API datasource for analytics
class AnalyticsApiDataSource {
  final ApiClient _apiClient;
  static const _basePath = '/api/v1/analytics';

  AnalyticsApiDataSource(this._apiClient);

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data == null) {
      throw const ServerFailure(message: 'Invalid response: missing data');
    }
    return data as Map<String, dynamic>;
  }

  /// Get complete dashboard analytics
  Future<DashboardAnalytics> getDashboardAnalytics() async {
    final response = await _apiClient.get<Map<String, dynamic>>(_basePath);
    return DashboardAnalytics.fromJson(_extractData(response));
  }

  /// Get week statistics
  Future<WeekStats> getWeekStats() async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/week-stats');
    return WeekStats.fromJson(_extractData(response));
  }

  /// Get production analytics
  Future<ProductionSummary> getProductionAnalytics() async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/production');
    return ProductionSummary.fromJson(_extractData(response));
  }

  /// Get sales analytics
  Future<SalesSummary> getSalesAnalytics() async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/sales');
    return SalesSummary.fromJson(_extractData(response));
  }

  /// Get expenses analytics
  Future<ExpensesSummary> getExpensesAnalytics() async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/expenses');
    return ExpensesSummary.fromJson(_extractData(response));
  }

  /// Get feed analytics
  Future<FeedSummary> getFeedAnalytics() async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/feed');
    return FeedSummary.fromJson(_extractData(response));
  }

  /// Get health analytics
  Future<HealthSummary> getHealthAnalytics() async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/health');
    return HealthSummary.fromJson(_extractData(response));
  }
}
