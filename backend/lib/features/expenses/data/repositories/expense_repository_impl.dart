import 'package:supabase/supabase.dart';
import '../../../../core/core.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._client);
  final SupabaseClient _client;
  static const _table = 'expenses';

  @override
  Future<Result<List<Expense>>> getExpenses(String userId, {String? farmId}) async {
    try {
      var query = _client.from(_table).select();

      // Filter by farm_id if provided, otherwise by user_id
      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query.order('date', ascending: false);
      return Result.success((response as List).map((j) => Expense.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Expense>> getExpenseById(String id) async {
    try {
      final response = await _client.from(_table).select().eq('id', id).single();
      return Result.success(Expense.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return Result.failure(const NotFoundFailure(message: 'Expense not found'));
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Expense>>> getExpensesInRange(String userId, String startDate, String endDate, {String? farmId}) async {
    try {
      var query = _client.from(_table).select().gte('date', startDate).lte('date', endDate);

      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query.order('date', ascending: false);
      return Result.success((response as List).map((j) => Expense.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Expense>>> getExpensesByCategory(String userId, ExpenseCategory category, {String? farmId}) async {
    try {
      var query = _client.from(_table).select().eq('category', category.name);

      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query;
      return Result.success((response as List).map((j) => Expense.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Expense>> createExpense(Expense expense) async {
    try {
      final data = {
        'user_id': expense.userId,
        'farm_id': expense.farmId,
        'date': expense.date,
        'category': expense.category.name,
        'amount': expense.amount,
        'description': expense.description,
        'notes': expense.notes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      final response = await _client.from(_table).insert(data).select().single();
      return Result.success(Expense.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Expense>> updateExpense(Expense expense) async {
    try {
      final data = {
        'date': expense.date,
        'category': expense.category.name,
        'amount': expense.amount,
        'description': expense.description,
        'notes': expense.notes,
      };
      final response = await _client.from(_table).update(data).eq('id', expense.id).select().single();
      return Result.success(Expense.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteExpense(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ExpenseStatistics>> getStatistics(String userId, String startDate, String endDate, {String? farmId}) async {
    try {
      var query = _client.from(_table).select().gte('date', startDate).lte('date', endDate);

      if (farmId != null) {
        query = query.eq('farm_id', farmId);
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query;
      final expenses = (response as List).map((j) => Expense.fromJson(j as Map<String, dynamic>)).toList();

      final byCategory = <String, double>{};
      var totalAmount = 0.0;
      for (final e in expenses) {
        totalAmount += e.amount;
        byCategory[e.category.name] = (byCategory[e.category.name] ?? 0) + e.amount;
      }

      return Result.success(ExpenseStatistics(totalExpenses: expenses.length, totalAmount: totalAmount, byCategory: byCategory));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
