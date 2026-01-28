// test/state/providers/sale_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/models/egg_sale.dart';
import 'package:hckegg_lite/state/providers/sale_provider.dart';
import '../../mocks/mock_sale_repository.dart';

void main() {
  late MockSaleRepository mockRepository;
  late SaleProvider provider;

  setUp(() {
    mockRepository = MockSaleRepository();
    provider = SaleProvider(repository: mockRepository);
  });

  tearDown(() {
    mockRepository.clear();
  });

  group('SaleProvider', () {
    group('initial state', () {
      test('starts with empty sales list', () {
        expect(provider.sales, isEmpty);
      });

      test('starts with isLoading false', () {
        expect(provider.isLoading, false);
      });

      test('starts with no error', () {
        expect(provider.error, isNull);
      });

      test('total stats are zero initially', () {
        expect(provider.totalEggsSold, 0);
        expect(provider.totalRevenue, 0.0);
      });
    });

    group('loadSales', () {
      test('loads sales from repository', () async {
        final testSales = [
          _createSale('1', '2024-01-15', 12, 0.50),
          _createSale('2', '2024-01-16', 24, 0.50),
        ];
        mockRepository.seedSales(testSales);

        await provider.loadSales();

        expect(provider.sales.length, 2);
        expect(mockRepository.getAllCallCount, 1);
      });

      test('sets error on failure', () async {
        mockRepository.shouldThrowOnLoad = true;

        await provider.loadSales();

        expect(provider.error, isNotNull);
        expect(provider.error, contains('Simulated load error'));
      });
    });

    group('saveSale', () {
      test('adds new sale to list', () async {
        final sale = _createSale('1', '2024-01-15', 12, 0.50);

        await provider.saveSale(sale);

        expect(provider.sales.length, 1);
        expect(provider.sales[0].quantitySold, 12);
        expect(mockRepository.saveCallCount, 1);
      });

      test('updates existing sale with same id', () async {
        final sale1 = _createSale('1', '2024-01-15', 12, 0.50);
        await provider.saveSale(sale1);

        final sale2 = _createSale('1', '2024-01-15', 24, 0.50);
        await provider.saveSale(sale2);

        expect(provider.sales.length, 1);
        expect(provider.sales[0].quantitySold, 24);
      });

      test('sorts sales by date descending', () async {
        await provider.saveSale(_createSale('1', '2024-01-15', 12, 0.50));
        await provider.saveSale(_createSale('2', '2024-01-20', 24, 0.50));
        await provider.saveSale(_createSale('3', '2024-01-10', 6, 0.50));

        expect(provider.sales[0].date, '2024-01-20');
        expect(provider.sales[1].date, '2024-01-15');
        expect(provider.sales[2].date, '2024-01-10');
      });

      test('sets error and rethrows on repository failure', () async {
        mockRepository.shouldThrowOnSave = true;
        final sale = _createSale('1', '2024-01-15', 12, 0.50);

        expect(() => provider.saveSale(sale), throwsException);
        expect(provider.error, isNotNull);
      });
    });

    group('deleteSale', () {
      test('removes sale from list', () async {
        mockRepository.seedSales([
          _createSale('1', '2024-01-15', 12, 0.50),
          _createSale('2', '2024-01-16', 24, 0.50),
        ]);
        await provider.loadSales();

        await provider.deleteSale('1');

        expect(provider.sales.length, 1);
        expect(provider.sales[0].id, '2');
        expect(mockRepository.deleteCallCount, 1);
      });

      test('sets error and rethrows on repository failure', () async {
        mockRepository.shouldThrowOnDelete = true;

        expect(() => provider.deleteSale('1'), throwsException);
        expect(provider.error, isNotNull);
      });
    });

    group('statistics', () {
      test('calculates totalEggsSold correctly', () async {
        mockRepository.seedSales([
          _createSale('1', '2024-01-15', 12, 0.50),
          _createSale('2', '2024-01-16', 24, 0.50),
          _createSale('3', '2024-01-17', 6, 0.50),
        ]);
        await provider.loadSales();

        expect(provider.totalEggsSold, 42); // 12 + 24 + 6
      });

      test('calculates totalRevenue correctly', () async {
        mockRepository.seedSales([
          _createSale('1', '2024-01-15', 10, 0.50), // 5.0
          _createSale('2', '2024-01-16', 20, 0.25), // 5.0
        ]);
        await provider.loadSales();

        expect(provider.totalRevenue, closeTo(10.0, 0.01)); // 5.0 + 5.0
      });
    });

    group('getSalesInRange', () {
      test('returns sales within date range', () async {
        mockRepository.seedSales([
          _createSale('1', '2024-01-10', 12, 0.50),
          _createSale('2', '2024-01-15', 24, 0.50),
          _createSale('3', '2024-01-20', 6, 0.50),
          _createSale('4', '2024-01-25', 18, 0.50),
        ]);
        await provider.loadSales();

        final inRange = provider.getSalesInRange(
          DateTime(2024, 1, 12),
          DateTime(2024, 1, 22),
        );

        expect(inRange.length, 2);
        expect(inRange.any((s) => s.date == '2024-01-15'), true);
        expect(inRange.any((s) => s.date == '2024-01-20'), true);
      });

      test('returns empty list when no sales in range', () async {
        mockRepository.seedSales([
          _createSale('1', '2024-01-10', 12, 0.50),
        ]);
        await provider.loadSales();

        final inRange = provider.getSalesInRange(
          DateTime(2024, 2, 1),
          DateTime(2024, 2, 28),
        );

        expect(inRange, isEmpty);
      });
    });

    group('getSalesByCustomer', () {
      test('finds sales by customer name', () async {
        mockRepository.seedSales([
          _createSaleWithCustomer('1', '2024-01-15', 12, 0.50, 'Maria Silva'),
          _createSaleWithCustomer('2', '2024-01-16', 24, 0.50, 'João Santos'),
          _createSaleWithCustomer('3', '2024-01-17', 6, 0.50, 'Maria Costa'),
        ]);
        await provider.loadSales();

        final mariaSales = provider.getSalesByCustomer('Maria');

        expect(mariaSales.length, 2);
      });

      test('search is case insensitive', () async {
        mockRepository.seedSales([
          _createSaleWithCustomer('1', '2024-01-15', 12, 0.50, 'MARIA SILVA'),
        ]);
        await provider.loadSales();

        final results = provider.getSalesByCustomer('maria');

        expect(results.length, 1);
      });

      test('returns empty list when no match', () async {
        mockRepository.seedSales([
          _createSaleWithCustomer('1', '2024-01-15', 12, 0.50, 'Maria Silva'),
        ]);
        await provider.loadSales();

        final results = provider.getSalesByCustomer('Pedro');

        expect(results, isEmpty);
      });
    });

    group('getRecentSales', () {
      test('returns specified number of sales', () async {
        mockRepository.seedSales([
          _createSale('1', '2024-01-15', 12, 0.50),
          _createSale('2', '2024-01-16', 24, 0.50),
          _createSale('3', '2024-01-17', 6, 0.50),
          _createSale('4', '2024-01-18', 18, 0.50),
          _createSale('5', '2024-01-19', 30, 0.50),
        ]);
        await provider.loadSales();

        final recent = provider.getRecentSales(3);

        expect(recent.length, 3);
      });

      test('returns all when count exceeds total', () async {
        mockRepository.seedSales([
          _createSale('1', '2024-01-15', 12, 0.50),
          _createSale('2', '2024-01-16', 24, 0.50),
        ]);
        await provider.loadSales();

        final recent = provider.getRecentSales(10);

        expect(recent.length, 2);
      });
    });

    group('clearData', () {
      test('clears all sales', () async {
        mockRepository.seedSales([
          _createSale('1', '2024-01-15', 12, 0.50),
          _createSale('2', '2024-01-16', 24, 0.50),
        ]);
        await provider.loadSales();

        provider.clearData();

        expect(provider.sales, isEmpty);
        expect(provider.error, isNull);
        expect(provider.isLoading, false);
      });
    });

    group('sales immutability', () {
      test('sales getter returns unmodifiable list', () async {
        mockRepository.seedSales([
          _createSale('1', '2024-01-15', 12, 0.50),
        ]);
        await provider.loadSales();

        final sales = provider.sales;

        expect(
          () => sales.add(_createSale('2', '2024-01-16', 24, 0.50)),
          throwsUnsupportedError,
        );
      });
    });
  });
}

EggSale _createSale(String id, String date, int quantity, double pricePerEgg) {
  return EggSale(
    id: id,
    date: date,
    quantitySold: quantity,
    pricePerEgg: pricePerEgg,
    pricePerDozen: pricePerEgg * 12,
  );
}

EggSale _createSaleWithCustomer(
  String id,
  String date,
  int quantity,
  double pricePerEgg,
  String customerName,
) {
  return EggSale(
    id: id,
    date: date,
    quantitySold: quantity,
    pricePerEgg: pricePerEgg,
    pricePerDozen: pricePerEgg * 12,
    customerName: customerName,
  );
}
