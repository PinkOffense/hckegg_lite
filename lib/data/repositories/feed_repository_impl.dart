// lib/data/repositories/feed_repository_impl.dart

import '../../domain/repositories/feed_repository.dart';
import '../../models/feed_stock.dart';
import '../datasources/remote/feed_remote_datasource.dart';

/// Implementação do FeedRepository usando Supabase
class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDatasource _remoteDatasource;

  FeedRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<FeedStock>> getAll() async {
    try {
      return await _remoteDatasource.getAll();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<FeedStock?> getById(String id) async {
    try {
      return await _remoteDatasource.getById(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<FeedStock>> getByType(FeedType type) async {
    try {
      return await _remoteDatasource.getByType(type);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<FeedStock> save(FeedStock stock) async {
    try {
      final existing = await _remoteDatasource.getById(stock.id);

      if (existing != null) {
        return await _remoteDatasource.update(stock);
      } else {
        return await _remoteDatasource.create(stock);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _remoteDatasource.delete(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<FeedStock>> getLowStock() async {
    try {
      return await _remoteDatasource.getLowStock();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<FeedMovement>> getMovements(String feedStockId) async {
    try {
      return await _remoteDatasource.getMovements(feedStockId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<FeedMovement> addMovement(FeedMovement movement) async {
    try {
      return await _remoteDatasource.addMovement(movement);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteMovement(String id) async {
    try {
      await _remoteDatasource.deleteMovement(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error.toString().contains('Database error')) {
      return Exception('Database error: $error');
    }
    return Exception('Unexpected error: $error');
  }
}
