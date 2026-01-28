// test/state/providers/egg_record_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/models/week_stats.dart';
import 'package:hckegg_lite/models/daily_egg_record.dart';
import 'package:hckegg_lite/models/egg_sale.dart';
import 'package:hckegg_lite/models/expense.dart';
import 'package:hckegg_lite/state/providers/egg_record_provider.dart';
import '../../mocks/mock_egg_repository.dart';

void main() {
  late MockEggRepository mockRepository;
  late EggRecordProvider provider;

  setUp(() {
    mockRepository = MockEggRepository();
    provider = EggRecordProvider(repository: mockRepository);
  });

  tearDown(() {
    mockRepository.clear();
  });

  group('EggRecordProvider', () {
    group('initial state', () {
      test('starts with empty records list', () {
        expect(provider.records, isEmpty);
      });

      test('starts with isLoading false', () {
        expect(provider.isLoading, false);
      });

      test('starts with no error', () {
        expect(provider.error, isNull);
      });

      test('total stats are zero initially', () {
        expect(provider.totalEggsCollected, 0);
        expect(provider.totalEggsConsumed, 0);
        expect(provider.totalEggsRemaining, 0);
        expect(provider.recordCount, 0);
      });
    });

    group('loadRecords', () {
      test('loads records from repository', () async {
        final testRecords = [
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 12),
        ];
        mockRepository.seedRecords(testRecords);

        final success = await provider.loadRecords();

        expect(success, true);
        expect(provider.records.length, 2);
        expect(mockRepository.getAllCallCount, 1);
      });

      test('sorts records by date descending', () async {
        final testRecords = [
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-01-20', eggsCollected: 12),
          DailyEggRecord(id: '3', date: '2024-01-10', eggsCollected: 8),
        ];
        mockRepository.seedRecords(testRecords);

        await provider.loadRecords();

        expect(provider.records[0].date, '2024-01-20');
        expect(provider.records[1].date, '2024-01-15');
        expect(provider.records[2].date, '2024-01-10');
      });

      test('returns false and sets error on failure', () async {
        mockRepository.shouldThrowOnLoad = true;

        final success = await provider.loadRecords();

        expect(success, false);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Simulated load error'));
      });

      test('clears previous error on successful load', () async {
        mockRepository.shouldThrowOnLoad = true;
        await provider.loadRecords();
        expect(provider.error, isNotNull);

        mockRepository.shouldThrowOnLoad = false;
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
        ]);

        await provider.loadRecords();
        expect(provider.error, isNull);
      });
    });

    group('getRecordByDate', () {
      test('returns record when found', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 12),
        ]);
        await provider.loadRecords();

        final record = provider.getRecordByDate('2024-01-15');

        expect(record, isNotNull);
        expect(record!.eggsCollected, 10);
      });

      test('returns null when not found', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
        ]);
        await provider.loadRecords();

        final record = provider.getRecordByDate('2024-01-20');

        expect(record, isNull);
      });

      test('returns null for empty date string', () {
        final record = provider.getRecordByDate('');
        expect(record, isNull);
      });
    });

    group('saveRecord', () {
      test('adds new record to list', () async {
        final record = DailyEggRecord(
          id: '1',
          date: '2024-01-15',
          eggsCollected: 10,
        );

        await provider.saveRecord(record);

        expect(provider.records.length, 1);
        expect(provider.records[0].eggsCollected, 10);
        expect(mockRepository.saveCallCount, 1);
      });

      test('updates existing record with same date', () async {
        final record1 = DailyEggRecord(
          id: '1',
          date: '2024-01-15',
          eggsCollected: 10,
        );
        await provider.saveRecord(record1);

        final record2 = DailyEggRecord(
          id: '2',
          date: '2024-01-15',
          eggsCollected: 20,
        );
        await provider.saveRecord(record2);

        expect(provider.records.length, 1);
        expect(provider.records[0].eggsCollected, 20);
      });

      test('throws ArgumentError for negative eggsCollected', () async {
        final record = DailyEggRecord(
          id: '1',
          date: '2024-01-15',
          eggsCollected: -5,
        );

        expect(
          () => provider.saveRecord(record),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative eggsConsumed', () async {
        final record = DailyEggRecord(
          id: '1',
          date: '2024-01-15',
          eggsCollected: 10,
          eggsConsumed: -5,
        );

        expect(
          () => provider.saveRecord(record),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for empty date', () async {
        final record = DailyEggRecord(
          id: '1',
          date: '',
          eggsCollected: 10,
        );

        expect(
          () => provider.saveRecord(record),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('sets error and rethrows on repository failure', () async {
        mockRepository.shouldThrowOnSave = true;
        final record = DailyEggRecord(
          id: '1',
          date: '2024-01-15',
          eggsCollected: 10,
        );

        expect(
          () => provider.saveRecord(record),
          throwsException,
        );
        expect(provider.error, isNotNull);
      });
    });

    group('deleteRecord', () {
      test('removes record from list', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 12),
        ]);
        await provider.loadRecords();

        await provider.deleteRecord('2024-01-15');

        expect(provider.records.length, 1);
        expect(provider.records[0].date, '2024-01-16');
        expect(mockRepository.deleteCallCount, 1);
      });

      test('throws ArgumentError for empty date', () {
        expect(
          () => provider.deleteRecord(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('sets error and rethrows on repository failure', () async {
        mockRepository.shouldThrowOnDelete = true;

        expect(
          () => provider.deleteRecord('2024-01-15'),
          throwsException,
        );
        expect(provider.error, isNotNull);
      });
    });

    group('statistics', () {
      test('calculates totalEggsCollected correctly', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 15),
          DailyEggRecord(id: '3', date: '2024-01-17', eggsCollected: 20),
        ]);
        await provider.loadRecords();

        expect(provider.totalEggsCollected, 45);
      });

      test('calculates totalEggsConsumed correctly', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10, eggsConsumed: 2),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 15, eggsConsumed: 3),
          DailyEggRecord(id: '3', date: '2024-01-17', eggsCollected: 20, eggsConsumed: 5),
        ]);
        await provider.loadRecords();

        expect(provider.totalEggsConsumed, 10);
      });

      test('calculates totalEggsRemaining correctly', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10, eggsConsumed: 2),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 15, eggsConsumed: 3),
        ]);
        await provider.loadRecords();

        // (10-2) + (15-3) = 8 + 12 = 20
        expect(provider.totalEggsRemaining, 20);
      });
    });

    group('getRecentRecords', () {
      test('returns specified number of records', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 12),
          DailyEggRecord(id: '3', date: '2024-01-17', eggsCollected: 14),
          DailyEggRecord(id: '4', date: '2024-01-18', eggsCollected: 16),
          DailyEggRecord(id: '5', date: '2024-01-19', eggsCollected: 18),
        ]);
        await provider.loadRecords();

        final recent = provider.getRecentRecords(3);

        expect(recent.length, 3);
        // Should be most recent first (already sorted by loadRecords)
        expect(recent[0].date, '2024-01-19');
        expect(recent[1].date, '2024-01-18');
        expect(recent[2].date, '2024-01-17');
      });

      test('returns empty list for count <= 0', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
        ]);
        await provider.loadRecords();

        expect(provider.getRecentRecords(0), isEmpty);
        expect(provider.getRecentRecords(-1), isEmpty);
      });

      test('returns all records when count exceeds total', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 12),
        ]);
        await provider.loadRecords();

        final recent = provider.getRecentRecords(10);

        expect(recent.length, 2);
      });
    });

    group('search', () {
      test('finds records by date', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-02-15', eggsCollected: 12),
          DailyEggRecord(id: '3', date: '2024-01-20', eggsCollected: 14),
        ]);
        await provider.loadRecords();

        final results = provider.search('01-15');

        expect(results.length, 1);
        expect(results[0].date, '2024-01-15');
      });

      test('finds records by notes', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10, notes: 'Good day'),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 12, notes: 'Bad weather'),
          DailyEggRecord(id: '3', date: '2024-01-17', eggsCollected: 14, notes: 'Very good production'),
        ]);
        await provider.loadRecords();

        final results = provider.search('good');

        expect(results.length, 2);
      });

      test('returns all records for empty query', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 12),
        ]);
        await provider.loadRecords();

        final results = provider.search('');

        expect(results.length, 2);
      });
    });

    group('getWeekStats', () {
      test('calculates weekly stats correctly', () async {
        // Set up records for current week
        final now = DateTime.now();
        final monday = now.subtract(Duration(days: now.weekday - 1));

        mockRepository.seedRecords([
          DailyEggRecord(
            id: '1',
            date: _toIsoDate(monday),
            eggsCollected: 10,
            eggsConsumed: 2,
          ),
          DailyEggRecord(
            id: '2',
            date: _toIsoDate(monday.add(const Duration(days: 1))),
            eggsCollected: 15,
            eggsConsumed: 3,
          ),
        ]);
        await provider.loadRecords();

        final sales = [
          EggSale(
            id: 's1',
            date: _toIsoDate(monday),
            quantitySold: 5,
            pricePerEgg: 0.50,
            pricePerDozen: 5.0,
          ),
        ];

        final expenses = [
          Expense(
            id: 'e1',
            date: _toIsoDate(monday),
            category: ExpenseCategory.feed,
            amount: 10.0,
            description: 'Feed',
            createdAt: now,
          ),
        ];

        final stats = provider.getWeekStats(sales: sales, expenses: expenses);

        expect(stats.collected, 25); // 10 + 15
        expect(stats.consumed, 5); // 2 + 3
        expect(stats.sold, 5);
        expect(stats.revenue, 2.5); // 5 * 0.50
        expect(stats.expenses, 10.0);
        expect(stats.netProfit, -7.5); // 2.5 - 10.0
      });

      test('returns empty stats when no records in week', () async {
        // Records from last month
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2023-01-15', eggsCollected: 10),
        ]);
        await provider.loadRecords();

        final stats = provider.getWeekStats(sales: [], expenses: []);

        expect(stats.collected, 0);
        expect(stats.consumed, 0);
        expect(stats.sold, 0);
        expect(stats.revenue, 0.0);
        expect(stats.expenses, 0.0);
        expect(stats.netProfit, 0.0);
      });

      test('returns WeekStats type', () async {
        await provider.loadRecords();
        final stats = provider.getWeekStats(sales: [], expenses: []);

        expect(stats, isA<WeekStats>());
      });
    });

    group('clearData', () {
      test('clears all records', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
          DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 12),
        ]);
        await provider.loadRecords();
        expect(provider.records.length, 2);

        provider.clearData();

        expect(provider.records, isEmpty);
        expect(provider.error, isNull);
        expect(provider.isLoading, false);
      });
    });

    group('clearError', () {
      test('clears error state', () async {
        mockRepository.shouldThrowOnLoad = true;
        await provider.loadRecords();
        expect(provider.error, isNotNull);

        provider.clearError();

        expect(provider.error, isNull);
      });
    });

    group('records immutability', () {
      test('records getter returns unmodifiable list', () async {
        mockRepository.seedRecords([
          DailyEggRecord(id: '1', date: '2024-01-15', eggsCollected: 10),
        ]);
        await provider.loadRecords();

        final records = provider.records;

        expect(
          () => records.add(DailyEggRecord(id: '2', date: '2024-01-16', eggsCollected: 5)),
          throwsUnsupportedError,
        );
      });
    });
  });
}

String _toIsoDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
