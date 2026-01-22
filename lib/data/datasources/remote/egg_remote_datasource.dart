// lib/data/datasources/remote/egg_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/daily_egg_record.dart';

/// Datasource remoto para registos de ovos (Supabase)
class EggRemoteDatasource {
  final SupabaseClient _client;

  EggRemoteDatasource(this._client);

  /// Nome da tabela no Supabase
  static const String _tableName = 'daily_egg_records';

  /// Obter todos os registos do utilizador
  Future<List<DailyEggRecord>> getAll() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Obter registo por data
  Future<DailyEggRecord?> getByDate(String date) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('date', date)
        .maybeSingle();

    if (response == null) return null;
    return _fromSupabaseJson(response);
  }

  /// Obter registos num intervalo de datas
  Future<List<DailyEggRecord>> getByDateRange(DateTime start, DateTime end) async {
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

  /// Obter os últimos N registos
  Future<List<DailyEggRecord>> getRecent(int count) async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('date', ascending: false)
        .limit(count);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Criar um novo registo
  Future<DailyEggRecord> create(DailyEggRecord record) async {
    final json = _toSupabaseJson(record);

    final response = await _client
        .from(_tableName)
        .insert(json)
        .select()
        .single();

    return _fromSupabaseJson(response);
  }

  /// Actualizar um registo existente
  Future<DailyEggRecord> update(DailyEggRecord record) async {
    final json = _toSupabaseJson(record);

    final response = await _client
        .from(_tableName)
        .update(json)
        .eq('id', record.id)
        .select()
        .single();

    return _fromSupabaseJson(response);
  }

  /// Eliminar por data
  Future<void> deleteByDate(String date) async {
    await _client
        .from(_tableName)
        .delete()
        .eq('date', date);
  }

  /// Eliminar por ID
  Future<void> deleteById(String id) async {
    await _client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  /// Pesquisar registos
  Future<List<DailyEggRecord>> search(String query) async {
    final response = await _client
        .from(_tableName)
        .select()
        .or('notes.ilike.%$query%,date.ilike.%$query%')
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Obter estatísticas
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String query = _client.from(_tableName).select().toString();

    if (startDate != null) {
      query += '.gte(date,${_dateToString(startDate)})';
    }
    if (endDate != null) {
      query += '.lte(date,${_dateToString(endDate)})';
    }

    final response = await _client
        .from(_tableName)
        .select();

    final records = (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();

    // Calcular estatísticas
    final totalCollected = records.fold(0, (sum, r) => sum + r.eggsCollected);
    final totalSold = records.fold(0, (sum, r) => sum + r.eggsSold);
    final totalConsumed = records.fold(0, (sum, r) => sum + r.eggsConsumed);
    final totalRevenue = records.fold(0.0, (sum, r) => sum + r.revenue);
    final totalExpenses = records.fold(0.0, (sum, r) => sum + r.totalExpenses);

    return {
      'collected': totalCollected,
      'sold': totalSold,
      'consumed': totalConsumed,
      'revenue': totalRevenue,
      'expenses': totalExpenses,
      'net_profit': totalRevenue - totalExpenses,
    };
  }

  /// Converter de JSON do Supabase para DailyEggRecord
  DailyEggRecord _fromSupabaseJson(Map<String, dynamic> json) {
    return DailyEggRecord(
      id: json['id'] as String,
      date: json['date'] as String,
      eggsCollected: json['eggs_collected'] as int,
      eggsSold: json['eggs_sold'] as int,
      eggsConsumed: json['eggs_consumed'] as int,
      pricePerEgg: (json['price_per_egg'] as num).toDouble(),
      notes: json['notes'] as String?,
      henCount: json['hen_count'] as int?,
      feedExpense: json['feed_expense'] != null ? (json['feed_expense'] as num).toDouble() : null,
      vetExpense: json['vet_expense'] != null ? (json['vet_expense'] as num).toDouble() : null,
      otherExpense: json['other_expense'] != null ? (json['other_expense'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converter de DailyEggRecord para JSON do Supabase
  Map<String, dynamic> _toSupabaseJson(DailyEggRecord record) {
    return {
      'date': record.date,
      'eggs_collected': record.eggsCollected,
      'eggs_sold': record.eggsSold,
      'eggs_consumed': record.eggsConsumed,
      'price_per_egg': record.pricePerEgg,
      'notes': record.notes,
      'hen_count': record.henCount,
      'feed_expense': record.feedExpense,
      'vet_expense': record.vetExpense,
      'other_expense': record.otherExpense,
      // user_id é automaticamente adicionado pelo RLS
      // id é gerado automaticamente se não existir
    };
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
