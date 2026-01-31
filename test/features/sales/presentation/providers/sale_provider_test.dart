// test/features/sales/presentation/providers/sale_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/core.dart';
import 'package:hckegg_lite/features/sales/domain/domain.dart';
import 'package:hckegg_lite/features/sales/presentation/providers/sale_provider.dart';
import 'package:hckegg_lite/models/egg_sale.dart';

// Mock Repository
class MockSaleRepository implements SaleRepository {
  List<EggSale> salesToReturn = [];
  Failure? failureToReturn;

  @override
  Future<Result<List<EggSale>>> getSales() async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(salesToReturn);
  }

  @override
  Future<Result<EggSale>> getSaleById(String id) async {
    final sale = salesToReturn.firstWhere((s) => s.id == id);
    return Result.success(sale);
  }

  @override
  Future<Result<List<EggSale>>> getSalesByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final filtered = salesToReturn.where((s) {
      return s.date.compareTo(startDate) >= 0 && s.date.compareTo(endDate) <= 0;
    }).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<EggSale>>> getPendingPayments() async {
    final filtered = salesToReturn.where((s) => s.paymentStatus == PaymentStatus.pending).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<EggSale>>> getLostSales() async {
    final filtered = salesToReturn.where((s) => s.isLost).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<EggSale>> createSale(EggSale sale) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(sale);
  }

  @override
  Future<Result<EggSale>> updateSale(EggSale sale) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(sale);
  }

  @override
  Future<Result<void>> deleteSale(String id) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(null);
  }

  @override
  Future<Result<void>> markAsPaid(String id, String paymentDate) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(null);
  }

  @override
  Future<Result<void>> markAsLost(String id) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(null);
  }
}

void main() {
  late MockSaleRepository mockRepository;
  late SaleProvider provider;

  setUp(() {
    mockRepository = MockSaleRepository();

    provider = SaleProvider(
      getSales: GetSales(mockRepository),
      getSaleById: GetSaleById(mockRepository),
      getSalesInRange: GetSalesInRange(mockRepository),
      createSale: CreateSale(mockRepository),
      updateSale: UpdateSale(mockRepository),
      deleteSale: DeleteSale(mockRepository),
    );
  });

  group('SaleProvider', () {
    group('initial state', () {
      test('starts with empty sales list', () {
        expect(provider.sales, isEmpty);
      });

      test('starts with initial state', () {
        expect(provider.state, SaleState.initial);
      });

      test('starts with no error', () {
        expect(provider.errorMessage, isNull);
      });

      test('statistics are zero initially', () {
        expect(provider.totalRevenue, 0.0);
        expect(provider.totalEggsSold, 0);
      });
    });

    group('loadSales', () {
      test('loads sales successfully', () async {
        mockRepository.salesToReturn = [
          _createSale('1', '2024-01-15', 30, 0.50),
          _createSale('2', '2024-01-14', 24, 0.50),
        ];

        await provider.loadSales();

        expect(provider.sales.length, 2);
        expect(provider.state, SaleState.loaded);
      });

      test('sets error state on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Network error');

        await provider.loadSales();

        expect(provider.state, SaleState.error);
        expect(provider.errorMessage, 'Network error');
      });
    });

    group('saveSale', () {
      test('creates new sale successfully', () async {
        final sale = _createSale('1', '2024-01-15', 30, 0.50);

        final result = await provider.saveSale(sale);

        expect(result, true);
        expect(provider.sales.length, 1);
      });

      test('updates existing sale', () async {
        mockRepository.salesToReturn = [
          _createSale('1', '2024-01-15', 30, 0.50),
        ];
        await provider.loadSales();
        mockRepository.failureToReturn = null;

        final updatedSale = _createSale('1', '2024-01-15', 36, 0.50);
        await provider.saveSale(updatedSale);

        expect(provider.sales.length, 1);
        expect(provider.sales[0].quantitySold, 36);
      });

      test('returns false on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Save failed');
        final sale = _createSale('1', '2024-01-15', 30, 0.50);

        final result = await provider.saveSale(sale);

        expect(result, false);
        expect(provider.state, SaleState.error);
      });
    });

    group('deleteSale', () {
      test('removes sale from list', () async {
        mockRepository.salesToReturn = [
          _createSale('1', '2024-01-15', 30, 0.50),
          _createSale('2', '2024-01-14', 24, 0.50),
        ];
        await provider.loadSales();
        mockRepository.failureToReturn = null;

        final result = await provider.deleteSale('1');

        expect(result, true);
        expect(provider.sales.length, 1);
        expect(provider.sales[0].id, '2');
      });

      test('returns false on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Delete failed');

        final result = await provider.deleteSale('1');

        expect(result, false);
        expect(provider.state, SaleState.error);
      });
    });

    group('statistics', () {
      test('calculates totalRevenue correctly', () async {
        mockRepository.salesToReturn = [
          _createSale('1', '2024-01-15', 30, 0.50), // 30 * 0.50 = 15.0
          _createSale('2', '2024-01-14', 24, 0.50), // 24 * 0.50 = 12.0
        ];
        await provider.loadSales();

        expect(provider.totalRevenue, closeTo(27.0, 0.01));
      });

      test('calculates totalEggsSold correctly', () async {
        mockRepository.salesToReturn = [
          _createSale('1', '2024-01-15', 30, 0.50),
          _createSale('2', '2024-01-14', 24, 0.50),
        ];
        await provider.loadSales();

        expect(provider.totalEggsSold, 54);
      });
    });

    group('search', () {
      test('returns all sales when query is empty', () async {
        mockRepository.salesToReturn = [
          _createSale('1', '2024-01-15', 30, 0.50),
          _createSale('2', '2024-01-14', 24, 0.50),
        ];
        await provider.loadSales();

        final results = provider.search('');

        expect(results.length, 2);
      });

      test('filters by customer name', () async {
        mockRepository.salesToReturn = [
          _createSale('1', '2024-01-15', 30, 0.50, customer: 'John'),
          _createSale('2', '2024-01-14', 24, 0.50, customer: 'Maria'),
        ];
        await provider.loadSales();

        final results = provider.search('john');

        expect(results.length, 1);
        expect(results[0].customerName, 'John');
      });
    });

    group('clearData', () {
      test('clears all sales and resets state', () async {
        mockRepository.salesToReturn = [
          _createSale('1', '2024-01-15', 30, 0.50),
        ];
        await provider.loadSales();
        expect(provider.sales.length, 1);

        provider.clearData();

        expect(provider.sales, isEmpty);
        expect(provider.state, SaleState.initial);
        expect(provider.errorMessage, isNull);
      });
    });
  });
}

EggSale _createSale(
  String id,
  String date,
  int quantity,
  double pricePerEgg, {
  String? customer,
}) {
  return EggSale(
    id: id,
    date: date,
    quantitySold: quantity,
    pricePerEgg: pricePerEgg,
    pricePerDozen: pricePerEgg * 12,
    customerName: customer,
  );
}
