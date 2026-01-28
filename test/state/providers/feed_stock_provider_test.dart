// test/state/providers/feed_stock_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/models/feed_stock.dart';
import 'package:hckegg_lite/state/providers/feed_stock_provider.dart';
import '../../mocks/mock_feed_repository.dart';

void main() {
  late MockFeedRepository mockRepository;
  late FeedStockProvider provider;

  setUp(() {
    mockRepository = MockFeedRepository();
    provider = FeedStockProvider(repository: mockRepository);
  });

  tearDown(() {
    mockRepository.clear();
  });

  group('FeedStockProvider', () {
    group('initial state', () {
      test('starts with empty stocks list', () {
        expect(provider.feedStocks, isEmpty);
      });

      test('starts with isLoading false', () {
        expect(provider.isLoading, false);
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
      test('loads stocks from repository', () async {
        final testStocks = [
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.0),
        ];
        mockRepository.seedStocks(testStocks);

        await provider.loadFeedStocks();

        expect(provider.feedStocks.length, 2);
        expect(mockRepository.getAllCallCount, 1);
      });

      test('sets error on failure', () async {
        mockRepository.shouldThrowOnLoad = true;

        await provider.loadFeedStocks();

        expect(provider.error, isNotNull);
        expect(provider.error, contains('Simulated load error'));
      });
    });

    group('saveFeedStock', () {
      test('adds new stock to list', () async {
        final stock = _createFeedStock('1', FeedType.layer, 50.0);

        await provider.saveFeedStock(stock);

        expect(provider.feedStocks.length, 1);
        expect(provider.feedStocks[0].type, FeedType.layer);
        expect(mockRepository.saveCallCount, 1);
      });

      test('updates existing stock with same id', () async {
        final stock1 = _createFeedStock('1', FeedType.layer, 50.0);
        await provider.saveFeedStock(stock1);

        final stock2 = _createFeedStock('1', FeedType.layer, 75.0);
        await provider.saveFeedStock(stock2);

        expect(provider.feedStocks.length, 1);
        expect(provider.feedStocks[0].currentQuantityKg, 75.0);
      });

      test('performs optimistic update before repository call', () async {
        final stock = _createFeedStock('1', FeedType.layer, 50.0);

        // The stock is added immediately (optimistic)
        provider.saveFeedStock(stock);

        expect(provider.feedStocks.length, 1);
      });
    });

    group('deleteFeedStock', () {
      test('removes stock from list', () async {
        mockRepository.seedStocks([
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.0),
        ]);
        await provider.loadFeedStocks();

        await provider.deleteFeedStock('1');

        expect(provider.feedStocks.length, 1);
        expect(provider.feedStocks[0].id, '2');
        expect(mockRepository.deleteCallCount, 1);
      });

      test('sets error and rethrows on repository failure', () async {
        mockRepository.shouldThrowOnDelete = true;

        expect(() => provider.deleteFeedStock('1'), throwsException);
        expect(provider.error, isNotNull);
      });
    });

    group('statistics', () {
      test('calculates totalFeedStock correctly', () async {
        mockRepository.seedStocks([
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.5),
          _createFeedStock('3', FeedType.starter, 20.0),
        ]);
        await provider.loadFeedStocks();

        expect(provider.totalFeedStock, closeTo(100.5, 0.01));
      });

      test('calculates lowStockCount correctly', () async {
        mockRepository.seedStocks([
          _createFeedStock('1', FeedType.layer, 50.0, minimumQty: 10.0), // not low
          _createFeedStock('2', FeedType.grower, 5.0, minimumQty: 10.0), // low
          _createFeedStock('3', FeedType.starter, 10.0, minimumQty: 10.0), // low (equal)
        ]);
        await provider.loadFeedStocks();

        expect(provider.lowStockCount, 2);
      });
    });

    group('getLowStockFeeds', () {
      test('returns stocks below minimum quantity', () async {
        mockRepository.seedStocks([
          _createFeedStock('1', FeedType.layer, 50.0, minimumQty: 10.0),
          _createFeedStock('2', FeedType.grower, 5.0, minimumQty: 10.0),
          _createFeedStock('3', FeedType.starter, 8.0, minimumQty: 10.0),
        ]);
        await provider.loadFeedStocks();

        final lowStocks = provider.getLowStockFeeds();

        expect(lowStocks.length, 2);
        expect(lowStocks.every((s) => s.isLowStock), true);
      });

      test('returns empty list when no low stocks', () async {
        mockRepository.seedStocks([
          _createFeedStock('1', FeedType.layer, 50.0, minimumQty: 10.0),
        ]);
        await provider.loadFeedStocks();

        final lowStocks = provider.getLowStockFeeds();

        expect(lowStocks, isEmpty);
      });
    });

    group('addFeedMovement', () {
      test('increases quantity on purchase', () async {
        final stock = _createFeedStock('1', FeedType.layer, 50.0);
        mockRepository.seedStocks([stock]);
        await provider.loadFeedStocks();

        final movement = _createMovement('m1', '1', StockMovementType.purchase, 25.0);
        await provider.addFeedMovement(movement, stock);

        expect(provider.feedStocks[0].currentQuantityKg, 75.0);
        expect(mockRepository.addMovementCallCount, 1);
      });

      test('decreases quantity on consumption', () async {
        final stock = _createFeedStock('1', FeedType.layer, 50.0);
        mockRepository.seedStocks([stock]);
        await provider.loadFeedStocks();

        final movement = _createMovement('m1', '1', StockMovementType.consumption, 20.0);
        await provider.addFeedMovement(movement, stock);

        expect(provider.feedStocks[0].currentQuantityKg, 30.0);
      });

      test('does not go below zero on large consumption', () async {
        final stock = _createFeedStock('1', FeedType.layer, 50.0);
        mockRepository.seedStocks([stock]);
        await provider.loadFeedStocks();

        final movement = _createMovement('m1', '1', StockMovementType.consumption, 100.0);
        await provider.addFeedMovement(movement, stock);

        expect(provider.feedStocks[0].currentQuantityKg, 0.0);
      });

      test('decreases quantity on loss', () async {
        final stock = _createFeedStock('1', FeedType.layer, 50.0);
        mockRepository.seedStocks([stock]);
        await provider.loadFeedStocks();

        final movement = _createMovement('m1', '1', StockMovementType.loss, 10.0);
        await provider.addFeedMovement(movement, stock);

        expect(provider.feedStocks[0].currentQuantityKg, 40.0);
      });

      test('decreases quantity on adjustment (not purchase)', () async {
        final stock = _createFeedStock('1', FeedType.layer, 50.0);
        mockRepository.seedStocks([stock]);
        await provider.loadFeedStocks();

        final movement = _createMovement('m1', '1', StockMovementType.adjustment, 15.0);
        await provider.addFeedMovement(movement, stock);

        expect(provider.feedStocks[0].currentQuantityKg, 35.0);
      });
    });

    group('getFeedMovements', () {
      test('returns movements from repository', () async {
        final movements = [
          _createMovement('m1', '1', StockMovementType.purchase, 20.0),
          _createMovement('m2', '1', StockMovementType.consumption, 10.0),
        ];
        mockRepository.seedMovements(movements);

        final result = await provider.getFeedMovements('1');

        expect(result.length, 2);
      });

      test('returns empty list on error', () async {
        mockRepository.shouldThrowOnLoad = true;

        final result = await provider.getFeedMovements('1');

        expect(result, isEmpty);
      });
    });

    group('clearData', () {
      test('clears all stocks', () async {
        mockRepository.seedStocks([
          _createFeedStock('1', FeedType.layer, 50.0),
          _createFeedStock('2', FeedType.grower, 30.0),
        ]);
        await provider.loadFeedStocks();
        expect(provider.feedStocks.length, 2);

        provider.clearData();

        expect(provider.feedStocks, isEmpty);
        expect(provider.error, isNull);
        expect(provider.isLoading, false);
      });
    });

    group('feedStocks immutability', () {
      test('feedStocks getter returns unmodifiable list', () async {
        mockRepository.seedStocks([
          _createFeedStock('1', FeedType.layer, 50.0),
        ]);
        await provider.loadFeedStocks();

        final stocks = provider.feedStocks;

        expect(
          () => stocks.add(_createFeedStock('2', FeedType.grower, 30.0)),
          throwsUnsupportedError,
        );
      });
    });

    group('edge cases', () {
      test('handles zero quantity stock', () async {
        mockRepository.seedStocks([
          _createFeedStock('1', FeedType.layer, 0.0),
        ]);
        await provider.loadFeedStocks();

        expect(provider.totalFeedStock, 0.0);
        expect(provider.feedStocks[0].isLowStock, true);
      });

      test('handles decimal quantities', () async {
        mockRepository.seedStocks([
          _createFeedStock('1', FeedType.layer, 25.5),
          _createFeedStock('2', FeedType.grower, 10.25),
        ]);
        await provider.loadFeedStocks();

        expect(provider.totalFeedStock, closeTo(35.75, 0.01));
      });
    });
  });
}

FeedStock _createFeedStock(
  String id,
  FeedType type,
  double currentQuantity, {
  double minimumQty = 10.0,
}) {
  return FeedStock(
    id: id,
    type: type,
    currentQuantityKg: currentQuantity,
    minimumQuantityKg: minimumQty,
    lastUpdated: DateTime.now(),
    createdAt: DateTime.now(),
  );
}

FeedMovement _createMovement(
  String id,
  String feedStockId,
  StockMovementType type,
  double quantityKg,
) {
  return FeedMovement(
    id: id,
    feedStockId: feedStockId,
    movementType: type,
    quantityKg: quantityKg,
    date: '2024-01-15',
    createdAt: DateTime.now(),
  );
}
