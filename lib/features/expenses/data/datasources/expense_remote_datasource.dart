import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/expense.dart';
import '../models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseModel>> getExpenses();
  Future<ExpenseModel> getExpenseById(String id);
  Future<List<ExpenseModel>> getExpensesByDateRange({required String startDate, required String endDate});
  Future<List<ExpenseModel>> getExpensesByCategory(ExpenseCategory category);
  Future<ExpenseModel> createExpense(ExpenseModel expense);
  Future<ExpenseModel> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final SupabaseClient _client;
  static const _tableName = 'expenses';

  ExpenseRemoteDataSourceImpl(this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user. Please sign in again.');
    }
    return user.id;
  }

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);
    return (response as List).map((j) => ExpenseModel.fromJson(j)).toList();
  }

  @override
  Future<ExpenseModel> getExpenseById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .single();
    return ExpenseModel.fromJson(response);
  }

  @override
  Future<List<ExpenseModel>> getExpensesByDateRange({required String startDate, required String endDate}) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date', ascending: false);
    return (response as List).map((j) => ExpenseModel.fromJson(j)).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByCategory(ExpenseCategory category) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .eq('category', category.name)
        .order('date', ascending: false);
    return (response as List).map((j) => ExpenseModel.fromJson(j)).toList();
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final response = await _client
        .from(_tableName)
        .insert(expense.toInsertJson(_userId))
        .select()
        .single();
    return ExpenseModel.fromJson(response);
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final response = await _client
        .from(_tableName)
        .update(expense.toInsertJson(_userId))
        .eq('id', expense.id)
        .eq('user_id', _userId)
        .select()
        .single();
    return ExpenseModel.fromJson(response);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _client.from(_tableName).delete().eq('id', id).eq('user_id', _userId);
  }
}
