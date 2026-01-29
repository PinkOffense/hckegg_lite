// test/services/provider_clear_data_test.dart
//
// Tests to verify that all providers properly clear their data on logout.
// This is critical for security - no user data should persist after logout.

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/models/daily_egg_record.dart';
import 'package:hckegg_lite/models/expense.dart';
import 'package:hckegg_lite/models/egg_sale.dart';
import 'package:hckegg_lite/models/vet_record.dart';
import 'package:hckegg_lite/models/feed_stock.dart';
import 'package:hckegg_lite/state/providers/egg_record_provider.dart';
import 'package:hckegg_lite/state/providers/expense_provider.dart';
import 'package:hckegg_lite/state/providers/sale_provider.dart';
import 'package:hckegg_lite/state/providers/vet_record_provider.dart';
import 'package:hckegg_lite/state/providers/feed_stock_provider.dart';
import '../mocks/mock_egg_repository.dart';
import '../mocks/mock_expense_repository.dart';
import '../mocks/mock_sale_repository.dart';
import '../mocks/mock_vet_repository.dart';
import '../mocks/mock_feed_repository.dart';

void main() {
  group('Provider clearData for Logout', () {
    group('EggRecordProvider', () {
      late MockEggRepository mockRepository;
      late EggRecordProvider provider;

      setUp(() {
        mockRepository = MockEggRepository();
        provider = EggRecordProvider(repository: mockRepository);
      });

      test('clearData removes all records', () async {
        // Add some records
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 12),
        ]);
        await provider.loadRecords();
        expect(provider.records.length, 2);

        // Clear data
        provider.clearData();

        // Verify all data is cleared
        expect(provider.records, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('clearData resets statistics to zero', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10, eggsConsumed: 2),
        ]);
        await provider.loadRecords();
        expect(provider.totalEggsCollected, 10);

        provider.clearData();

        expect(provider.totalEggsCollected, 0);
        expect(provider.totalEggsConsumed, 0);
        expect(provider.totalEggsRemaining, 0);
      });
    });

    group('ExpenseProvider', () {
      late MockExpenseRepository mockRepository;
      late ExpenseProvider provider;

      setUp(() {
        mockRepository = MockExpenseRepository();
        provider = ExpenseProvider(repository: mockRepository);
      });

      test('clearData removes all expenses', () async {
        mockRepository.seedExpenses([
          Expense(
            id: '1',
            date: '2024-01-15',
            category: ExpenseCategory.feed,
            amount: 50.0,
            description: 'Feed',
            createdAt: DateTime.now(),
          ),
        ]);
        await provider.loadExpenses();
        expect(provider.expenses.length, 1);

        provider.clearData();

        expect(provider.expenses, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });
    });

    group('SaleProvider', () {
      late MockSaleRepository mockRepository;
      late SaleProvider provider;

      setUp(() {
        mockRepository = MockSaleRepository();
        provider = SaleProvider(repository: mockRepository);
      });

      test('clearData removes all sales', () async {
        mockRepository.seedSales([
          EggSale(
            id: '1',
            date: '2024-01-15',
            quantitySold: 12,
            pricePerEgg: 0.50,
            pricePerDozen: 5.0,
          ),
        ]);
        await provider.loadSales();
        expect(provider.sales.length, 1);

        provider.clearData();

        expect(provider.sales, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });
    });

    group('VetRecordProvider', () {
      late MockVetRepository mockRepository;
      late VetRecordProvider provider;

      setUp(() {
        mockRepository = MockVetRepository();
        provider = VetRecordProvider(repository: mockRepository);
      });

      test('clearData removes all vet records', () async {
        mockRepository.seedRecords([
          VetRecord(
            id: '1',
            date: '2024-01-15',
            type: VetRecordType.vaccination,
            description: 'Annual vaccination',
            cost: 25.0,
          ),
        ]);
        await provider.loadVetRecords();
        expect(provider.getVetRecords().length, 1);

        provider.clearData();

        expect(provider.getVetRecords(), isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('clearData resets vet costs', () async {
        mockRepository.seedRecords([
          VetRecord(
            id: '1',
            date: '2024-01-15',
            type: VetRecordType.treatment,
            description: 'Treatment',
            cost: 100.0,
          ),
        ]);
        await provider.loadVetRecords();
        expect(provider.totalVetCosts, 100.0);

        provider.clearData();

        expect(provider.totalVetCosts, 0.0);
      });
    });

    group('FeedStockProvider', () {
      late MockFeedRepository mockRepository;
      late FeedStockProvider provider;

      setUp(() {
        mockRepository = MockFeedRepository();
        provider = FeedStockProvider(repository: mockRepository);
      });

      test('clearData removes all feed stocks', () async {
        final now = DateTime.now();
        mockRepository.seedStocks([
          FeedStock(
            id: '1',
            type: FeedType.layer,
            currentQuantityKg: 50.0,
            minimumQuantityKg: 10.0,
            lastUpdated: now,
            createdAt: now,
          ),
        ]);
        await provider.loadFeedStocks();
        expect(provider.feedStocks.length, 1);

        provider.clearData();

        expect(provider.feedStocks, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('clearData resets stock counts', () async {
        final now = DateTime.now();
        mockRepository.seedStocks([
          FeedStock(
            id: '1',
            type: FeedType.layer,
            currentQuantityKg: 50.0,
            minimumQuantityKg: 10.0,
            lastUpdated: now,
            createdAt: now,
          ),
        ]);
        await provider.loadFeedStocks();
        expect(provider.totalFeedStock, 50.0);

        provider.clearData();

        expect(provider.totalFeedStock, 0.0);
        expect(provider.lowStockCount, 0);
      });
    });

    group('All providers clear independently', () {
      test('clearing one provider does not affect others', () async {
        final eggRepo = MockEggRepository();
        final expenseRepo = MockExpenseRepository();

        final eggProvider = EggRecordProvider(repository: eggRepo);
        final expenseProvider = ExpenseProvider(repository: expenseRepo);

        // Seed data
        eggRepo.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
        ]);
        expenseRepo.seedExpenses([
          Expense(
            id: '1',
            date: '2024-01-15',
            category: ExpenseCategory.feed,
            amount: 50.0,
            description: 'Feed',
            createdAt: DateTime.now(),
          ),
        ]);

        await eggProvider.loadRecords();
        await expenseProvider.loadExpenses();

        expect(eggProvider.records.length, 1);
        expect(expenseProvider.expenses.length, 1);

        // Clear only egg provider
        eggProvider.clearData();

        // Egg provider should be empty
        expect(eggProvider.records, isEmpty);
        // Expense provider should still have data
        expect(expenseProvider.expenses.length, 1);
      });
    });
  });
}
