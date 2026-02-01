import '../../../../core/core.dart';
import '../entities/sale.dart';
import '../repositories/sale_repository.dart';

class GetSales implements UseCase<List<Sale>, GetSalesParams> {
  GetSales(this.repository);
  final SaleRepository repository;

  @override
  Future<Result<List<Sale>>> call(GetSalesParams params) =>
      repository.getSales(params.userId);
}

class GetSalesParams {
  const GetSalesParams({required this.userId});
  final String userId;
}

class GetSaleById implements UseCase<Sale, GetSaleByIdParams> {
  GetSaleById(this.repository);
  final SaleRepository repository;

  @override
  Future<Result<Sale>> call(GetSaleByIdParams params) =>
      repository.getSaleById(params.id);
}

class GetSaleByIdParams {
  const GetSaleByIdParams({required this.id});
  final String id;
}

class CreateSale implements UseCase<Sale, CreateSaleParams> {
  CreateSale(this.repository);
  final SaleRepository repository;

  @override
  Future<Result<Sale>> call(CreateSaleParams params) =>
      repository.createSale(params.sale);
}

class CreateSaleParams {
  const CreateSaleParams({required this.sale});
  final Sale sale;
}

class UpdateSale implements UseCase<Sale, UpdateSaleParams> {
  UpdateSale(this.repository);
  final SaleRepository repository;

  @override
  Future<Result<Sale>> call(UpdateSaleParams params) =>
      repository.updateSale(params.sale);
}

class UpdateSaleParams {
  const UpdateSaleParams({required this.sale});
  final Sale sale;
}

class DeleteSale implements UseCase<void, DeleteSaleParams> {
  DeleteSale(this.repository);
  final SaleRepository repository;

  @override
  Future<Result<void>> call(DeleteSaleParams params) =>
      repository.deleteSale(params.id);
}

class DeleteSaleParams {
  const DeleteSaleParams({required this.id});
  final String id;
}

class MarkSaleAsPaid implements UseCase<void, MarkAsPaidParams> {
  MarkSaleAsPaid(this.repository);
  final SaleRepository repository;

  @override
  Future<Result<void>> call(MarkAsPaidParams params) =>
      repository.markAsPaid(params.id, params.paymentDate);
}

class MarkAsPaidParams {
  const MarkAsPaidParams({required this.id, required this.paymentDate});
  final String id;
  final String paymentDate;
}

class MarkSaleAsLost implements UseCase<void, MarkAsLostParams> {
  MarkSaleAsLost(this.repository);
  final SaleRepository repository;

  @override
  Future<Result<void>> call(MarkAsLostParams params) =>
      repository.markAsLost(params.id);
}

class MarkAsLostParams {
  const MarkAsLostParams({required this.id});
  final String id;
}

class GetSaleStatistics implements UseCase<SaleStatistics, GetSaleStatisticsParams> {
  GetSaleStatistics(this.repository);
  final SaleRepository repository;

  @override
  Future<Result<SaleStatistics>> call(GetSaleStatisticsParams params) =>
      repository.getStatistics(params.userId, params.startDate, params.endDate);
}

class GetSaleStatisticsParams {
  const GetSaleStatisticsParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });
  final String userId;
  final String startDate;
  final String endDate;
}
