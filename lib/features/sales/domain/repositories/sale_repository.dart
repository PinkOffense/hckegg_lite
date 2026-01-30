import '../../../../core/core.dart';
import '../entities/egg_sale.dart';

/// Repository interface for egg sales
abstract class SaleRepository {
  Future<Result<List<EggSale>>> getSales();
  Future<Result<EggSale>> getSaleById(String id);
  Future<Result<List<EggSale>>> getSalesByDateRange({
    required String startDate,
    required String endDate,
  });
  Future<Result<List<EggSale>>> getPendingPayments();
  Future<Result<List<EggSale>>> getLostSales();
  Future<Result<EggSale>> createSale(EggSale sale);
  Future<Result<EggSale>> updateSale(EggSale sale);
  Future<Result<void>> deleteSale(String id);
  Future<Result<void>> markAsPaid(String id, String paymentDate);
  Future<Result<void>> markAsLost(String id);
}
