// lib/data/datasources/remote/feed_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
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
  FeedStock _stockFromSupabase(Map<String, dynamic> json) {
    return FeedStock(
      id: json['id'] as String,
      type: FeedType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeedType.other,
      ),
      brand: json['brand'] as String?,
      currentQuantityKg: (json['current_quantity_kg'] as num).toDouble(),
      minimumQuantityKg: (json['minimum_quantity_kg'] as num?)?.toDouble() ?? 10.0,
      pricePerKg: (json['price_per_kg'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
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
  FeedMovement _movementFromSupabase(Map<String, dynamic> json) {
    return FeedMovement(
      id: json['id'] as String,
      feedStockId: json['feed_stock_id'] as String,
      movementType: StockMovementType.values.firstWhere(
        (e) => e.name == json['movement_type'],
        orElse: () => StockMovementType.adjustment,
      ),
      quantityKg: (json['quantity_kg'] as num).toDouble(),
      cost: (json['cost'] as num?)?.toDouble(),
      date: json['date'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
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
