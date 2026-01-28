// test/state/providers/expense_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/models/expense.dart';
import 'package:hckegg_lite/state/providers/expense_provider.dart';
import '../../mocks/mock_expense_repository.dart';

void main() {
  late MockExpenseRepository mockRepository;
  late ExpenseProvider provider;

  setUp(() {
    mockRepository = MockExpenseRepository();
    provider = ExpenseProvider(repository: mockRepository);
  });

  tearDown(() {
    mockRepository.clear();
  });

  group('ExpenseProvider', () {
    group('initial state', () {
      test('starts with empty expenses list', () {
        expect(provider.expenses, isEmpty);
      });

      test('starts with isLoading false', () {
        expect(provider.isLoading, false);
      });

      test('starts with no error', () {
        expect(provider.error, isNull);
      });

      test('totalExpenses is zero initially', () {
        expect(provider.totalExpenses, 0.0);
      });
    });

    group('loadExpenses', () {
      test('loads expenses from repository', () async {
        final testExpenses = [
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0),
          _createExpense('2', '2024-01-16', ExpenseCategory.maintenance, 25.0),
        ];
        mockRepository.seedExpenses(testExpenses);

        await provider.loadExpenses();

        expect(provider.expenses.length, 2);
        expect(mockRepository.getAllCallCount, 1);
      });

      test('sets error on failure', () async {
        mockRepository.shouldThrowOnLoad = true;

        await provider.loadExpenses();

        expect(provider.error, isNotNull);
        expect(provider.error, contains('Simulated load error'));
      });
    });

    group('saveExpense', () {
      test('adds new expense to list', () async {
        final expense = _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0);

        await provider.saveExpense(expense);

        expect(provider.expenses.length, 1);
        expect(provider.expenses[0].amount, 50.0);
        expect(mockRepository.saveCallCount, 1);
      });

      test('updates existing expense with same id', () async {
        final expense1 = _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0);
        await provider.saveExpense(expense1);

        final expense2 = _createExpense('1', '2024-01-15', ExpenseCategory.feed, 75.0);
        await provider.saveExpense(expense2);

        expect(provider.expenses.length, 1);
        expect(provider.expenses[0].amount, 75.0);
      });

      test('sets error and rethrows on repository failure', () async {
        mockRepository.shouldThrowOnSave = true;
        final expense = _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0);

        expect(() => provider.saveExpense(expense), throwsException);
        expect(provider.error, isNotNull);
      });
    });

    group('deleteExpense', () {
      test('removes expense from list', () async {
        mockRepository.seedExpenses([
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0),
          _createExpense('2', '2024-01-16', ExpenseCategory.maintenance, 25.0),
        ]);
        await provider.loadExpenses();

        await provider.deleteExpense('1');

        expect(provider.expenses.length, 1);
        expect(provider.expenses[0].id, '2');
        expect(mockRepository.deleteCallCount, 1);
      });

      test('sets error and rethrows on repository failure', () async {
        mockRepository.shouldThrowOnDelete = true;

        expect(() => provider.deleteExpense('1'), throwsException);
        expect(provider.error, isNotNull);
      });
    });

    group('totalExpenses', () {
      test('calculates total correctly', () async {
        mockRepository.seedExpenses([
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0),
          _createExpense('2', '2024-01-16', ExpenseCategory.maintenance, 25.0),
          _createExpense('3', '2024-01-17', ExpenseCategory.equipment, 100.0),
        ]);
        await provider.loadExpenses();

        expect(provider.totalExpenses, closeTo(175.0, 0.01)); // 50 + 25 + 100
      });

      test('handles decimal amounts', () async {
        mockRepository.seedExpenses([
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.50),
          _createExpense('2', '2024-01-16', ExpenseCategory.maintenance, 25.25),
        ]);
        await provider.loadExpenses();

        expect(provider.totalExpenses, closeTo(75.75, 0.01));
      });
    });

    group('getExpensesByCategory', () {
      test('returns expenses of specified category', () async {
        mockRepository.seedExpenses([
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0),
          _createExpense('2', '2024-01-16', ExpenseCategory.maintenance, 25.0),
          _createExpense('3', '2024-01-17', ExpenseCategory.feed, 60.0),
          _createExpense('4', '2024-01-18', ExpenseCategory.equipment, 100.0),
        ]);
        await provider.loadExpenses();

        final feedExpenses = provider.getExpensesByCategory(ExpenseCategory.feed);

        expect(feedExpenses.length, 2);
        expect(feedExpenses.every((e) => e.category == ExpenseCategory.feed), true);
      });

      test('returns empty list when no expenses in category', () async {
        mockRepository.seedExpenses([
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0),
        ]);
        await provider.loadExpenses();

        final equipmentExpenses = provider.getExpensesByCategory(ExpenseCategory.equipment);

        expect(equipmentExpenses, isEmpty);
      });

      test('works with all categories', () async {
        mockRepository.seedExpenses([
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0),
          _createExpense('2', '2024-01-16', ExpenseCategory.maintenance, 25.0),
          _createExpense('3', '2024-01-17', ExpenseCategory.equipment, 100.0),
          _createExpense('4', '2024-01-18', ExpenseCategory.utilities, 30.0),
          _createExpense('5', '2024-01-19', ExpenseCategory.other, 15.0),
        ]);
        await provider.loadExpenses();

        expect(provider.getExpensesByCategory(ExpenseCategory.feed).length, 1);
        expect(provider.getExpensesByCategory(ExpenseCategory.maintenance).length, 1);
        expect(provider.getExpensesByCategory(ExpenseCategory.equipment).length, 1);
        expect(provider.getExpensesByCategory(ExpenseCategory.utilities).length, 1);
        expect(provider.getExpensesByCategory(ExpenseCategory.other).length, 1);
      });
    });

    group('clearData', () {
      test('clears all expenses', () async {
        mockRepository.seedExpenses([
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0),
          _createExpense('2', '2024-01-16', ExpenseCategory.maintenance, 25.0),
        ]);
        await provider.loadExpenses();

        provider.clearData();

        expect(provider.expenses, isEmpty);
        expect(provider.error, isNull);
        expect(provider.isLoading, false);
      });
    });

    group('expenses immutability', () {
      test('expenses getter returns unmodifiable list', () async {
        mockRepository.seedExpenses([
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 50.0),
        ]);
        await provider.loadExpenses();

        final expenses = provider.expenses;

        expect(
          () => expenses.add(_createExpense('2', '2024-01-16', ExpenseCategory.maintenance, 25.0)),
          throwsUnsupportedError,
        );
      });
    });

    group('edge cases', () {
      test('handles zero amount expenses', () async {
        mockRepository.seedExpenses([
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 0.0),
        ]);
        await provider.loadExpenses();

        expect(provider.totalExpenses, 0.0);
      });

      test('handles very large amounts', () async {
        mockRepository.seedExpenses([
          _createExpense('1', '2024-01-15', ExpenseCategory.feed, 999999.99),
        ]);
        await provider.loadExpenses();

        expect(provider.totalExpenses, closeTo(999999.99, 0.01));
      });
    });
  });
}

Expense _createExpense(
  String id,
  String date,
  ExpenseCategory category,
  double amount,
) {
  return Expense(
    id: id,
    date: date,
    category: category,
    amount: amount,
    description: 'Test expense',
    createdAt: DateTime.now(),
  );
}
