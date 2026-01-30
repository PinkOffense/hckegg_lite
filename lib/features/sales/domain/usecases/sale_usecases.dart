import '../../../../core/core.dart';
import '../entities/egg_sale.dart';
import '../repositories/sale_repository.dart';

class GetSales implements UseCase<List<EggSale>, NoParams> {
  final SaleRepository repository;
  GetSales(this.repository);

  @override
  Future<Result<List<EggSale>>> call(NoParams params) => repository.getSales();
}

class GetPendingPayments implements UseCase<List<EggSale>, NoParams> {
  final SaleRepository repository;
  GetPendingPayments(this.repository);

  @override
  Future<Result<List<EggSale>>> call(NoParams params) => repository.getPendingPayments();
}

class GetLostSales implements UseCase<List<EggSale>, NoParams> {
  final SaleRepository repository;
  GetLostSales(this.repository);

  @override
  Future<Result<List<EggSale>>> call(NoParams params) => repository.getLostSales();
}

class CreateSale implements UseCase<EggSale, CreateSaleParams> {
  final SaleRepository repository;
  CreateSale(this.repository);

  @override
  Future<Result<EggSale>> call(CreateSaleParams params) => repository.createSale(params.sale);
}

class CreateSaleParams {
  final EggSale sale;
  const CreateSaleParams({required this.sale});
}

class UpdateSale implements UseCase<EggSale, UpdateSaleParams> {
  final SaleRepository repository;
  UpdateSale(this.repository);

  @override
  Future<Result<EggSale>> call(UpdateSaleParams params) => repository.updateSale(params.sale);
}

class UpdateSaleParams {
  final EggSale sale;
  const UpdateSaleParams({required this.sale});
}

class DeleteSale implements UseCase<void, DeleteSaleParams> {
  final SaleRepository repository;
  DeleteSale(this.repository);

  @override
  Future<Result<void>> call(DeleteSaleParams params) => repository.deleteSale(params.id);
}

class DeleteSaleParams {
  final String id;
  const DeleteSaleParams({required this.id});
}

class MarkSaleAsPaid implements UseCase<void, MarkAsPaidParams> {
  final SaleRepository repository;
  MarkSaleAsPaid(this.repository);

  @override
  Future<Result<void>> call(MarkAsPaidParams params) =>
      repository.markAsPaid(params.id, params.paymentDate);
}

class MarkAsPaidParams {
  final String id;
  final String paymentDate;
  const MarkAsPaidParams({required this.id, required this.paymentDate});
}

class MarkSaleAsLost implements UseCase<void, MarkAsLostParams> {
  final SaleRepository repository;
  MarkSaleAsLost(this.repository);

  @override
  Future<Result<void>> call(MarkAsLostParams params) => repository.markAsLost(params.id);
}

class MarkAsLostParams {
  final String id;
  const MarkAsLostParams({required this.id});
}
