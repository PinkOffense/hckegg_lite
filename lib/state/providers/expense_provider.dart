// lib/state/providers/expense_provider.dart

import 'package:flutter/material.dart';
import '../../core/di/repository_provider.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../models/expense.dart';

/// Provider para gestão de despesas
///
/// Responsabilidades:
/// - Carregar, guardar e eliminar despesas
/// - Fornecer estatísticas de despesas por categoria
/// - Notificar listeners sobre mudanças de estado
class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository;

  /// Construtor que permite injecção de dependências para testes
  ExpenseProvider({ExpenseRepository? repository})
      : _repository = repository ?? RepositoryProvider.instance.expenseRepository;

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
  ///
  /// Throws [ArgumentError] if:
  /// - amount is negative
  /// - date is empty
  /// - description is empty
  Future<void> saveExpense(Expense expense) async {
    _validateExpense(expense);

    try {
      final saved = await _repository.save(expense);

      final existingIndex = _expenses.indexWhere((e) => e.id == saved.id);
      if (existingIndex != -1) {
        _expenses[existingIndex] = saved;
      } else {
        _expenses.insert(0, saved);
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Validates expense data before saving
  void _validateExpense(Expense expense) {
    if (expense.amount < 0) {
      throw ArgumentError('Expense amount cannot be negative');
    }
    if (expense.date.isEmpty) {
      throw ArgumentError('Expense date cannot be empty');
    }
    if (expense.description.isEmpty) {
      throw ArgumentError('Expense description cannot be empty');
    }
  }

  /// Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
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
