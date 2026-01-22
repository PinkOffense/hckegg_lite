// lib/data/datasources/remote/expense_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/expense.dart';

/// Datasource remoto para despesas (Supabase)
class ExpenseRemoteDatasource {
  final SupabaseClient _client;

  ExpenseRemoteDatasource(this._client);

  static const String _tableName = 'expenses';

  /// Obter todas as despesas
  Future<List<Expense>> getAll() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Obter despesa por ID
  Future<Expense?> getById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _fromSupabaseJson(response);
  }

  /// Obter despesas num intervalo de datas
  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async {
    final startStr = _dateToString(start);
    final endStr = _dateToString(end);

    final response = await _client
        .from(_tableName)
        .select()
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Obter despesas por categoria
  Future<List<Expense>> getByCategory(ExpenseCategory category) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('category', category.name)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Criar nova despesa
  Future<Expense> create(Expense expense) async {
    final json = _toSupabaseJson(expense);

    final response = await _client
        .from(_tableName)
        .insert(json)
        .select()
        .single();

    return _fromSupabaseJson(response);
  }

  /// Actualizar despesa
  Future<Expense> update(Expense expense) async {
    final json = _toSupabaseJson(expense);

    final response = await _client
        .from(_tableName)
        .update(json)
        .eq('id', expense.id)
        .select()
        .single();

    return _fromSupabaseJson(response);
  }

  /// Eliminar despesa
  Future<void> delete(String id) async {
    await _client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  /// Obter totais por categoria
  Future<Map<ExpenseCategory, double>> getTotalsByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Construir query com filtros opcionais
    var query = _client.from(_tableName).select();

    if (startDate != null) {
      query = query.gte('date', _dateToString(startDate));
    }
    if (endDate != null) {
      query = query.lte('date', _dateToString(endDate));
    }

    final response = await query;
    final expenses = (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();

    // Agrupar por categoria
    final totals = <ExpenseCategory, double>{};
    for (final category in ExpenseCategory.values) {
      totals[category] = 0.0;
    }

    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0.0) + expense.amount;
    }

    return totals;
  }

  /// Obter total de despesas
  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from(_tableName).select();

    if (startDate != null) {
      query = query.gte('date', _dateToString(startDate));
    }
    if (endDate != null) {
      query = query.lte('date', _dateToString(endDate));
    }

    final response = await query;
    final expenses = (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();

    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  /// Converter de JSON do Supabase para Expense
  Expense _fromSupabaseJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      date: json['date'] as String,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converter de Expense para JSON do Supabase
  Map<String, dynamic> _toSupabaseJson(Expense expense) {
    return {
      'date': expense.date,
      'category': expense.category.name,
      'amount': expense.amount,
      'description': expense.description,
      'notes': expense.notes,
    };
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
