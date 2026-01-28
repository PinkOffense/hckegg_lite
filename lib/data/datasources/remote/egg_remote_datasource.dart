// lib/data/datasources/remote/egg_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/date_utils.dart';
import '../../../core/exceptions.dart';
import '../../../core/json_utils.dart';
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
    final startStr = AppDateUtils.toIsoDateString(start);
    final endStr = AppDateUtils.toIsoDateString(end);

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

  /// Pesquisar registos (com sanitização para prevenir SQL injection)
  Future<List<DailyEggRecord>> search(String query) async {
    // Sanitize input to prevent SQL injection
    final sanitizedQuery = JsonUtils.sanitizeForQuery(query);

    // Validate query is safe
    if (sanitizedQuery.isEmpty || !JsonUtils.isSafeForQuery(sanitizedQuery)) {
      return []; // Return empty list for potentially malicious queries
    }

    final response = await _client
        .from(_tableName)
        .select()
        .or('notes.ilike.%$sanitizedQuery%,date.ilike.%$sanitizedQuery%')
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
      query += '.gte(date,${AppDateUtils.toIsoDateString(startDate)})';
    }
    if (endDate != null) {
      query += '.lte(date,${AppDateUtils.toIsoDateString(endDate)})';
    }

    final response = await _client
        .from(_tableName)
        .select();

    final records = (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();

    // Calcular estatísticas
    final totalCollected = records.fold<int>(0, (sum, r) => sum + r.eggsCollected);
    final totalConsumed = records.fold<int>(0, (sum, r) => sum + r.eggsConsumed);
    final totalRemaining = records.fold<int>(0, (sum, r) => sum + r.eggsRemaining);

    return {
      'collected': totalCollected,
      'consumed': totalConsumed,
      'remaining': totalRemaining,
    };
  }

  /// Converter de JSON do Supabase para DailyEggRecord
  /// Usa parsing seguro com tratamento de erros adequado
  DailyEggRecord _fromSupabaseJson(Map<String, dynamic> json) {
    try {
      return DailyEggRecord(
        id: json.requireString('id'),
        date: json.requireString('date'),
        eggsCollected: json.requireInt('eggs_collected'),
        eggsConsumed: json.intOrDefault('eggs_consumed', 0),
        notes: json.optionalString('notes'),
        henCount: json.optionalInt('hen_count'),
        createdAt: json.requireDateTime('created_at'),
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw ValidationException.parseError('DailyEggRecord', json);
    }
  }

  /// Converter de DailyEggRecord para JSON do Supabase
  Map<String, dynamic> _toSupabaseJson(DailyEggRecord record) {
    final userId = _client.auth.currentUser?.id;

    return {
      'date': record.date,
      'eggs_collected': record.eggsCollected,
      'eggs_consumed': record.eggsConsumed,
      'notes': record.notes,
      'hen_count': record.henCount,
      // Adicionar user_id explicitamente (também validado pelo RLS)
      if (userId != null) 'user_id': userId,
      // id é gerado automaticamente se não existir
    };
  }
}
