import 'package:flutter/foundation.dart';
import '../../data/datasources/analytics_api_datasource.dart';
import '../../domain/entities/analytics_data.dart';

/// State for analytics
enum AnalyticsState { initial, loading, loaded, error }

/// Provider for analytics - fetches all business logic from backend
class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsApiDataSource _dataSource;

  AnalyticsProvider(this._dataSource);

  // State
  AnalyticsState _state = AnalyticsState.initial;
  AnalyticsState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == AnalyticsState.loading;
  bool get hasError => _state == AnalyticsState.error;

  // Cached data
  DashboardAnalytics? _dashboardAnalytics;
  WeekStats? _weekStats;

  DashboardAnalytics get dashboard => _dashboardAnalytics ?? DashboardAnalytics.empty();
  WeekStats get weekStats => _weekStats ?? WeekStats.empty();

  // Convenience getters
  ProductionSummary get production => dashboard.production;
  SalesSummary get sales => dashboard.sales;
  ExpensesSummary get expenses => dashboard.expenses;
  FeedSummary get feed => dashboard.feed;
  HealthSummary get health => dashboard.health;
  List<DashboardAlert> get alerts => dashboard.alerts;

  /// Load complete dashboard analytics
  Future<void> loadDashboardAnalytics() async {
    _state = AnalyticsState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardAnalytics = await _dataSource.getDashboardAnalytics();
      _state = AnalyticsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AnalyticsState.error;
    }

    notifyListeners();
  }

  /// Load week statistics
  Future<void> loadWeekStats() async {
    try {
      _weekStats = await _dataSource.getWeekStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Refresh all analytics
  Future<void> refresh() async {
    await Future.wait([
      loadDashboardAnalytics(),
      loadWeekStats(),
    ]);
  }

  /// Clear all data (used on logout)
  void clearData() {
    _dashboardAnalytics = null;
    _weekStats = null;
    _errorMessage = null;
    _state = AnalyticsState.initial;
    notifyListeners();
  }
}
