// test/mocks/mock_sale_repository.dart

import 'package:hckegg_lite/domain/repositories/sale_repository.dart';
import 'package:hckegg_lite/models/egg_sale.dart';

/// Mock implementation of SaleRepository for testing
class MockSaleRepository implements SaleRepository {
  final List<EggSale> _sales = [];

  // Control flags for simulating errors
  bool shouldThrowOnSave = false;
  bool shouldThrowOnDelete = false;
  bool shouldThrowOnLoad = false;

  // Track method calls
  int saveCallCount = 0;
  int deleteCallCount = 0;
  int getAllCallCount = 0;

  void seedSales(List<EggSale> sales) {
    _sales.clear();
    _sales.addAll(sales);
  }

  void clear() {
    _sales.clear();
    saveCallCount = 0;
    deleteCallCount = 0;
    getAllCallCount = 0;
  }

  @override
  Future<List<EggSale>> getAll() async {
    getAllCallCount++;
    if (shouldThrowOnLoad) {
      throw Exception('Simulated load error');
    }
    return List.from(_sales);
  }

  @override
  Future<EggSale?> getById(String id) async {
    try {
      return _sales.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<EggSale>> getByDateRange(DateTime start, DateTime end) async {
    final startStr = _toIsoDate(start);
    final endStr = _toIsoDate(end);
    return _sales.where((s) {
      return s.date.compareTo(startStr) >= 0 && s.date.compareTo(endStr) <= 0;
    }).toList();
  }

  @override
  Future<List<EggSale>> getByCustomer(String customerName) async {
    final normalizedName = customerName.toLowerCase();
    return _sales.where((s) =>
      s.customerName?.toLowerCase().contains(normalizedName) ?? false
    ).toList();
  }

  @override
  Future<EggSale> save(EggSale sale) async {
    saveCallCount++;
    if (shouldThrowOnSave) {
      throw Exception('Simulated save error');
    }

    final existingIndex = _sales.indexWhere((s) => s.id == sale.id);
    if (existingIndex != -1) {
      _sales[existingIndex] = sale;
    } else {
      _sales.add(sale);
    }
    return sale;
  }

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    if (shouldThrowOnDelete) {
      throw Exception('Simulated delete error');
    }
    _sales.removeWhere((s) => s.id == id);
  }

  @override
  Future<double> getTotalRevenue({DateTime? startDate, DateTime? endDate}) async {
    return _sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
  }

  @override
  Future<Map<String, dynamic>> getSalesStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return {
      'total_sold': _sales.fold<int>(0, (sum, s) => sum + s.quantitySold),
      'total_revenue': _sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount),
      'sale_count': _sales.length,
    };
  }

  String _toIsoDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
