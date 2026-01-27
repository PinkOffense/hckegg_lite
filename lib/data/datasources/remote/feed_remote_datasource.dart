// lib/data/datasources/remote/feed_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/exceptions.dart';
import '../../../core/json_utils.dart';
import '../../../models/feed_stock.dart';

/// Datasource remoto para stock de ração (Supabase)
class FeedRemoteDatasource {
  final SupabaseClient _client;

  FeedRemoteDatasource(this._client);

  static const String _stockTable = 'feed_stocks';
  static const String _movementTable = 'feed_movements';

  /// Obter todos os stocks
  Future<List<FeedStock>> getAll() async {
    final response = await _client
        .from(_stockTable)
        .select()
        .order('type', ascending: true);

    return (response as List)
        .map((json) => _stockFromSupabase(json))
        .toList();
  }

  /// Obter stock por ID
  Future<FeedStock?> getById(String id) async {
    final response = await _client
        .from(_stockTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _stockFromSupabase(response);
  }

  /// Obter stocks por tipo
  Future<List<FeedStock>> getByType(FeedType type) async {
    final response = await _client
        .from(_stockTable)
        .select()
        .eq('type', type.name)
        .order('brand', ascending: true);

    return (response as List)
        .map((json) => _stockFromSupabase(json))
        .toList();
  }

  /// Criar novo stock
  Future<FeedStock> create(FeedStock stock) async {
    final json = _stockToSupabase(stock);

    final response = await _client
        .from(_stockTable)
        .insert(json)
        .select()
        .single();

    return _stockFromSupabase(response);
  }

  /// Actualizar stock
  Future<FeedStock> update(FeedStock stock) async {
    final json = _stockToSupabase(stock);

    final response = await _client
        .from(_stockTable)
        .update(json)
        .eq('id', stock.id)
        .select()
        .single();

    return _stockFromSupabase(response);
  }

  /// Eliminar stock
  Future<void> delete(String id) async {
    // Primeiro eliminar movimentos associados
    await _client
        .from(_movementTable)
        .delete()
        .eq('feed_stock_id', id);

    // Depois eliminar o stock
    await _client
        .from(_stockTable)
        .delete()
        .eq('id', id);
  }

  /// Obter stocks com quantidade baixa
  Future<List<FeedStock>> getLowStock() async {
    final response = await _client
        .from(_stockTable)
        .select()
        .order('current_quantity_kg', ascending: true);

    final stocks = (response as List)
        .map((json) => _stockFromSupabase(json))
        .toList();

    return stocks.where((s) => s.isLowStock).toList();
  }

  /// Obter movimentos de um stock
  Future<List<FeedMovement>> getMovements(String feedStockId) async {
    final response = await _client
        .from(_movementTable)
        .select()
        .eq('feed_stock_id', feedStockId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => _movementFromSupabase(json))
        .toList();
  }

  /// Adicionar movimento
  Future<FeedMovement> addMovement(FeedMovement movement) async {
    final json = _movementToSupabase(movement);

    final response = await _client
        .from(_movementTable)
        .insert(json)
        .select()
        .single();

    return _movementFromSupabase(response);
  }

  /// Eliminar movimento
  Future<void> deleteMovement(String id) async {
    await _client
        .from(_movementTable)
        .delete()
        .eq('id', id);
  }

  /// Converter de JSON do Supabase para FeedStock
  /// Usa parsing seguro com tratamento de erros adequado
  FeedStock _stockFromSupabase(Map<String, dynamic> json) {
    try {
      return FeedStock(
        id: json.requireString('id'),
        type: json.enumValue('type', FeedType.values, FeedType.other),
        brand: json.optionalString('brand'),
        currentQuantityKg: json.requireDouble('current_quantity_kg'),
        minimumQuantityKg: json.doubleOrDefault('minimum_quantity_kg', 10.0),
        pricePerKg: json.optionalDouble('price_per_kg'),
        notes: json.optionalString('notes'),
        lastUpdated: json.requireDateTime('last_updated'),
        createdAt: json.requireDateTime('created_at'),
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw ValidationException.parseError('FeedStock', json);
    }
  }

  /// Converter de FeedStock para JSON do Supabase
  Map<String, dynamic> _stockToSupabase(FeedStock stock) {
    final userId = _client.auth.currentUser?.id;

    return {
      'type': stock.type.name,
      'brand': stock.brand,
      'current_quantity_kg': stock.currentQuantityKg,
      'minimum_quantity_kg': stock.minimumQuantityKg,
      'price_per_kg': stock.pricePerKg,
      'notes': stock.notes,
      'last_updated': stock.lastUpdated.toIso8601String(),
      if (userId != null) 'user_id': userId,
    };
  }

  /// Converter de JSON do Supabase para FeedMovement
  /// Usa parsing seguro com tratamento de erros adequado
  FeedMovement _movementFromSupabase(Map<String, dynamic> json) {
    try {
      return FeedMovement(
        id: json.requireString('id'),
        feedStockId: json.requireString('feed_stock_id'),
        movementType: json.enumValue('movement_type', StockMovementType.values, StockMovementType.adjustment),
        quantityKg: json.requireDouble('quantity_kg'),
        cost: json.optionalDouble('cost'),
        date: json.requireString('date'),
        notes: json.optionalString('notes'),
        createdAt: json.requireDateTime('created_at'),
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw ValidationException.parseError('FeedMovement', json);
    }
  }

  /// Converter de FeedMovement para JSON do Supabase
  Map<String, dynamic> _movementToSupabase(FeedMovement movement) {
    final userId = _client.auth.currentUser?.id;

    return {
      'feed_stock_id': movement.feedStockId,
      'movement_type': movement.movementType.name,
      'quantity_kg': movement.quantityKg,
      'cost': movement.cost,
      'date': movement.date,
      'notes': movement.notes,
      if (userId != null) 'user_id': userId,
    };
  }
}
