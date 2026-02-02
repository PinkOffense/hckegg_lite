import '../../../../core/core.dart';
import '../entities/feed_stock.dart';

abstract class FeedStockRepository {
  // Feed Stock operations
  Future<Result<List<FeedStock>>> getFeedStocks(String userId);
  Future<Result<FeedStock>> getFeedStockById(String id);
  Future<Result<List<FeedStock>>> getLowStockItems(String userId);
  Future<Result<FeedStock>> createFeedStock(FeedStock feedStock);
  Future<Result<FeedStock>> updateFeedStock(FeedStock feedStock);
  Future<Result<void>> deleteFeedStock(String id);

  // Feed Movement operations
  Future<Result<List<FeedMovement>>> getFeedMovements(
    String userId,
    String feedStockId,
  );
  Future<Result<FeedMovement>> addFeedMovement(FeedMovement movement);
}
