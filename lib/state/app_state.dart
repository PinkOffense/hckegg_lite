import 'package:flutter/material.dart';
import '../core/date_utils.dart';
import '../core/di/repository_provider.dart';
import '../domain/repositories/egg_repository.dart';
import '../domain/repositories/expense_repository.dart';
import '../domain/repositories/vet_repository.dart';
import '../domain/repositories/sale_repository.dart';
import '../domain/repositories/feed_repository.dart';
import '../models/daily_egg_record.dart';
import '../models/expense.dart';
import '../models/vet_record.dart';
import '../models/egg_sale.dart';
import '../models/egg_reservation.dart';
import '../models/feed_stock.dart';

class AppState extends ChangeNotifier {
  // Repositories
  final EggRepository _eggRepository = RepositoryProvider.instance.eggRepository;
  final ExpenseRepository _expenseRepository = RepositoryProvider.instance.expenseRepository;
  final VetRepository _vetRepository = RepositoryProvider.instance.vetRepository;
  final SaleRepository _saleRepository = RepositoryProvider.instance.saleRepository;
  final FeedRepository _feedRepository = RepositoryProvider.instance.feedRepository;

  // State - Egg Records
  List<DailyEggRecord> _records = [];
  bool _isLoadingRecords = false;
  String? _recordsError;

  // State - Expenses
  List<Expense> _expenses = [];
  bool _isLoadingExpenses = false;
  String? _expensesError;

  // State - Vet Records
  List<VetRecord> _vetRecords = [];
  bool _isLoadingVetRecords = false;
  String? _vetRecordsError;

  // State - Sales
  List<EggSale> _sales = [];
  bool _isLoadingSales = false;
  String? _salesError;

  // State - Reservations (local storage for now)
  List<EggReservation> _reservations = [];
  bool _isLoadingReservations = false;
  String? _reservationsError;

  // State - Feed Stock
  List<FeedStock> _feedStocks = [];
  bool _isLoadingFeedStocks = false;
  String? _feedStocksError;

  // Getters - Egg Records
  List<DailyEggRecord> get records => List.unmodifiable(_records);
  bool get isLoadingRecords => _isLoadingRecords;
  String? get recordsError => _recordsError;

  // Getters - Expenses
  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoadingExpenses => _isLoadingExpenses;
  String? get expensesError => _expensesError;

  // Getters - Vet Records
  List<VetRecord> get vetRecords => List.unmodifiable(_vetRecords);
  bool get isLoadingVetRecords => _isLoadingVetRecords;
  String? get vetRecordsError => _vetRecordsError;

  // Getters - Sales
  List<EggSale> get sales => List.unmodifiable(_sales);
  bool get isLoadingSales => _isLoadingSales;
  String? get salesError => _salesError;

  // Getters - Reservations
  List<EggReservation> get reservations => List.unmodifiable(_reservations);
  bool get isLoadingReservations => _isLoadingReservations;
  String? get reservationsError => _reservationsError;

  // Getters - Feed Stock
  List<FeedStock> get feedStocks => List.unmodifiable(_feedStocks);
  bool get isLoadingFeedStocks => _isLoadingFeedStocks;
  String? get feedStocksError => _feedStocksError;

  // Overall loading state
  bool get isLoading => _isLoadingRecords || _isLoadingExpenses || _isLoadingVetRecords || _isLoadingSales || _isLoadingReservations || _isLoadingFeedStocks;

  // ========== EGG RECORDS ==========

  /// Carregar todos os registos de ovos do Supabase
  Future<void> loadRecords() async {
    _isLoadingRecords = true;
    _recordsError = null;
    notifyListeners();

    try {
      _records = await _eggRepository.getAll();
    } catch (e) {
      _recordsError = e.toString();
    } finally {
      _isLoadingRecords = false;
      notifyListeners();
    }
  }

  /// Obter registo por data
  DailyEggRecord? getRecordByDate(String date) {
    try {
      return _records.firstWhere((r) => r.date == date);
    } catch (e) {
      return null;
    }
  }

  /// Guardar (criar ou actualizar) um registo
  Future<void> saveRecord(DailyEggRecord record) async {
    try {
      final saved = await _eggRepository.save(record);

      // Actualizar lista local
      final existingIndex = _records.indexWhere((r) => r.date == saved.date);
      if (existingIndex != -1) {
        _records[existingIndex] = saved;
      } else {
        _records.insert(0, saved);
      }

      // Ordenar por data (mais recentes primeiro)
      _records.sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
    } catch (e) {
      _recordsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Eliminar um registo por data
  Future<void> deleteRecord(String date) async {
    try {
      await _eggRepository.deleteByDate(date);
      _records.removeWhere((r) => r.date == date);
      notifyListeners();
    } catch (e) {
      _recordsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obter registos num intervalo de datas
  List<DailyEggRecord> getRecordsInRange(DateTime start, DateTime end) {
    final startStr = AppDateUtils.toIsoDateString(start);
    final endStr = AppDateUtils.toIsoDateString(end);

    return _records.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList();
  }

  /// Obter últimos N dias de registos
  List<DailyEggRecord> getRecentRecords(int days) {
    return _records.take(days).toList();
  }

  /// Pesquisar registos
  List<DailyEggRecord> search(String query) {
    if (query.isEmpty) return records;
    return records.where((r) {
      final notesMatch = r.notes?.toLowerCase().contains(query.toLowerCase()) ?? false;
      final dateMatch = r.date.contains(query);
      return notesMatch || dateMatch;
    }).toList();
  }

  // Estatísticas de ovos
  int get totalEggsCollected {
    return _records.fold<int>(0, (sum, r) => sum + r.eggsCollected);
  }

  int get totalEggsConsumed {
    return _records.fold<int>(0, (sum, r) => sum + r.eggsConsumed);
  }

  int get totalEggsRemaining {
    return _records.fold<int>(0, (sum, r) => sum + r.eggsRemaining);
  }

  // Estatísticas de vendas
  int get totalEggsSold {
    return _sales.fold<int>(0, (sum, s) => sum + s.quantitySold);
  }

  double get totalRevenue {
    return _sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
  }

  /// Estatísticas da semana
  Map<String, dynamic> getWeekStats() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekRecords = getRecordsInRange(weekAgo, now);
    final weekSales = getSalesInRange(weekAgo, now);

    final revenue = weekSales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);

    return {
      'collected': weekRecords.fold<int>(0, (sum, r) => sum + r.eggsCollected),
      'sold': weekSales.fold<int>(0, (sum, s) => sum + s.quantitySold),
      'consumed': weekRecords.fold<int>(0, (sum, r) => sum + r.eggsConsumed),
      'revenue': revenue,
      'expenses': 0.0, // Expenses removed from daily records
      'net_profit': revenue,
    };
  }

  // ========== EXPENSES ==========

  /// Carregar todas as despesas do Supabase
  Future<void> loadExpenses() async {
    _isLoadingExpenses = true;
    _expensesError = null;
    notifyListeners();

    try {
      _expenses = await _expenseRepository.getAll();
    } catch (e) {
      _expensesError = e.toString();
    } finally {
      _isLoadingExpenses = false;
      notifyListeners();
    }
  }

  /// Guardar uma despesa
  Future<void> saveExpense(Expense expense) async {
    try {
      final saved = await _expenseRepository.save(expense);

      // Actualizar lista local
      final existingIndex = _expenses.indexWhere((e) => e.id == saved.id);
      if (existingIndex != -1) {
        _expenses[existingIndex] = saved;
      } else {
        _expenses.insert(0, saved);
      }

      notifyListeners();
    } catch (e) {
      _expensesError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Eliminar uma despesa
  Future<void> deleteExpense(String id) async {
    try {
      await _expenseRepository.delete(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _expensesError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obter despesas por categoria
  List<Expense> getExpensesByCategory(ExpenseCategory category) {
    return _expenses.where((e) => e.category == category).toList();
  }

  // ========== VET RECORDS ==========

  /// Carregar registos veterinários do Supabase
  Future<void> loadVetRecords() async {
    _isLoadingVetRecords = true;
    _vetRecordsError = null;
    notifyListeners();

    try {
      _vetRecords = await _vetRepository.getAll();
      // Auto-remove past appointments (before today)
      await _cleanupPastAppointments();
    } catch (e) {
      _vetRecordsError = e.toString();
    } finally {
      _isLoadingVetRecords = false;
      notifyListeners();
    }
  }

  /// Remove appointments scheduled for before today
  Future<void> _cleanupPastAppointments() async {
    final today = DateTime.now();
    final todayStr = AppDateUtils.toIsoDateString(today);

    final pastRecords = _vetRecords.where((r) {
      if (r.nextActionDate == null) return false;
      return r.nextActionDate!.compareTo(todayStr) < 0;
    }).toList();

    for (final record in pastRecords) {
      try {
        await _vetRepository.delete(record.id);
        _vetRecords.removeWhere((r) => r.id == record.id);
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
  }

  /// Get today's appointments for reminder popup
  List<VetRecord> getTodayAppointments() {
    final todayStr = AppDateUtils.toIsoDateString(DateTime.now());
    return _vetRecords
        .where((r) => r.nextActionDate == todayStr)
        .toList();
  }

  /// Obter registos veterinários (ordenados)
  List<VetRecord> getVetRecords() {
    final sorted = List<VetRecord>.from(_vetRecords);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// Guardar um registo veterinário
  Future<void> saveVetRecord(VetRecord record) async {
    try {
      final saved = await _vetRepository.save(record);

      // Actualizar lista local
      final existingIndex = _vetRecords.indexWhere((r) => r.id == saved.id);
      if (existingIndex != -1) {
        _vetRecords[existingIndex] = saved;
      } else {
        _vetRecords.add(saved);
      }

      notifyListeners();
    } catch (e) {
      _vetRecordsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Eliminar um registo veterinário
  Future<void> deleteVetRecord(String id) async {
    try {
      await _vetRepository.delete(id);
      _vetRecords.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _vetRecordsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obter registos por tipo
  List<VetRecord> getVetRecordsByType(VetRecordType type) {
    return _vetRecords.where((r) => r.type == type).toList();
  }

  /// Obter acções agendadas futuras
  List<VetRecord> getUpcomingVetActions() {
    final now = DateTime.now();
    return _vetRecords
        .where((r) => r.nextActionDate != null)
        .where((r) {
          final nextDate = DateTime.parse(r.nextActionDate!);
          return nextDate.isAfter(now);
        })
        .toList()
      ..sort((a, b) => a.nextActionDate!.compareTo(b.nextActionDate!));
  }

  // Estatísticas veterinárias
  int get totalVetRecords => _vetRecords.length;

  int get totalDeaths => _vetRecords.where((r) => r.type == VetRecordType.death).length;

  double get totalVetCosts => _vetRecords.fold<double>(0.0, (sum, r) => sum + (r.cost ?? 0.0));

  int get totalHensAffected => _vetRecords.fold<int>(0, (sum, r) => sum + r.hensAffected);

  // ========== SALES ==========

  /// Carregar todas as vendas do Supabase
  Future<void> loadSales() async {
    _isLoadingSales = true;
    _salesError = null;
    notifyListeners();

    try {
      _sales = await _saleRepository.getAll();
    } catch (e) {
      _salesError = e.toString();
    } finally {
      _isLoadingSales = false;
      notifyListeners();
    }
  }

  /// Guardar uma venda
  Future<void> saveSale(EggSale sale) async {
    try {
      final saved = await _saleRepository.save(sale);

      // Actualizar lista local
      final existingIndex = _sales.indexWhere((s) => s.id == saved.id);
      if (existingIndex != -1) {
        _sales[existingIndex] = saved;
      } else {
        _sales.insert(0, saved);
      }

      // Ordenar por data (mais recentes primeiro)
      _sales.sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
    } catch (e) {
      _salesError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Eliminar uma venda
  Future<void> deleteSale(String id) async {
    try {
      await _saleRepository.delete(id);
      _sales.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _salesError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obter vendas num intervalo de datas
  List<EggSale> getSalesInRange(DateTime start, DateTime end) {
    final startStr = AppDateUtils.toIsoDateString(start);
    final endStr = AppDateUtils.toIsoDateString(end);

    return _sales.where((s) {
      return s.date.compareTo(startStr) >= 0 && s.date.compareTo(endStr) <= 0;
    }).toList();
  }

  /// Obter vendas por cliente
  List<EggSale> getSalesByCustomer(String customerName) {
    return _sales.where((s) =>
      s.customerName?.toLowerCase().contains(customerName.toLowerCase()) ?? false
    ).toList();
  }

  /// Obter últimas N vendas
  List<EggSale> getRecentSales(int count) {
    return _sales.take(count).toList();
  }

  // ========== RESERVATIONS ==========

  /// Carregar todas as reservas (local storage for now)
  Future<void> loadReservations() async {
    _isLoadingReservations = true;
    _reservationsError = null;
    notifyListeners();

    try {
      // TODO: Implement Supabase storage when ready
      // For now, reservations are stored in memory only
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      _reservationsError = e.toString();
    } finally {
      _isLoadingReservations = false;
      notifyListeners();
    }
  }

  /// Guardar uma reserva
  Future<void> saveReservation(EggReservation reservation) async {
    try {
      // TODO: Implement Supabase storage when ready
      // For now, use local storage only

      // Actualizar lista local
      final existingIndex = _reservations.indexWhere((r) => r.id == reservation.id);
      if (existingIndex != -1) {
        _reservations[existingIndex] = reservation;
      } else {
        _reservations.insert(0, reservation);
      }

      // Ordenar por data (mais recentes primeiro)
      _reservations.sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
    } catch (e) {
      _reservationsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Eliminar uma reserva
  Future<void> deleteReservation(String id) async {
    try {
      // TODO: Implement Supabase storage when ready
      _reservations.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _reservationsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Converter reserva em venda
  Future<void> convertReservationToSale(EggReservation reservation, PaymentStatus paymentStatus) async {
    try {
      // Create a new sale from the reservation
      final sale = EggSale(
        id: reservation.id, // Use same ID for tracking
        date: AppDateUtils.toIsoDateString(DateTime.now()), // Sale date is today
        quantitySold: reservation.quantity,
        pricePerEgg: reservation.pricePerEgg ?? 0.50, // Use reserved price or default
        pricePerDozen: reservation.pricePerDozen ?? 6.00,
        customerName: reservation.customerName,
        customerEmail: reservation.customerEmail,
        customerPhone: reservation.customerPhone,
        notes: reservation.notes != null
          ? 'Converted from reservation on ${reservation.date}. ${reservation.notes}'
          : 'Converted from reservation on ${reservation.date}',
        paymentStatus: paymentStatus,
        paymentDate: paymentStatus == PaymentStatus.paid || paymentStatus == PaymentStatus.advance
          ? AppDateUtils.toIsoDateString(DateTime.now())
          : null,
        isReservation: false,
        reservationNotes: null,
        createdAt: DateTime.now(),
        isLost: false,
      );

      // Save the sale
      await saveSale(sale);

      // Remove the reservation
      await deleteReservation(reservation.id);

      notifyListeners();
    } catch (e) {
      _reservationsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obter reservas num intervalo de datas
  List<EggReservation> getReservationsInRange(DateTime start, DateTime end) {
    final startStr = AppDateUtils.toIsoDateString(start);
    final endStr = AppDateUtils.toIsoDateString(end);

    return _reservations.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList();
  }

  // ========== FEED STOCK ==========

  /// Carregar todos os stocks de ração
  Future<void> loadFeedStocks() async {
    _isLoadingFeedStocks = true;
    _feedStocksError = null;
    notifyListeners();

    try {
      _feedStocks = await _feedRepository.getAll();
    } catch (e) {
      _feedStocksError = e.toString();
    } finally {
      _isLoadingFeedStocks = false;
      notifyListeners();
    }
  }

  /// Obter todos os stocks de ração
  List<FeedStock> getFeedStocks() {
    return List<FeedStock>.from(_feedStocks);
  }

  /// Obter stocks com quantidade baixa
  List<FeedStock> getLowStockFeeds() {
    return _feedStocks.where((s) => s.isLowStock).toList();
  }

  /// Guardar um stock de ração
  Future<void> saveFeedStock(FeedStock stock) async {
    // Optimistic update - atualizar UI imediatamente
    final existingIndex = _feedStocks.indexWhere((s) => s.id == stock.id);
    if (existingIndex != -1) {
      _feedStocks[existingIndex] = stock;
    } else {
      _feedStocks.add(stock);
    }
    notifyListeners();

    // Tentar guardar no Supabase
    try {
      await _feedRepository.save(stock);
    } catch (e) {
      // Se falhar, manter a atualização local
      _feedStocksError = e.toString();
    }
  }

  /// Eliminar um stock de ração
  Future<void> deleteFeedStock(String id) async {
    try {
      await _feedRepository.delete(id);
      _feedStocks.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _feedStocksError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Adicionar movimento de stock (compra, consumo, etc)
  Future<void> addFeedMovement(FeedMovement movement, FeedStock stock) async {
    // Calcular nova quantidade
    double newQuantity = stock.currentQuantityKg;
    if (movement.movementType == StockMovementType.purchase) {
      newQuantity += movement.quantityKg;
    } else {
      newQuantity -= movement.quantityKg;
    }

    final updatedStock = stock.copyWith(
      currentQuantityKg: newQuantity < 0 ? 0 : newQuantity,
      lastUpdated: DateTime.now(),
    );

    // Optimistic update - atualizar UI imediatamente
    final existingIndex = _feedStocks.indexWhere((s) => s.id == stock.id);
    if (existingIndex != -1) {
      _feedStocks[existingIndex] = updatedStock;
      notifyListeners();
    }

    // Tentar guardar no Supabase (pode falhar se tabelas não existirem)
    try {
      await _feedRepository.addMovement(movement);
      await _feedRepository.save(updatedStock);
    } catch (e) {
      // Se falhar, manter a atualização local (dados não sincronizados)
      _feedStocksError = e.toString();
    }
  }

  /// Obter movimentos de um stock
  Future<List<FeedMovement>> getFeedMovements(String feedStockId) async {
    try {
      return await _feedRepository.getMovements(feedStockId);
    } catch (e) {
      _feedStocksError = e.toString();
      return [];
    }
  }

  // Estatísticas de ração
  double get totalFeedStock {
    return _feedStocks.fold<double>(0.0, (sum, s) => sum + s.currentQuantityKg);
  }

  int get lowStockCount {
    return _feedStocks.where((s) => s.isLowStock).length;
  }

  // ========== CLEAR ALL DATA ==========

  /// Limpar todos os dados locais (usado no logout)
  void clearAllData() {
    _records = [];
    _recordsError = null;
    _isLoadingRecords = false;

    _expenses = [];
    _expensesError = null;
    _isLoadingExpenses = false;

    _vetRecords = [];
    _vetRecordsError = null;
    _isLoadingVetRecords = false;

    _sales = [];
    _salesError = null;
    _isLoadingSales = false;

    _reservations = [];
    _reservationsError = null;
    _isLoadingReservations = false;

    _feedStocks = [];
    _feedStocksError = null;
    _isLoadingFeedStocks = false;

    notifyListeners();
  }

  // ========== LOAD ALL DATA ==========

  /// Carregar todos os dados ao iniciar a app
  Future<void> loadAllData() async {
    await Future.wait([
      loadRecords(),
      loadExpenses(),
      loadVetRecords(),
      loadSales(),
      loadFeedStocks(),
    ]);
  }

}
