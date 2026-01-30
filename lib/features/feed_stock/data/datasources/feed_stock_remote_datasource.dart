import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/feed_stock_model.dart';

abstract class FeedStockRemoteDataSource {
  Future<List<FeedStockModel>> getFeedStocks();
  Future<FeedStockModel> getFeedStockById(String id);
  Future<List<FeedStockModel>> getLowStockItems();
  Future<FeedStockModel> createFeedStock(FeedStockModel stock);
  Future<FeedStockModel> updateFeedStock(FeedStockModel stock);
  Future<void> deleteFeedStock(String id);
  Future<List<FeedMovementModel>> getMovements(String feedStockId);
  Future<FeedMovementModel> addMovement(FeedMovementModel movement);
}

class FeedStockRemoteDataSourceImpl implements FeedStockRemoteDataSource {
  final SupabaseClient client;

  FeedStockRemoteDataSourceImpl({required this.client});

  @override
  Future<List<FeedStockModel>> getFeedStocks() async {
    final response = await client
        .from('feed_stocks')
        .select()
        .order('last_updated', ascending: false);

    return (response as List)
        .map((json) => FeedStockModel.fromJson(json))
        .toList();
  }

  @override
  Future<FeedStockModel> getFeedStockById(String id) async {
    final response = await client
        .from('feed_stocks')
        .select()
        .eq('id', id)
        .single();

    return FeedStockModel.fromJson(response);
  }

  @override
  Future<List<FeedStockModel>> getLowStockItems() async {
    final allStocks = await getFeedStocks();
    return allStocks.where((stock) => stock.isLowStock).toList();
  }

  @override
  Future<FeedStockModel> createFeedStock(FeedStockModel stock) async {
    final response = await client
        .from('feed_stocks')
        .insert(stock.toJson())
        .select()
        .single();

    return FeedStockModel.fromJson(response);
  }

  @override
  Future<FeedStockModel> updateFeedStock(FeedStockModel stock) async {
    final response = await client
        .from('feed_stocks')
        .update(stock.toJson())
        .eq('id', stock.id)
        .select()
        .single();

    return FeedStockModel.fromJson(response);
  }

  @override
  Future<void> deleteFeedStock(String id) async {
    await client.from('feed_stocks').delete().eq('id', id);
  }

  @override
  Future<List<FeedMovementModel>> getMovements(String feedStockId) async {
    final response = await client
        .from('feed_movements')
        .select()
        .eq('feed_stock_id', feedStockId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => FeedMovementModel.fromJson(json))
        .toList();
  }

  @override
  Future<FeedMovementModel> addMovement(FeedMovementModel movement) async {
    final response = await client
        .from('feed_movements')
        .insert(movement.toJson())
        .select()
        .single();

    return FeedMovementModel.fromJson(response);
  }
}
