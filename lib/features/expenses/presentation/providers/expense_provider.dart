import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// State for the expenses feature
enum ExpenseState { initial, loading, loaded, error }

/// Provider for expenses following clean architecture
class ExpenseProvider extends ChangeNotifier {
  final GetExpenses _getExpenses;
  final GetExpensesByCategory _getExpensesByCategory;
  final CreateExpense _createExpense;
  final UpdateExpense _updateExpense;
  final DeleteExpense _deleteExpense;

  ExpenseProvider({
    required GetExpenses getExpenses,
    required GetExpensesByCategory getExpensesByCategory,
    required CreateExpense createExpense,
    required UpdateExpense updateExpense,
    required DeleteExpense deleteExpense,
  })  : _getExpenses = getExpenses,
        _getExpensesByCategory = getExpensesByCategory,
        _createExpense = createExpense,
        _updateExpense = updateExpense,
        _deleteExpense = deleteExpense;

  // State
  ExpenseState _state = ExpenseState.initial;
  ExpenseState get state => _state;

  List<Expense> _expenses = [];
  List<Expense> get expenses => List.unmodifiable(_expenses);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Backward compatibility

  bool get isLoading => _state == ExpenseState.loading;
  bool get hasError => _state == ExpenseState.error;

  // Cached statistics
  double? _cachedTotalExpenses;

  double get totalExpenses {
    _cachedTotalExpenses ??= _expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    return _cachedTotalExpenses!;
  }

  void _invalidateCache() {
    _cachedTotalExpenses = null;
  }

  /// Load all expenses
  Future<void> loadExpenses() async {
    _state = ExpenseState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _getExpenses(const NoParams());

    result.fold(
      onSuccess: (data) {
        _expenses = data;
        _invalidateCache();
        _state = ExpenseState.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = ExpenseState.error;
      },
    );

    notifyListeners();
  }

  /// Get expenses by category
  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    final result = await _getExpensesByCategory(
      GetByCategoryParams(category: category),
    );
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (_) => [],
    );
  }

  /// Get expenses by category (local filtering)
  List<Expense> getExpensesByCategoryLocal(ExpenseCategory category) {
    return _expenses.where((e) => e.category == category).toList();
  }

  /// Search expenses by description, notes, category, or amount
  List<Expense> search(String query) {
    if (query.isEmpty) return _expenses;
    final q = query.toLowerCase();
    return _expenses.where((e) {
      final descMatch = e.description.toLowerCase().contains(q);
      final notesMatch = e.notes?.toLowerCase().contains(q) ?? false;
      final categoryMatch = e.category.name.toLowerCase().contains(q);
      final dateMatch = e.date.toLowerCase().contains(q);
      final amountMatch = e.amount.toStringAsFixed(2).contains(q);
      return descMatch || notesMatch || categoryMatch || dateMatch || amountMatch;
    }).toList();
  }

  /// Save an expense (create or update)
  Future<bool> saveExpense(Expense expense) async {
    _state = ExpenseState.loading;
    notifyListeners();

    final Result<Expense> result;

    if (expense.id.isEmpty || !_expenses.any((e) => e.id == expense.id)) {
      result = await _createExpense(CreateExpenseParams(expense: expense));
    } else {
      result = await _updateExpense(UpdateExpenseParams(expense: expense));
    }

    final success = result.fold(
      onSuccess: (savedExpense) {
        final index = _expenses.indexWhere((e) => e.id == savedExpense.id);
        if (index >= 0) {
          _expenses[index] = savedExpense;
        } else {
          _expenses.insert(0, savedExpense);
        }
        _expenses.sort((a, b) => b.date.compareTo(a.date));
        _invalidateCache();
        _state = ExpenseState.loaded;
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = ExpenseState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
  }

  /// Delete an expense
  Future<bool> deleteExpense(String id) async {
    _state = ExpenseState.loading;
    notifyListeners();

    final result = await _deleteExpense(DeleteExpenseParams(id: id));

    final success = result.fold(
      onSuccess: (_) {
        _expenses.removeWhere((e) => e.id == id);
        _invalidateCache();
        _state = ExpenseState.loaded;
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = ExpenseState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data (used on logout)
  void clearData() {
    _expenses = [];
    _errorMessage = null;
    _state = ExpenseState.initial;
    _invalidateCache();
    notifyListeners();
  }
}
