// test/features/expenses/presentation/providers/expense_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/core.dart';
import 'package:hckegg_lite/features/expenses/domain/domain.dart';
import 'package:hckegg_lite/features/expenses/presentation/providers/expense_provider.dart';
import 'package:hckegg_lite/models/expense.dart';

// Mock Repository
class MockExpenseRepository implements ExpenseRepository {
  List<Expense> expensesToReturn = [];
  Failure? failureToReturn;

  @override
  Future<Result<List<Expense>>> getExpenses() async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(expensesToReturn);
  }

  @override
  Future<Result<Expense>> getExpenseById(String id) async {
    final expense = expensesToReturn.firstWhere((e) => e.id == id);
    return Result.success(expense);
  }

  @override
  Future<Result<List<Expense>>> getExpensesByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final filtered = expensesToReturn.where((e) {
      return e.date.compareTo(startDate) >= 0 && e.date.compareTo(endDate) <= 0;
    }).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<Expense>>> getExpensesByCategory(ExpenseCategory category) async {
    final filtered = expensesToReturn.where((e) => e.category == category).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<Expense>> createExpense(Expense expense) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(expense);
  }

  @override
  Future<Result<Expense>> updateExpense(Expense expense) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(expense);
  }

  @override
  Future<Result<void>> deleteExpense(String id) async {
    if (failureToReturn != null) return Result.fail(failureToReturn!);
    return Result.success(null);
  }

  @override
  Future<Result<double>> getTotalExpenses({
    required String startDate,
    required String endDate,
  }) async {
    final total = expensesToReturn
        .where((e) => e.date.compareTo(startDate) >= 0 && e.date.compareTo(endDate) <= 0)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
    return Result.success(total);
  }
}

void main() {
  late MockExpenseRepository mockRepository;
  late ExpenseProvider provider;

  setUp(() {
    mockRepository = MockExpenseRepository();

    provider = ExpenseProvider(
      getExpenses: GetExpenses(mockRepository),
      getExpensesByCategory: GetExpensesByCategory(mockRepository),
      createExpense: CreateExpense(mockRepository),
      updateExpense: UpdateExpense(mockRepository),
      deleteExpense: DeleteExpense(mockRepository),
    );
  });

  group('ExpenseProvider', () {
    group('initial state', () {
      test('starts with empty expenses list', () {
        expect(provider.expenses, isEmpty);
      });

      test('starts with initial state', () {
        expect(provider.state, ExpenseState.initial);
      });

      test('starts with no error', () {
        expect(provider.errorMessage, isNull);
      });

      test('totalExpenses is zero initially', () {
        expect(provider.totalExpenses, 0.0);
      });
    });

    group('loadExpenses', () {
      test('loads expenses successfully', () async {
        mockRepository.expensesToReturn = [
          _createExpense('1', '2024-01-15', 50.0, ExpenseCategory.feed),
          _createExpense('2', '2024-01-14', 30.0, ExpenseCategory.maintenance),
        ];

        await provider.loadExpenses();

        expect(provider.expenses.length, 2);
        expect(provider.state, ExpenseState.loaded);
      });

      test('sets error state on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Network error');

        await provider.loadExpenses();

        expect(provider.state, ExpenseState.error);
        expect(provider.errorMessage, 'Network error');
      });
    });

    group('saveExpense', () {
      test('creates new expense successfully', () async {
        final expense = _createExpense('1', '2024-01-15', 50.0, ExpenseCategory.feed);

        final result = await provider.saveExpense(expense);

        expect(result, true);
        expect(provider.expenses.length, 1);
      });

      test('updates existing expense', () async {
        mockRepository.expensesToReturn = [
          _createExpense('1', '2024-01-15', 50.0, ExpenseCategory.feed),
        ];
        await provider.loadExpenses();
        mockRepository.failureToReturn = null;

        final updatedExpense = _createExpense('1', '2024-01-15', 75.0, ExpenseCategory.feed);
        await provider.saveExpense(updatedExpense);

        expect(provider.expenses.length, 1);
        expect(provider.expenses[0].amount, 75.0);
      });

      test('returns false on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Save failed');
        final expense = _createExpense('1', '2024-01-15', 50.0, ExpenseCategory.feed);

        final result = await provider.saveExpense(expense);

        expect(result, false);
        expect(provider.state, ExpenseState.error);
      });
    });

    group('deleteExpense', () {
      test('removes expense from list', () async {
        mockRepository.expensesToReturn = [
          _createExpense('1', '2024-01-15', 50.0, ExpenseCategory.feed),
          _createExpense('2', '2024-01-14', 30.0, ExpenseCategory.maintenance),
        ];
        await provider.loadExpenses();
        mockRepository.failureToReturn = null;

        final result = await provider.deleteExpense('1');

        expect(result, true);
        expect(provider.expenses.length, 1);
        expect(provider.expenses[0].id, '2');
      });

      test('returns false on failure', () async {
        mockRepository.failureToReturn = ServerFailure(message: 'Delete failed');

        final result = await provider.deleteExpense('1');

        expect(result, false);
        expect(provider.state, ExpenseState.error);
      });
    });

    group('statistics', () {
      test('calculates totalExpenses correctly', () async {
        mockRepository.expensesToReturn = [
          _createExpense('1', '2024-01-15', 50.0, ExpenseCategory.feed),
          _createExpense('2', '2024-01-14', 30.0, ExpenseCategory.maintenance),
          _createExpense('3', '2024-01-13', 20.0, ExpenseCategory.utilities),
        ];
        await provider.loadExpenses();

        expect(provider.totalExpenses, closeTo(100.0, 0.01));
      });

      test('getExpensesByCategoryLocal filters correctly', () async {
        mockRepository.expensesToReturn = [
          _createExpense('1', '2024-01-15', 50.0, ExpenseCategory.feed),
          _createExpense('2', '2024-01-14', 30.0, ExpenseCategory.feed),
          _createExpense('3', '2024-01-13', 20.0, ExpenseCategory.maintenance),
        ];
        await provider.loadExpenses();

        final feedExpenses = provider.getExpensesByCategoryLocal(ExpenseCategory.feed);
        final maintenanceExpenses = provider.getExpensesByCategoryLocal(ExpenseCategory.maintenance);

        expect(feedExpenses.length, 2);
        expect(maintenanceExpenses.length, 1);
      });
    });

    group('search', () {
      test('returns all expenses when query is empty', () async {
        mockRepository.expensesToReturn = [
          _createExpense('1', '2024-01-15', 50.0, ExpenseCategory.feed),
          _createExpense('2', '2024-01-14', 30.0, ExpenseCategory.maintenance),
        ];
        await provider.loadExpenses();

        final results = provider.search('');

        expect(results.length, 2);
      });

      test('filters by description', () async {
        mockRepository.expensesToReturn = [
          _createExpense('1', '2024-01-15', 50.0, ExpenseCategory.feed, description: 'Chicken feed'),
          _createExpense('2', '2024-01-14', 30.0, ExpenseCategory.maintenance, description: 'Repairs'),
        ];
        await provider.loadExpenses();

        final results = provider.search('chicken');

        expect(results.length, 1);
        expect(results[0].description, 'Chicken feed');
      });
    });

    group('clearData', () {
      test('clears all expenses and resets state', () async {
        mockRepository.expensesToReturn = [
          _createExpense('1', '2024-01-15', 50.0, ExpenseCategory.feed),
        ];
        await provider.loadExpenses();
        expect(provider.expenses.length, 1);

        provider.clearData();

        expect(provider.expenses, isEmpty);
        expect(provider.state, ExpenseState.initial);
        expect(provider.errorMessage, isNull);
      });
    });
  });
}

Expense _createExpense(
  String id,
  String date,
  double amount,
  ExpenseCategory category, {
  String? description,
}) {
  return Expense(
    id: id,
    date: date,
    amount: amount,
    category: category,
    description: description ?? 'Test expense',
    createdAt: DateTime.now(),
  );
}
