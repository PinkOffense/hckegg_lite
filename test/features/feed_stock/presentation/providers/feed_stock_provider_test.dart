// test/features/feed_stock/presentation/providers/feed_stock_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/core.dart';
import 'package:hckegg_lite/features/feed_stock/domain/domain.dart';
import 'package:hckegg_lite/features/feed_stock/presentation/providers/feed_stock_provider.dart';
import 'package:hckegg_lite/models/feed_stock.dart';

// Mock Repository
class MockFeedStockRepository implements FeedStockRepository {
  List<FeedStock> stocksToReturn = [];
  List<FeedMovement> movementsToReturn = [];
  Failure? failureToReturn;

  @override
  Future<Result<List<FeedStock>>> getFeedStocks() async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(stocksToReturn);
  }

  @override
  Future<Result<FeedStock>> getFeedStockById(String id) async {
    final stock = stocksToReturn.firstWhere((s) => s.id == id);
    return Result.success(stock);
  }

  @override
  Future<Result<List<FeedStock>>> getLowStockItems() async {
    return Result.success(stocksToReturn.where((s) => s.isLowStock).toList());
  }

  @override
  Future<Result<FeedStock>> createFeedStock(FeedStock stock) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(stock);
  }

  @override
  Future<Result<FeedStock>> updateFeedStock(FeedStock stock) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(stock);
  }

  @override
  Future<Result<void>> deleteFeedStock(String id) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(null);
  }

  @override
  Future<Result<List<FeedMovement>>> getMovements(String feedStockId) async {
    return Result.success(movementsToReturn);
  }

  @override
  Future<Result<FeedMovement>> addMovement(FeedMovement movement) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(movement);
  }
}

void main() {
  late MockFeedStockRepository mockRepository;
  late FeedStockProvider provider;

  setUp(() {
    mockRepository = MockFeedStockRepository();

    provider = FeedStockProvider(
      getFeedStocks: GetFeedStocks(mockRepository),
      getLowStockItems: GetLowStockItems(mockRepository),
      createFeedStock: CreateFeedStock(mockRepository),
      updateFeedStock: UpdateFeedStock(mockRepository),
      deleteFeedStock: DeleteFeedStock(mockRepository),
      getFeedMovements: GetFeedMovements(mockRepository),
      addFeedMovement: AddFeedMovement(mockRepository),
    );
  });

  group('FeedStockProvider', () {
    group('initial state', () {
      test('starts with empty stocks list', () {
        expect(provider.feedStocks, isEmpty);
      });

      test('starts with initial state', () {
        expect(provider.state, FeedStockState.initial);
      });

      test('starts with no error', () {
        expect(provider.error, isNull);
      });

      test('statistics are zero initially', () {
        expect(provider.totalFeedStock, 0.0);
        expect(provider.lowStockCount, 0);
      });
    });

    group('loadFeedStocks', () {
      test('loads stocks successfully', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.0),
        ];

        await provider.loadFeedStocks();

        expect(provider.feedStocks.length, 2);
        expect(provider.state, FeedStockState.loaded);
      });

      test('sets error state on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Network error');

        await provider.loadFeedStocks();

        expect(provider.state, FeedStockState.error);
        expect(provider.error, 'Network error');
      });
    });

    group('saveFeedStock', () {
      test('creates new stock successfully', () async {
        final stock = _createFeedStock('1', FeedType.layer, 50.0);

        final result = await provider.saveFeedStock(stock);

        expect(result, true);
        expect(provider.feedStocks.length, 1);
      });

      test('updates existing stock', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
        ];
        await provider.loadFeedStocks();

        final updatedStock = _createFeedStock('1', FeedType.layer, 75.0);
        await provider.saveFeedStock(updatedStock);

        expect(provider.feedStocks.length, 1);
        expect(provider.feedStocks[0].currentQuantityKg, 75.0);
      });

      test('returns false on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Create failed');
        final stock = _createFeedStock('1', FeedType.layer, 50.0);

        final result = await provider.saveFeedStock(stock);

        expect(result, false);
        expect(provider.state, FeedStockState.error);
      });
    });

    group('deleteFeedStock', () {
      test('removes stock from list', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.0),
        ];
        await provider.loadFeedStocks();
        mockRepository.failureToReturn = null; // Reset for delete

        final result = await provider.deleteFeedStock('1');

        expect(result, true);
        expect(provider.feedStocks.length, 1);
        expect(provider.feedStocks[0].id, '2');
      });

      test('returns false on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Delete failed');

        final result = await provider.deleteFeedStock('1');

        expect(result, false);
        expect(provider.state, FeedStockState.error);
      });
    });

    group('statistics', () {
      test('calculates totalFeedStock correctly', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.5),
          _createFeedStock('3', FeedType.starter, 20.0),
        ];
        await provider.loadFeedStocks();

        expect(provider.totalFeedStock, closeTo(100.5, 0.01));
      });

      test('calculates lowStockCount correctly', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0, minimumQty: 10.0), // not low
          _createFeedStock('2', FeedType.grower, 5.0, minimumQty: 10.0), // low
          _createFeedStock('3', FeedType.starter, 10.0, minimumQty: 10.0), // low (equal)
        ];
        await provider.loadFeedStocks();

        expect(provider.lowStockCount, 2);
      });
    });

    group('search', () {
      test('returns all stocks when query is empty', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.0),
        ];
        await provider.loadFeedStocks();

        final results = provider.search('');

        expect(results.length, 2);
      });

      test('filters by feed type', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.0),
          _createFeedStock('3', FeedType.starter, 20.0),
        ];
        await provider.loadFeedStocks();

        final results = provider.search('layer');

        expect(results.length, 1);
        expect(results[0].type, FeedType.layer);
      });

      test('filters by brand', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0, brand: 'Premium Feed'),
          _createFeedStock('2', FeedType.grower, 30.0, brand: 'Economy'),
        ];
        await provider.loadFeedStocks();

        final results = provider.search('premium');

        expect(results.length, 1);
        expect(results[0].brand, 'Premium Feed');
      });

      test('search is case insensitive', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0, brand: 'PREMIUM'),
        ];
        await provider.loadFeedStocks();

        final results = provider.search('premium');

        expect(results.length, 1);
      });

      test('returns empty list when no matches', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
        ];
        await provider.loadFeedStocks();

        final results = provider.search('xyz');

        expect(results, isEmpty);
      });
    });

    group('getLowStockFeeds', () {
      test('returns stocks below minimum quantity', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0, minimumQty: 10.0),
          _createFeedStock('2', FeedType.grower, 5.0, minimumQty: 10.0),
          _createFeedStock('3', FeedType.starter, 8.0, minimumQty: 10.0),
        ];
        await provider.loadFeedStocks();

        final lowStocks = provider.getLowStockFeeds();

        expect(lowStocks.length, 2);
        expect(lowStocks.every((s) => s.isLowStock), true);
      });
    });

    group('clearData', () {
      test('clears all stocks and resets state', () async {
        mockRepository.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
        ];
        await provider.loadFeedStocks();
        expect(provider.feedStocks.length, 1);

        provider.clearData();

        expect(provider.feedStocks, isEmpty);
        expect(provider.state, FeedStockState.initial);
        expect(provider.error, isNull);
      });
    });
  });
}

FeedStock _createFeedStock(
  String id,
  FeedType type,
  double currentQuantity, {
  double minimumQty = 10.0,
  String? brand,
}) {
  return FeedStock(
    id: id,
    type: type,
    brand: brand,
    currentQuantityKg: currentQuantity,
    minimumQuantityKg: minimumQty,
    lastUpdated: DateTime.now(),
    createdAt: DateTime.now(),
  );
}
