// lib/data/repositories/expense_repository_impl.dart

import '../../domain/repositories/expense_repository.dart';
import '../../models/expense.dart';
import '../datasources/remote/expense_remote_datasource.dart';

/// Implementação do ExpenseRepository usando Supabase
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDatasource _remoteDatasource;

  ExpenseRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<Expense>> getAll() async {
    try {
      return await _remoteDatasource.getAll();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Expense?> getById(String id) async {
    try {
      return await _remoteDatasource.getById(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async {
    try {
      return await _remoteDatasource.getByDateRange(start, end);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Expense>> getByCategory(ExpenseCategory category) async {
    try {
      return await _remoteDatasource.getByCategory(category);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Expense> save(Expense expense) async {
    try {
      // Verificar se já existe
      final existing = await _remoteDatasource.getById(expense.id);

      if (existing != null) {
        // Actualizar
        return await _remoteDatasource.update(expense);
      } else {
        // Criar
        return await _remoteDatasource.create(expense);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _remoteDatasource.delete(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<ExpenseCategory, double>> getTotalsByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _remoteDatasource.getTotalsByCategory(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _remoteDatasource.getTotalExpenses(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Tratamento de erros centralizado
  Exception _handleError(dynamic error) {
    if (error.toString().contains('Database error')) {
      return Exception('Database error: $error');
    }
    return Exception('Unexpected error: $error');
  }
}
