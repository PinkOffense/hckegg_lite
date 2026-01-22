// lib/domain/repositories/expense_repository.dart

import '../../models/expense.dart';

/// Interface abstrata para o repositório de despesas
abstract class ExpenseRepository {
  /// Obter todas as despesas do utilizador
  Future<List<Expense>> getAll();

  /// Obter despesa por ID
  Future<Expense?> getById(String id);

  /// Obter despesas num intervalo de datas
  Future<List<Expense>> getByDateRange(DateTime start, DateTime end);

  /// Obter despesas por categoria
  Future<List<Expense>> getByCategory(ExpenseCategory category);

  /// Guardar (criar ou actualizar) uma despesa
  Future<Expense> save(Expense expense);

  /// Eliminar uma despesa
  Future<void> delete(String id);

  /// Obter total de despesas por categoria
  Future<Map<ExpenseCategory, double>> getTotalsByCategory({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Obter total de despesas
  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
  });
}
