import '../../../../core/core.dart';
import '../entities/feed_stock.dart';

abstract class FeedStockRepository {
  Future<Result<List<FeedStock>>> getFeedStocks(String userId);
  Future<Result<FeedStock>> getFeedStockById(String id);
  Future<Result<List<FeedStock>>> getFeedStocksInRange(String userId, String startDate, String endDate);
  Future<Result<List<FeedStock>>> getFeedStocksByType(String userId, String feedType);
  Future<Result<FeedStock>> createFeedStock(FeedStock feedStock);
  Future<Result<FeedStock>> updateFeedStock(FeedStock feedStock);
  Future<Result<void>> deleteFeedStock(String id);
  Future<Result<FeedStockStatistics>> getStatistics(String userId, String startDate, String endDate);
}

class FeedStockStatistics {
  const FeedStockStatistics({
    required this.totalRecords,
    required this.totalQuantityKg,
    required this.totalCost,
    required this.byFeedType,
  });

  final int totalRecords;
  final double totalQuantityKg;
  final double totalCost;
  final Map<String, FeedTypeStats> byFeedType;

  Map<String, dynamic> toJson() => {
        'total_records': totalRecords,
        'total_quantity_kg': totalQuantityKg,
        'total_cost': totalCost,
        'by_feed_type': byFeedType.map((k, v) => MapEntry(k, v.toJson())),
      };
}

class FeedTypeStats {
  const FeedTypeStats({
    required this.quantityKg,
    required this.cost,
  });

  final double quantityKg;
  final double cost;

  Map<String, dynamic> toJson() => {
        'quantity_kg': quantityKg,
        'cost': cost,
      };
}
