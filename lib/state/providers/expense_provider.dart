// lib/state/providers/expense_provider.dart

import 'package:flutter/material.dart';
import '../../core/di/repository_provider.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../models/expense.dart';

/// Provider para gestão de despesas
class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository = RepositoryProvider.instance.expenseRepository;

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Estatísticas
  double get totalExpenses => _expenses.fold<double>(0.0, (sum, e) => sum + e.amount);

  /// Carregar todas as despesas
  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Guardar uma despesa
  Future<void> saveExpense(Expense expense) async {
    try {
      final saved = await _repository.save(expense);

      final existingIndex = _expenses.indexWhere((e) => e.id == saved.id);
      if (existingIndex != -1) {
        _expenses[existingIndex] = saved;
      } else {
        _expenses.insert(0, saved);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Eliminar uma despesa
  Future<void> deleteExpense(String id) async {
    try {
      await _repository.delete(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obter despesas por categoria
  List<Expense> getExpensesByCategory(ExpenseCategory category) {
    return _expenses.where((e) => e.category == category).toList();
  }

  /// Limpar todos os dados (usado no logout)
  void clearData() {
    _expenses = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
