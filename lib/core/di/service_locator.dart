import 'package:supabase_flutter/supabase_flutter.dart';

// Features
import '../../features/eggs/eggs.dart';
import '../../features/eggs/data/datasources/egg_supabase_datasource.dart';
import '../../features/sales/sales.dart';
import '../../features/expenses/expenses.dart';
import '../../features/health/health.dart';
import '../../features/feed_stock/feed_stock.dart';
import '../../features/reservations/reservations.dart';
import '../../features/analytics/data/datasources/analytics_supabase_datasource.dart';
import '../../features/analytics/presentation/providers/analytics_provider.dart';
import '../../features/farms/presentation/providers/farm_provider.dart';

/// Service Locator for dependency injection
/// All data operations go directly through Supabase
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;

  ServiceLocator._internal();

  bool _initialized = false;

  /// Get the Supabase client
  SupabaseClient get supabaseClient => Supabase.instance.client;

  // Data Sources (all use Supabase)
  late final EggRemoteDataSource _eggDataSource;
  late final SaleRemoteDataSource _saleDataSource;
  late final ExpenseRemoteDataSource _expenseDataSource;
  late final VetRemoteDataSource _vetDataSource;
  late final FeedStockRemoteDataSource _feedStockDataSource;
  late final ReservationRemoteDataSource _reservationDataSource;
  late final AnalyticsSupabaseDataSource _analyticsDataSource;

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

    // Initialize all data sources using Supabase
    _eggDataSource = EggSupabaseDataSourceImpl(supabaseClient);
    _saleDataSource = SaleRemoteDataSourceImpl(supabaseClient);
    _expenseDataSource = ExpenseRemoteDataSourceImpl(supabaseClient);
    _vetDataSource = VetRemoteDataSourceImpl(supabaseClient);
    _feedStockDataSource = FeedStockRemoteDataSourceImpl(client: supabaseClient);
    _reservationDataSource = ReservationRemoteDataSourceImpl(client: supabaseClient);
    _analyticsDataSource = AnalyticsSupabaseDataSource(supabaseClient);

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

  // ===== FARMS FEATURE =====
  // Uses Supabase RPC directly for multi-user farm management

  FarmProvider createFarmProvider() {
    return FarmProvider(supabaseClient);
  }
}
