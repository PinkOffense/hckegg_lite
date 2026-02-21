import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/context/farm_context.dart';
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

  String? get _farmId => FarmContext().farmId;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user. Please sign in again.');
    }
    return user.id;
  }

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    var query = _client.from(_tableName).select();

    // Filter by farm_id if available, otherwise by user_id (legacy data)
    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query.order('date', ascending: false);
    return (response as List).map((j) => ExpenseModel.fromJson(j)).toList();
  }

  @override
  Future<ExpenseModel> getExpenseById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .single();
    return ExpenseModel.fromJson(response);
  }

  @override
  Future<List<ExpenseModel>> getExpensesByDateRange({required String startDate, required String endDate}) async {
    var query = _client.from(_tableName).select();

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date', ascending: false);
    return (response as List).map((j) => ExpenseModel.fromJson(j)).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByCategory(ExpenseCategory category) async {
    var query = _client.from(_tableName).select();

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query
        .eq('category', category.name)
        .order('date', ascending: false);
    return (response as List).map((j) => ExpenseModel.fromJson(j)).toList();
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final data = expense.toInsertJson(_userId);
    if (_farmId != null) {
      data['farm_id'] = _farmId;
    }

    final response = await _client
        .from(_tableName)
        .insert(data)
        .select()
        .single();
    return ExpenseModel.fromJson(response);
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final data = expense.toInsertJson(_userId);
    if (_farmId != null) {
      data['farm_id'] = _farmId;
    }

    final response = await _client
        .from(_tableName)
        .update(data)
        .eq('id', expense.id)
        .select()
        .single();
    return ExpenseModel.fromJson(response);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }
}
