import '../../../../core/core.dart';
import '../entities/sale.dart';

abstract class SaleRepository {
  Future<Result<List<Sale>>> getSales(String userId, {String? farmId});
  Future<Result<Sale>> getSaleById(String id);
  Future<Result<List<Sale>>> getSalesInRange(String userId, String startDate, String endDate, {String? farmId});
  Future<Result<List<Sale>>> getPendingPayments(String userId, {String? farmId});
  Future<Result<List<Sale>>> getLostSales(String userId, {String? farmId});
  Future<Result<Sale>> createSale(Sale sale);
  Future<Result<Sale>> updateSale(Sale sale);
  Future<Result<void>> deleteSale(String id);
  Future<Result<void>> markAsPaid(String id, String paymentDate);
  Future<Result<void>> markAsLost(String id);
  Future<Result<SaleStatistics>> getStatistics(String userId, String startDate, String endDate, {String? farmId});
}

class SaleStatistics {
  const SaleStatistics({
    required this.totalSales,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.totalPending,
    required this.totalLost,
    required this.averagePrice,
  });

  final int totalSales;
  final int totalQuantity;
  final double totalRevenue;
  final double totalPending;
  final double totalLost;
  final double averagePrice;

  Map<String, dynamic> toJson() => {
        'total_sales': totalSales,
        'total_quantity': totalQuantity,
        'total_revenue': totalRevenue,
        'total_pending': totalPending,
        'total_lost': totalLost,
        'average_price': averagePrice,
      };
}
