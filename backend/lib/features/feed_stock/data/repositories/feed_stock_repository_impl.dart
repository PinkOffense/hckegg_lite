import 'package:supabase/supabase.dart';
import '../../../../core/core.dart';
import '../../domain/entities/feed_stock.dart';
import '../../domain/repositories/feed_stock_repository.dart';

class FeedStockRepositoryImpl implements FeedStockRepository {
  FeedStockRepositoryImpl(this._client);
  final SupabaseClient _client;
  static const _stockTable = 'feed_stocks';
  static const _movementTable = 'feed_movements';

  @override
  Future<Result<List<FeedStock>>> getFeedStocks(String userId) async {
    try {
      final response = await _client
          .from(_stockTable)
          .select()
          .eq('user_id', userId)
          .order('type', ascending: true);
      return Result.success(
        (response as List)
            .map((j) => FeedStock.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> getFeedStockById(String id) async {
    try {
      final response =
          await _client.from(_stockTable).select().eq('id', id).single();
      return Result.success(FeedStock.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Result.failure(
          const NotFoundFailure(message: 'Feed stock not found'),
        );
      }
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FeedStock>>> getLowStockItems(String userId) async {
    try {
      final response = await _client
          .from(_stockTable)
          .select()
          .eq('user_id', userId);

      final stocks = (response as List)
          .map((j) => FeedStock.fromJson(j as Map<String, dynamic>))
          .where((stock) => stock.isLowStock)
          .toList();

      return Result.success(stocks);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> createFeedStock(FeedStock feedStock) async {
    try {
      final now = DateTime.now().toUtc();
      final data = {
        'user_id': feedStock.userId,
        'type': feedStock.type.name,
        'brand': feedStock.brand,
        'current_quantity_kg': feedStock.currentQuantityKg,
        'minimum_quantity_kg': feedStock.minimumQuantityKg,
        'price_per_kg': feedStock.pricePerKg,
        'notes': feedStock.notes,
        'last_updated': now.toIso8601String(),
        'created_at': now.toIso8601String(),
      };
      final response =
          await _client.from(_stockTable).insert(data).select().single();
      return Result.success(FeedStock.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> updateFeedStock(FeedStock feedStock) async {
    try {
      final data = {
        'type': feedStock.type.name,
        'brand': feedStock.brand,
        'current_quantity_kg': feedStock.currentQuantityKg,
        'minimum_quantity_kg': feedStock.minimumQuantityKg,
        'price_per_kg': feedStock.pricePerKg,
        'notes': feedStock.notes,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      };
      final response = await _client
          .from(_stockTable)
          .update(data)
          .eq('id', feedStock.id)
          .select()
          .single();
      return Result.success(FeedStock.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFeedStock(String id) async {
    try {
      await _client.from(_stockTable).delete().eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FeedMovement>>> getFeedMovements(
    String userId,
    String feedStockId,
  ) async {
    try {
      final response = await _client
          .from(_movementTable)
          .select()
          .eq('user_id', userId)
          .eq('feed_stock_id', feedStockId)
          .order('date', ascending: false);
      return Result.success(
        (response as List)
            .map((j) => FeedMovement.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedMovement>> addFeedMovement(FeedMovement movement) async {
    try {
      final data = {
        'user_id': movement.userId,
        'feed_stock_id': movement.feedStockId,
        'movement_type': movement.movementType.name,
        'quantity_kg': movement.quantityKg,
        'cost': movement.cost,
        'date': movement.date,
        'notes': movement.notes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      final response =
          await _client.from(_movementTable).insert(data).select().single();

      // Update the feed stock quantity based on movement type
      final stockResult = await getFeedStockById(movement.feedStockId);
      if (stockResult.isSuccess && stockResult.valueOrNull != null) {
        final stock = stockResult.valueOrNull!;
        double newQuantity = stock.currentQuantityKg;

        switch (movement.movementType) {
          case StockMovementType.purchase:
            newQuantity += movement.quantityKg;
          case StockMovementType.consumption:
          case StockMovementType.loss:
            newQuantity -= movement.quantityKg;
          case StockMovementType.adjustment:
            // Adjustment can be positive or negative, quantity is the new value
            newQuantity = movement.quantityKg;
        }

        await updateFeedStock(stock.copyWith(
          currentQuantityKg: newQuantity < 0 ? 0 : newQuantity,
          lastUpdated: DateTime.now().toUtc(),
        ));
      }

      return Result.success(FeedMovement.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
