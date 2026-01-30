// test/features/feed_stock/presentation/providers/feed_stock_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/core.dart';
import 'package:hckegg_lite/features/feed_stock/domain/domain.dart';
import 'package:hckegg_lite/features/feed_stock/presentation/providers/feed_stock_provider.dart';
import 'package:hckegg_lite/models/feed_stock.dart';

// Mock Use Cases
class MockGetFeedStocks implements GetFeedStocks {
  List<FeedStock> stocksToReturn = [];
  Failure? failureToReturn;
  int callCount = 0;

  @override
  Future<Result<List<FeedStock>>> call(NoParams params) async {
    callCount++;
    if (failureToReturn != null) {
      return Result.fail(failureToReturn!);
    }
    return Result.success(stocksToReturn);
  }
}

class MockCreateFeedStock implements CreateFeedStock {
  Failure? failureToReturn;
  int callCount = 0;

  @override
  Future<Result<FeedStock>> call(CreateFeedStockParams params) async {
    callCount++;
    if (failureToReturn != null) {
      return Result.fail(failureToReturn!);
    }
    return Result.success(params.stock);
  }
}

class MockUpdateFeedStock implements UpdateFeedStock {
  Failure? failureToReturn;
  int callCount = 0;

  @override
  Future<Result<FeedStock>> call(UpdateFeedStockParams params) async {
    callCount++;
    if (failureToReturn != null) {
      return Result.fail(failureToReturn!);
    }
    return Result.success(params.stock);
  }
}

class MockDeleteFeedStock implements DeleteFeedStock {
  Failure? failureToReturn;
  int callCount = 0;

  @override
  Future<Result<void>> call(DeleteFeedStockParams params) async {
    callCount++;
    if (failureToReturn != null) {
      return Result.fail(failureToReturn!);
    }
    return Result.success(null);
  }
}

class MockGetFeedMovements implements GetFeedMovements {
  List<FeedMovement> movementsToReturn = [];
  int callCount = 0;

  @override
  Future<Result<List<FeedMovement>>> call(GetFeedMovementsParams params) async {
    callCount++;
    return Result.success(movementsToReturn);
  }
}

class MockAddFeedMovement implements AddFeedMovement {
  Failure? failureToReturn;
  int callCount = 0;

  @override
  Future<Result<FeedMovement>> call(AddFeedMovementParams params) async {
    callCount++;
    if (failureToReturn != null) {
      return Result.fail(failureToReturn!);
    }
    return Result.success(params.movement);
  }
}

void main() {
  late MockGetFeedStocks mockGetFeedStocks;
  late MockCreateFeedStock mockCreateFeedStock;
  late MockUpdateFeedStock mockUpdateFeedStock;
  late MockDeleteFeedStock mockDeleteFeedStock;
  late MockGetFeedMovements mockGetFeedMovements;
  late MockAddFeedMovement mockAddFeedMovement;
  late FeedStockProvider provider;

  setUp(() {
    mockGetFeedStocks = MockGetFeedStocks();
    mockCreateFeedStock = MockCreateFeedStock();
    mockUpdateFeedStock = MockUpdateFeedStock();
    mockDeleteFeedStock = MockDeleteFeedStock();
    mockGetFeedMovements = MockGetFeedMovements();
    mockAddFeedMovement = MockAddFeedMovement();

    provider = FeedStockProvider(
      getFeedStocks: mockGetFeedStocks,
      createFeedStock: mockCreateFeedStock,
      updateFeedStock: mockUpdateFeedStock,
      deleteFeedStock: mockDeleteFeedStock,
      getFeedMovements: mockGetFeedMovements,
      addFeedMovement: mockAddFeedMovement,
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
        mockGetFeedStocks.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.0),
        ];

        await provider.loadFeedStocks();

        expect(provider.feedStocks.length, 2);
        expect(provider.state, FeedStockState.loaded);
        expect(mockGetFeedStocks.callCount, 1);
      });

      test('sets error state on failure', () async {
        mockGetFeedStocks.failureToReturn = ServerFailure(message: 'Network error');

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
        expect(mockCreateFeedStock.callCount, 1);
      });

      test('updates existing stock', () async {
        final stock = _createFeedStock('1', FeedType.layer, 50.0);
        mockGetFeedStocks.stocksToReturn = [stock];
        await provider.loadFeedStocks();

        final updatedStock = _createFeedStock('1', FeedType.layer, 75.0);
        await provider.saveFeedStock(updatedStock);

        expect(provider.feedStocks.length, 1);
        expect(provider.feedStocks[0].currentQuantityKg, 75.0);
        expect(mockUpdateFeedStock.callCount, 1);
      });

      test('returns false on failure', () async {
        mockCreateFeedStock.failureToReturn = ServerFailure(message: 'Create failed');
        final stock = _createFeedStock('1', FeedType.layer, 50.0);

        final result = await provider.saveFeedStock(stock);

        expect(result, false);
        expect(provider.state, FeedStockState.error);
      });
    });

    group('deleteFeedStock', () {
      test('removes stock from list', () async {
        mockGetFeedStocks.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.0),
        ];
        await provider.loadFeedStocks();

        final result = await provider.deleteFeedStock('1');

        expect(result, true);
        expect(provider.feedStocks.length, 1);
        expect(provider.feedStocks[0].id, '2');
      });

      test('returns false on failure', () async {
        mockDeleteFeedStock.failureToReturn = ServerFailure(message: 'Delete failed');

        final result = await provider.deleteFeedStock('1');

        expect(result, false);
        expect(provider.state, FeedStockState.error);
      });
    });

    group('statistics', () {
      test('calculates totalFeedStock correctly', () async {
        mockGetFeedStocks.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.5),
          _createFeedStock('3', FeedType.starter, 20.0),
        ];
        await provider.loadFeedStocks();

        expect(provider.totalFeedStock, closeTo(100.5, 0.01));
      });

      test('calculates lowStockCount correctly', () async {
        mockGetFeedStocks.stocksToReturn = [
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
        mockGetFeedStocks.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.0),
        ];
        await provider.loadFeedStocks();

        final results = provider.search('');

        expect(results.length, 2);
      });

      test('filters by feed type', () async {
        mockGetFeedStocks.stocksToReturn = [
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
        mockGetFeedStocks.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0, brand: 'Premium Feed'),
          _createFeedStock('2', FeedType.grower, 30.0, brand: 'Economy'),
        ];
        await provider.loadFeedStocks();

        final results = provider.search('premium');

        expect(results.length, 1);
        expect(results[0].brand, 'Premium Feed');
      });

      test('search is case insensitive', () async {
        mockGetFeedStocks.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0, brand: 'PREMIUM'),
        ];
        await provider.loadFeedStocks();

        final results = provider.search('premium');

        expect(results.length, 1);
      });

      test('returns empty list when no matches', () async {
        mockGetFeedStocks.stocksToReturn = [
          _createFeedStock('1', FeedType.layer, 50.0),
        ];
        await provider.loadFeedStocks();

        final results = provider.search('xyz');

        expect(results, isEmpty);
      });
    });

    group('getLowStockFeeds', () {
      test('returns stocks below minimum quantity', () async {
        mockGetFeedStocks.stocksToReturn = [
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
        mockGetFeedStocks.stocksToReturn = [
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
