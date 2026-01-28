// test/mocks/mock_feed_repository.dart

import '../../lib/domain/repositories/feed_repository.dart';
import '../../lib/models/feed_stock.dart';

/// Mock implementation of FeedRepository for testing
class MockFeedRepository implements FeedRepository {
  final List<FeedStock> _stocks = [];
  final List<FeedMovement> _movements = [];

  // Control flags for simulating errors
  bool shouldThrowOnSave = false;
  bool shouldThrowOnDelete = false;
  bool shouldThrowOnLoad = false;

  // Track method calls
  int saveCallCount = 0;
  int deleteCallCount = 0;
  int getAllCallCount = 0;
  int addMovementCallCount = 0;

  void seedStocks(List<FeedStock> stocks) {
    _stocks.clear();
    _stocks.addAll(stocks);
  }

  void seedMovements(List<FeedMovement> movements) {
    _movements.clear();
    _movements.addAll(movements);
  }

  void clear() {
    _stocks.clear();
    _movements.clear();
    saveCallCount = 0;
    deleteCallCount = 0;
    getAllCallCount = 0;
    addMovementCallCount = 0;
  }

  @override
  Future<List<FeedStock>> getAll() async {
    getAllCallCount++;
    if (shouldThrowOnLoad) {
      throw Exception('Simulated load error');
    }
    return List.from(_stocks);
  }

  @override
  Future<FeedStock?> getById(String id) async {
    try {
      return _stocks.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<FeedStock>> getByType(FeedType type) async {
    return _stocks.where((s) => s.type == type).toList();
  }

  @override
  Future<FeedStock> save(FeedStock stock) async {
    saveCallCount++;
    if (shouldThrowOnSave) {
      throw Exception('Simulated save error');
    }

    final existingIndex = _stocks.indexWhere((s) => s.id == stock.id);
    if (existingIndex != -1) {
      _stocks[existingIndex] = stock;
    } else {
      _stocks.add(stock);
    }
    return stock;
  }

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    if (shouldThrowOnDelete) {
      throw Exception('Simulated delete error');
    }
    _stocks.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<FeedStock>> getLowStock() async {
    return _stocks.where((s) => s.isLowStock).toList();
  }

  @override
  Future<List<FeedMovement>> getMovements(String feedStockId) async {
    return _movements.where((m) => m.feedStockId == feedStockId).toList();
  }

  @override
  Future<FeedMovement> addMovement(FeedMovement movement) async {
    addMovementCallCount++;
    _movements.add(movement);
    return movement;
  }

  @override
  Future<void> deleteMovement(String id) async {
    _movements.removeWhere((m) => m.id == id);
  }
}
