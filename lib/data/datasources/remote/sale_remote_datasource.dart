// lib/data/datasources/remote/sale_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/exceptions.dart';
import '../../../core/json_utils.dart';
import '../../../models/egg_sale.dart';

/// Datasource remoto para vendas de ovos (Supabase)
class SaleRemoteDatasource {
  final SupabaseClient _client;

  SaleRemoteDatasource(this._client);

  static const String _tableName = 'egg_sales';

  /// Obter todas as vendas
  Future<List<EggSale>> getAll() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Obter venda por ID
  Future<EggSale?> getById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _fromSupabaseJson(response);
  }

  /// Obter vendas num intervalo de datas
  Future<List<EggSale>> getByDateRange(DateTime start, DateTime end) async {
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

  /// Obter vendas por cliente (com sanitização para prevenir SQL injection)
  Future<List<EggSale>> getByCustomer(String customerName) async {
    // Sanitize input to prevent SQL injection
    final sanitizedName = JsonUtils.sanitizeForQuery(customerName);

    // Validate query is safe
    if (sanitizedName.isEmpty || !JsonUtils.isSafeForQuery(sanitizedName)) {
      return []; // Return empty list for potentially malicious queries
    }

    final response = await _client
        .from(_tableName)
        .select()
        .ilike('customer_name', '%$sanitizedName%')
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();
  }

  /// Criar nova venda
  Future<EggSale> create(EggSale sale) async {
    final json = _toSupabaseJson(sale);

    final response = await _client
        .from(_tableName)
        .insert(json)
        .select()
        .single();

    return _fromSupabaseJson(response);
  }

  /// Actualizar venda
  Future<EggSale> update(EggSale sale) async {
    final json = _toSupabaseJson(sale);

    final response = await _client
        .from(_tableName)
        .update(json)
        .eq('id', sale.id)
        .select()
        .single();

    return _fromSupabaseJson(response);
  }

  /// Eliminar venda
  Future<void> delete(String id) async {
    await _client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  /// Obter receita total
  Future<double> getTotalRevenue({
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
    final sales = (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();

    return sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
  }

  /// Obter estatísticas de vendas
  Future<Map<String, dynamic>> getSalesStatistics({
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
    final sales = (response as List)
        .map((json) => _fromSupabaseJson(json))
        .toList();

    final totalQuantity = sales.fold<int>(0, (sum, s) => sum + s.quantitySold);
    final totalRevenue = sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
    final averagePrice = sales.isEmpty
        ? 0.0
        : sales.fold<double>(0.0, (sum, s) => sum + s.pricePerEgg) / sales.length;

    return {
      'total_sales': sales.length,
      'total_quantity': totalQuantity,
      'total_revenue': totalRevenue,
      'average_price_per_egg': averagePrice,
    };
  }

  /// Converter de JSON do Supabase para EggSale
  /// Usa parsing seguro com tratamento de erros adequado
  EggSale _fromSupabaseJson(Map<String, dynamic> json) {
    try {
      final paymentStatusStr = json.optionalString('payment_status');
      return EggSale(
        id: json.requireString('id'),
        date: json.requireString('date'),
        quantitySold: json.requireInt('quantity_sold'),
        pricePerEgg: json.requireDouble('price_per_egg'),
        pricePerDozen: json.requireDouble('price_per_dozen'),
        customerName: json.optionalString('customer_name'),
        customerEmail: json.optionalString('customer_email'),
        customerPhone: json.optionalString('customer_phone'),
        notes: json.optionalString('notes'),
        paymentStatus: paymentStatusStr != null
            ? PaymentStatus.fromString(paymentStatusStr)
            : PaymentStatus.pending,
        paymentDate: json.optionalString('payment_date'),
        isReservation: json.boolOrDefault('is_reservation', false),
        reservationNotes: json.optionalString('reservation_notes'),
        isLost: json.boolOrDefault('is_lost', false),
        createdAt: json.requireDateTime('created_at'),
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw ValidationException.parseError('EggSale', json);
    }
  }

  /// Converter de EggSale para JSON do Supabase
  Map<String, dynamic> _toSupabaseJson(EggSale sale) {
    final userId = _client.auth.currentUser?.id;

    return {
      'date': sale.date,
      'quantity_sold': sale.quantitySold,
      'price_per_egg': sale.pricePerEgg,
      'price_per_dozen': sale.pricePerDozen,
      'customer_name': sale.customerName,
      'customer_email': sale.customerEmail,
      'customer_phone': sale.customerPhone,
      'notes': sale.notes,
      'payment_status': sale.paymentStatus.name,
      'payment_date': sale.paymentDate,
      'is_reservation': sale.isReservation,
      'reservation_notes': sale.reservationNotes,
      'is_lost': sale.isLost,
      // Adicionar user_id explicitamente (também validado pelo RLS)
      if (userId != null) 'user_id': userId,
    };
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
