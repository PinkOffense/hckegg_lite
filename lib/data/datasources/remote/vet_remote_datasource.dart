// lib/data/datasources/remote/vet_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/exceptions.dart';
import '../../../core/json_utils.dart';
import '../../../models/vet_record.dart';

/// Datasource remoto para registos veterinários (Supabase)
class VetRemoteDatasource {
  final SupabaseClient _client;

  VetRemoteDatasource(this._client);

  static const String _tableName = 'vet_records';

  /// Obter todos os registos
  Future<List<VetRecord>> getAll() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Obter registo por ID
  Future<VetRecord?> getById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _fromSupabaseJson(response);
  }

  /// Obter registos por tipo
  Future<List<VetRecord>> getByType(VetRecordType type) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('type', type.name)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Obter registos por gravidade
  Future<List<VetRecord>> getBySeverity(VetRecordSeverity severity) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('severity', severity.name)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Obter acções agendadas futuras
  Future<List<VetRecord>> getUpcomingActions() async {
    final today = DateTime.now();
    final todayStr = _dateToString(today);

    final response = await _client
        .from(_tableName)
        .select()
        .not('next_action_date', 'is', null)
        .gte('next_action_date', todayStr)
        .order('next_action_date', ascending: true);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Obter registos num intervalo de datas
  Future<List<VetRecord>> getByDateRange(DateTime start, DateTime end) async {
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

  /// Criar novo registo
  Future<VetRecord> create(VetRecord record) async {
    final json = _toSupabaseJson(record);

    final response = await _client
        .from(_tableName)
        .insert(json)
        .select()
        .single();

    return _fromSupabaseJson(response);
  }

  /// Actualizar registo
  Future<VetRecord> update(VetRecord record) async {
    final json = _toSupabaseJson(record);

    final response = await _client
        .from(_tableName)
        .update(json)
        .eq('id', record.id)
        .select()
        .single();

    return _fromSupabaseJson(response);
  }

  /// Eliminar registo
  Future<void> delete(String id) async {
    await _client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  /// Obter estatísticas
  Future<Map<String, dynamic>> getStatistics({
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
    final records = (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();

    // Calcular estatísticas
    final totalRecords = records.length;
    final totalDeaths = records.where((r) => r.type == VetRecordType.death).length;
    final totalCosts = records.fold<double>(0.0, (sum, r) => sum + (r.cost ?? 0.0));
    final totalHensAffected = records.fold<int>(0, (sum, r) => sum + r.hensAffected);

    // Contar por tipo
    final byType = <String, int>{};
    for (final type in VetRecordType.values) {
      byType[type.name] = records.where((r) => r.type == type).length;
    }

    // Contar por gravidade
    final bySeverity = <String, int>{};
    for (final severity in VetRecordSeverity.values) {
      bySeverity[severity.name] = records.where((r) => r.severity == severity).length;
    }

    return {
      'total_records': totalRecords,
      'total_deaths': totalDeaths,
      'total_costs': totalCosts,
      'total_hens_affected': totalHensAffected,
      'by_type': byType,
      'by_severity': bySeverity,
    };
  }

  /// Converter de JSON do Supabase para VetRecord
  /// Usa parsing seguro com tratamento de erros adequado
  VetRecord _fromSupabaseJson(Map<String, dynamic> json) {
    try {
      return VetRecord(
        id: json.requireString('id'),
        date: json.requireString('date'),
        type: json.enumValue('type', VetRecordType.values, VetRecordType.checkup),
        hensAffected: json.requireInt('hens_affected'),
        description: json.requireString('description'),
        medication: json.optionalString('medication'),
        cost: json.optionalDouble('cost'),
        nextActionDate: json.optionalString('next_action_date'),
        notes: json.optionalString('notes'),
        severity: json.enumValue('severity', VetRecordSeverity.values, VetRecordSeverity.low),
        createdAt: json.requireDateTime('created_at'),
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw ValidationException.parseError('VetRecord', json);
    }
  }

  /// Converter de VetRecord para JSON do Supabase
  Map<String, dynamic> _toSupabaseJson(VetRecord record) {
    final userId = _client.auth.currentUser?.id;

    return {
      'id': record.id,
      'date': record.date,
      'type': record.type.name,
      'hens_affected': record.hensAffected,
      'description': record.description,
      'medication': record.medication,
      'cost': record.cost,
      'next_action_date': record.nextActionDate,
      'notes': record.notes,
      'severity': record.severity.name,
      // Adicionar user_id explicitamente (também validado pelo RLS)
      if (userId != null) 'user_id': userId,
    };
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
