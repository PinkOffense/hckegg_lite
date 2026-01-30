import '../../../../core/core.dart';
import '../entities/feed_stock.dart';

abstract class FeedStockRepository {
  Future<Result<List<FeedStock>>> getFeedStocks();
  Future<Result<FeedStock>> getFeedStockById(String id);
  Future<Result<List<FeedStock>>> getLowStockItems();
  Future<Result<FeedStock>> createFeedStock(FeedStock stock);
  Future<Result<FeedStock>> updateFeedStock(FeedStock stock);
  Future<Result<void>> deleteFeedStock(String id);
  Future<Result<List<FeedMovement>>> getMovements(String feedStockId);
  Future<Result<FeedMovement>> addMovement(FeedMovement movement);
}
