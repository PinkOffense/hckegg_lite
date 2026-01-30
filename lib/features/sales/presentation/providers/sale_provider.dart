import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// State for the sales feature
enum SaleState { initial, loading, loaded, error }

/// Provider for sales following clean architecture
class SaleProvider extends ChangeNotifier {
  final GetSales _getSales;
  final GetSaleById _getSaleById;
  final GetSalesInRange _getSalesInRange;
  final CreateSale _createSale;
  final UpdateSale _updateSale;
  final DeleteSale _deleteSale;

  SaleProvider({
    required GetSales getSales,
    required GetSaleById getSaleById,
    required GetSalesInRange getSalesInRange,
    required CreateSale createSale,
    required UpdateSale updateSale,
    required DeleteSale deleteSale,
  })  : _getSales = getSales,
        _getSaleById = getSaleById,
        _getSalesInRange = getSalesInRange,
        _createSale = createSale,
        _updateSale = updateSale,
        _deleteSale = deleteSale;

  // State
  SaleState _state = SaleState.initial;
  SaleState get state => _state;

  List<EggSale> _sales = [];
  List<EggSale> get sales => List.unmodifiable(_sales);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Backward compatibility

  bool get isLoading => _state == SaleState.loading;
  bool get hasError => _state == SaleState.error;

  // Cached statistics
  int? _cachedTotalSold;
  double? _cachedTotalRevenue;

  int get totalEggsSold {
    _cachedTotalSold ??= _sales.fold<int>(0, (sum, s) => sum + s.quantitySold);
    return _cachedTotalSold!;
  }

  double get totalRevenue {
    _cachedTotalRevenue ??= _sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
    return _cachedTotalRevenue!;
  }

  void _invalidateCache() {
    _cachedTotalSold = null;
    _cachedTotalRevenue = null;
  }

  /// Load all sales
  Future<void> loadSales() async {
    _state = SaleState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _getSales(const NoParams());

    result.fold(
      onSuccess: (data) {
        _sales = data;
        _invalidateCache();
        _state = SaleState.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = SaleState.error;
      },
    );

    notifyListeners();
  }

  /// Get sale by ID
  Future<EggSale?> getSaleById(String id) async {
    final result = await _getSaleById(GetSaleByIdParams(id: id));
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (_) => null,
    );
  }

  /// Get sales in date range
  Future<List<EggSale>> getSalesInRange(DateTime start, DateTime end) async {
    final result = await _getSalesInRange(
      GetSalesInRangeParams(start: start, end: end),
    );
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (_) => [],
    );
  }

  /// Save a sale (create or update)
  Future<bool> saveSale(EggSale sale) async {
    _state = SaleState.loading;
    notifyListeners();

    final Result<EggSale> result;

    if (sale.id.isEmpty || !_sales.any((s) => s.id == sale.id)) {
      result = await _createSale(CreateSaleParams(sale: sale));
    } else {
      result = await _updateSale(UpdateSaleParams(sale: sale));
    }

    final success = result.fold(
      onSuccess: (savedSale) {
        final index = _sales.indexWhere((s) => s.id == savedSale.id);
        if (index >= 0) {
          _sales[index] = savedSale;
        } else {
          _sales.insert(0, savedSale);
        }
        _sales.sort((a, b) => b.date.compareTo(a.date));
        _invalidateCache();
        _state = SaleState.loaded;
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = SaleState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
  }

  /// Delete a sale
  Future<bool> deleteSale(String id) async {
    _state = SaleState.loading;
    notifyListeners();

    final result = await _deleteSale(DeleteSaleParams(id: id));

    final success = result.fold(
      onSuccess: (_) {
        _sales.removeWhere((s) => s.id == id);
        _invalidateCache();
        _state = SaleState.loaded;
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = SaleState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
  }

  /// Get sales by customer name
  List<EggSale> getSalesByCustomer(String customerName) {
    return _sales.where((s) =>
      s.customerName?.toLowerCase().contains(customerName.toLowerCase()) ?? false
    ).toList();
  }

  /// Get recent sales
  List<EggSale> getRecentSales(int count) {
    return _sales.take(count).toList();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data (used on logout)
  void clearData() {
    _sales = [];
    _errorMessage = null;
    _state = SaleState.initial;
    _invalidateCache();
    notifyListeners();
  }
}
