import 'package:supabase/supabase.dart';
import '../../../../core/core.dart';
import '../../domain/entities/feed_stock.dart';
import '../../domain/repositories/feed_stock_repository.dart';

class FeedStockRepositoryImpl implements FeedStockRepository {
  FeedStockRepositoryImpl(this._client);
  final SupabaseClient _client;
  static const _table = 'feed_stock';

  @override
  Future<Result<List<FeedStock>>> getFeedStocks(String userId) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).order('date', ascending: false);
      return Result.success((response as List).map((j) => FeedStock.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> getFeedStockById(String id) async {
    try {
      final response = await _client.from(_table).select().eq('id', id).single();
      return Result.success(FeedStock.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return Result.failure(const NotFoundFailure(message: 'Feed stock not found'));
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FeedStock>>> getFeedStocksInRange(String userId, String startDate, String endDate) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).gte('date', startDate).lte('date', endDate).order('date', ascending: false);
      return Result.success((response as List).map((j) => FeedStock.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FeedStock>>> getFeedStocksByType(String userId, String feedType) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).eq('feed_type', feedType);
      return Result.success((response as List).map((j) => FeedStock.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> createFeedStock(FeedStock feedStock) async {
    try {
      final data = {
        'user_id': feedStock.userId,
        'date': feedStock.date,
        'feed_type': feedStock.feedType,
        'quantity_kg': feedStock.quantityKg,
        'cost': feedStock.cost,
        'supplier': feedStock.supplier,
        'notes': feedStock.notes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      final response = await _client.from(_table).insert(data).select().single();
      return Result.success(FeedStock.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> updateFeedStock(FeedStock feedStock) async {
    try {
      final data = {
        'date': feedStock.date,
        'feed_type': feedStock.feedType,
        'quantity_kg': feedStock.quantityKg,
        'cost': feedStock.cost,
        'supplier': feedStock.supplier,
        'notes': feedStock.notes,
      };
      final response = await _client.from(_table).update(data).eq('id', feedStock.id).select().single();
      return Result.success(FeedStock.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFeedStock(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStockStatistics>> getStatistics(String userId, String startDate, String endDate) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).gte('date', startDate).lte('date', endDate);
      final feedStocks = (response as List).map((j) => FeedStock.fromJson(j as Map<String, dynamic>)).toList();

      final byFeedType = <String, FeedTypeStats>{};
      var totalQuantityKg = 0.0;
      var totalCost = 0.0;
      for (final f in feedStocks) {
        totalQuantityKg += f.quantityKg;
        totalCost += f.cost;
        final existing = byFeedType[f.feedType];
        byFeedType[f.feedType] = FeedTypeStats(
          quantityKg: (existing?.quantityKg ?? 0) + f.quantityKg,
          cost: (existing?.cost ?? 0) + f.cost,
        );
      }

      return Result.success(FeedStockStatistics(
        totalRecords: feedStocks.length,
        totalQuantityKg: totalQuantityKg,
        totalCost: totalCost,
        byFeedType: byFeedType,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
