// lib/domain/repositories/feed_repository.dart

import '../../models/feed_stock.dart';

/// Interface abstrata para o repositório de stock de ração
abstract class FeedRepository {
  /// Obter todos os stocks de ração
  Future<List<FeedStock>> getAll();

  /// Obter stock por ID
  Future<FeedStock?> getById(String id);

  /// Obter stocks por tipo
  Future<List<FeedStock>> getByType(FeedType type);

  /// Guardar (criar ou actualizar) um stock
  Future<FeedStock> save(FeedStock stock);

  /// Eliminar um stock
  Future<void> delete(String id);

  /// Obter stocks com quantidade baixa
  Future<List<FeedStock>> getLowStock();

  /// Obter todos os movimentos de um stock
  Future<List<FeedMovement>> getMovements(String feedStockId);

  /// Adicionar movimento de stock
  Future<FeedMovement> addMovement(FeedMovement movement);

  /// Eliminar movimento
  Future<void> deleteMovement(String id);
}
