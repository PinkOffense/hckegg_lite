// test/mocks/mock_expense_repository.dart

import 'package:hckegg_lite/domain/repositories/expense_repository.dart';
import 'package:hckegg_lite/models/expense.dart';

/// Mock implementation of ExpenseRepository for testing
class MockExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [];

  // Control flags for simulating errors
  bool shouldThrowOnSave = false;
  bool shouldThrowOnDelete = false;
  bool shouldThrowOnLoad = false;

  // Track method calls
  int saveCallCount = 0;
  int deleteCallCount = 0;
  int getAllCallCount = 0;

  void seedExpenses(List<Expense> expenses) {
    _expenses.clear();
    _expenses.addAll(expenses);
  }

  void clear() {
    _expenses.clear();
    saveCallCount = 0;
    deleteCallCount = 0;
    getAllCallCount = 0;
  }

  @override
  Future<List<Expense>> getAll() async {
    getAllCallCount++;
    if (shouldThrowOnLoad) {
      throw Exception('Simulated load error');
    }
    return List.from(_expenses);
  }

  @override
  Future<Expense?> getById(String id) async {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async {
    final startStr = _toIsoDate(start);
    final endStr = _toIsoDate(end);
    return _expenses.where((e) {
      return e.date.compareTo(startStr) >= 0 && e.date.compareTo(endStr) <= 0;
    }).toList();
  }

  @override
  Future<List<Expense>> getByCategory(ExpenseCategory category) async {
    return _expenses.where((e) => e.category == category).toList();
  }

  @override
  Future<Expense> save(Expense expense) async {
    saveCallCount++;
    if (shouldThrowOnSave) {
      throw Exception('Simulated save error');
    }

    final existingIndex = _expenses.indexWhere((e) => e.id == expense.id);
    if (existingIndex != -1) {
      _expenses[existingIndex] = expense;
    } else {
      _expenses.add(expense);
    }
    return expense;
  }

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    if (shouldThrowOnDelete) {
      throw Exception('Simulated delete error');
    }
    _expenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<Map<ExpenseCategory, double>> getTotalsByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Map<ExpenseCategory, double> totals = {};
    for (final expense in _expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0.0) + expense.amount;
    }
    return totals;
  }

  @override
  Future<double> getTotalExpenses({DateTime? startDate, DateTime? endDate}) async {
    return _expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  String _toIsoDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
