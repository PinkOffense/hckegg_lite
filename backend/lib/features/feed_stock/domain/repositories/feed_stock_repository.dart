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

class FeedStockStatistics {
  const FeedStockStatistics({
    required this.totalStocks,
    required this.lowStockCount,
    required this.totalQuantityKg,
    required this.byType,
  });

  final int totalStocks;
  final int lowStockCount;
  final double totalQuantityKg;
  final Map<String, FeedTypeStats> byType;

  Map<String, dynamic> toJson() => {
        'total_stocks': totalStocks,
        'low_stock_count': lowStockCount,
        'total_quantity_kg': totalQuantityKg,
        'by_type': byType.map((k, v) => MapEntry(k, v.toJson())),
      };
}

class FeedTypeStats {
  const FeedTypeStats({
    required this.count,
    required this.quantityKg,
  });

  final int count;
  final double quantityKg;

  Map<String, dynamic> toJson() => {
        'count': count,
        'quantity_kg': quantityKg,
      };
}
