import '../../../../core/core.dart';
import '../../domain/entities/egg_sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sale_remote_datasource.dart';
import '../models/egg_sale_model.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDataSource remoteDataSource;

  SaleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<EggSale>>> getSales() async {
    try {
      final sales = await remoteDataSource.getSales();
      return Success(sales.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggSale>> getSaleById(String id) async {
    try {
      final sale = await remoteDataSource.getSaleById(id);
      return Success(sale.toEntity());
    } catch (e) {
      return Fail(NotFoundFailure(message: 'Sale not found'));
    }
  }

  @override
  Future<Result<List<EggSale>>> getSalesByDateRange({required String startDate, required String endDate}) async {
    try {
      final sales = await remoteDataSource.getSalesByDateRange(startDate: startDate, endDate: endDate);
      return Success(sales.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<EggSale>>> getPendingPayments() async {
    try {
      final sales = await remoteDataSource.getPendingPayments();
      return Success(sales.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<EggSale>>> getLostSales() async {
    try {
      final sales = await remoteDataSource.getLostSales();
      return Success(sales.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggSale>> createSale(EggSale sale) async {
    try {
      final model = EggSaleModel.fromEntity(sale);
      final created = await remoteDataSource.createSale(model);
      return Success(created.toEntity());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggSale>> updateSale(EggSale sale) async {
    try {
      final model = EggSaleModel.fromEntity(sale);
      final updated = await remoteDataSource.updateSale(model);
      return Success(updated.toEntity());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteSale(String id) async {
    try {
      await remoteDataSource.deleteSale(id);
      return const Success(null);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsPaid(String id, String paymentDate) async {
    try {
      await remoteDataSource.markAsPaid(id, paymentDate);
      return const Success(null);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsLost(String id) async {
    try {
      await remoteDataSource.markAsLost(id);
      return const Success(null);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }
}
