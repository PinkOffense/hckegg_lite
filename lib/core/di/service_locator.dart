import 'package:supabase_flutter/supabase_flutter.dart';

// Core
import '../api/api_client.dart';
import '../api/api_config.dart';

// Features
import '../../features/eggs/eggs.dart';
import '../../features/sales/sales.dart';
import '../../features/expenses/expenses.dart';
import '../../features/health/health.dart';
import '../../features/feed_stock/feed_stock.dart';
import '../../features/reservations/reservations.dart';
import '../../features/analytics/data/datasources/analytics_api_datasource.dart';
import '../../features/analytics/presentation/providers/analytics_provider.dart';

/// Service Locator for dependency injection
/// All data operations go through the backend API
/// Supabase is only used for authentication (token management)
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;

  ServiceLocator._internal();

  late final ApiClient _apiClient;
  bool _initialized = false;

  /// Get the Supabase client (for auth only)
  SupabaseClient get supabaseClient => Supabase.instance.client;

  /// Get the API client
  ApiClient get apiClient => _apiClient;

  // Data Sources (all use API)
  late final EggRemoteDataSource _eggDataSource;
  late final SaleRemoteDataSource _saleDataSource;
  late final ExpenseRemoteDataSource _expenseDataSource;
  late final VetRemoteDataSource _vetDataSource;
  late final FeedStockRemoteDataSource _feedStockDataSource;
  late final ReservationRemoteDataSource _reservationDataSource;
  late final AnalyticsApiDataSource _analyticsDataSource;

  // Repositories
  late final EggRepository _eggRepository;
  late final SaleRepository _saleRepository;
  late final ExpenseRepository _expenseRepository;
  late final VetRepository _vetRepository;
  late final FeedStockRepository _feedStockRepository;
  late final ReservationRepository _reservationRepository;

  /// Initialize the service locator after Supabase is ready
  void initialize() {
    if (_initialized) return;

    // Initialize API client
    _apiClient = ApiClient(baseUrl: ApiConfig.apiUrl);

    // Initialize all data sources using the API backend
    _eggDataSource = EggApiDataSourceImpl(_apiClient);
    _saleDataSource = SaleApiDataSourceImpl(_apiClient);
    _expenseDataSource = ExpenseApiDataSourceImpl(_apiClient);
    _vetDataSource = VetApiDataSourceImpl(_apiClient);
    _feedStockDataSource = FeedStockApiDataSourceImpl(apiClient: _apiClient);
    _reservationDataSource = ReservationApiDataSourceImpl(apiClient: _apiClient);
    _analyticsDataSource = AnalyticsApiDataSource(_apiClient);

    // Initialize Repositories
    _eggRepository = EggRepositoryImpl(remoteDataSource: _eggDataSource);
    _saleRepository = SaleRepositoryImpl(remoteDataSource: _saleDataSource);
    _expenseRepository =
        ExpenseRepositoryImpl(remoteDataSource: _expenseDataSource);
    _vetRepository = VetRepositoryImpl(remoteDataSource: _vetDataSource);
    _feedStockRepository =
        FeedStockRepositoryImpl(remoteDataSource: _feedStockDataSource);
    _reservationRepository =
        ReservationRepositoryImpl(remoteDataSource: _reservationDataSource);

    _initialized = true;
  }

  // ===== EGG FEATURE =====

  EggProvider createEggProvider() {
    return EggProvider(
      getEggRecords: GetEggRecords(_eggRepository),
      createEggRecord: CreateEggRecord(_eggRepository),
      updateEggRecord: UpdateEggRecord(_eggRepository),
      deleteEggRecord: DeleteEggRecord(_eggRepository),
    );
  }

  // ===== SALES FEATURE =====

  SaleProvider createSaleProvider() {
    return SaleProvider(
      getSales: GetSales(_saleRepository),
      getSaleById: GetSaleById(_saleRepository),
      getSalesInRange: GetSalesInRange(_saleRepository),
      createSale: CreateSale(_saleRepository),
      updateSale: UpdateSale(_saleRepository),
      deleteSale: DeleteSale(_saleRepository),
    );
  }

  // ===== EXPENSES FEATURE =====

  ExpenseProvider createExpenseProvider() {
    return ExpenseProvider(
      getExpenses: GetExpenses(_expenseRepository),
      getExpensesByCategory: GetExpensesByCategory(_expenseRepository),
      createExpense: CreateExpense(_expenseRepository),
      updateExpense: UpdateExpense(_expenseRepository),
      deleteExpense: DeleteExpense(_expenseRepository),
    );
  }

  // ===== HEALTH FEATURE =====

  VetProvider createVetProvider() {
    return VetProvider(
      getVetRecords: GetVetRecords(_vetRepository),
      getUpcomingAppointments: GetUpcomingAppointments(_vetRepository),
      createVetRecord: CreateVetRecord(_vetRepository),
      updateVetRecord: UpdateVetRecord(_vetRepository),
      deleteVetRecord: DeleteVetRecord(_vetRepository),
    );
  }

  // ===== FEED STOCK FEATURE =====

  FeedStockProvider createFeedStockProvider() {
    return FeedStockProvider(
      getFeedStocks: GetFeedStocks(_feedStockRepository),
      getLowStockItems: GetLowStockItems(_feedStockRepository),
      createFeedStock: CreateFeedStock(_feedStockRepository),
      updateFeedStock: UpdateFeedStock(_feedStockRepository),
      deleteFeedStock: DeleteFeedStock(_feedStockRepository),
      getFeedMovements: GetFeedMovements(_feedStockRepository),
      addFeedMovement: AddFeedMovement(_feedStockRepository),
    );
  }

  // ===== RESERVATIONS FEATURE =====

  ReservationProvider createReservationProvider() {
    return ReservationProvider(
      getReservations: GetReservations(_reservationRepository),
      getReservationsInRange: GetReservationsInRange(_reservationRepository),
      createReservation: CreateReservation(_reservationRepository),
      updateReservation: UpdateReservation(_reservationRepository),
      deleteReservation: DeleteReservation(_reservationRepository),
      createSale: CreateSale(_saleRepository),
    );
  }

  // ===== ANALYTICS FEATURE =====

  AnalyticsProvider createAnalyticsProvider() {
    return AnalyticsProvider(_analyticsDataSource);
  }
}
