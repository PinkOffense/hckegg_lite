import '../../../../core/core.dart';
import '../../domain/entities/feed_stock.dart';
import '../../domain/repositories/feed_stock_repository.dart';
import '../datasources/feed_stock_remote_datasource.dart';
import '../models/feed_stock_model.dart';

class FeedStockRepositoryImpl implements FeedStockRepository {
  final FeedStockRemoteDataSource remoteDataSource;

  FeedStockRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<FeedStock>>> getFeedStocks() async {
    try {
      final stocks = await remoteDataSource.getFeedStocks();
      return Success(stocks);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> getFeedStockById(String id) async {
    try {
      final stock = await remoteDataSource.getFeedStockById(id);
      return Success(stock);
    } catch (e) {
      if (e.toString().contains('no rows')) {
        return Fail(NotFoundFailure(message: 'Feed stock not found'));
      }
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FeedStock>>> getLowStockItems() async {
    try {
      final stocks = await remoteDataSource.getLowStockItems();
      return Success(stocks);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> createFeedStock(FeedStock stock) async {
    try {
      final model = FeedStockModel.fromEntity(stock);
      final created = await remoteDataSource.createFeedStock(model);
      return Success(created);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> updateFeedStock(FeedStock stock) async {
    try {
      final model = FeedStockModel.fromEntity(stock);
      final updated = await remoteDataSource.updateFeedStock(model);
      return Success(updated);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFeedStock(String id) async {
    try {
      await remoteDataSource.deleteFeedStock(id);
      return const Success(null);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FeedMovement>>> getMovements(String feedStockId) async {
    try {
      final movements = await remoteDataSource.getMovements(feedStockId);
      return Success(movements);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedMovement>> addMovement(FeedMovement movement) async {
    try {
      final model = FeedMovementModel.fromEntity(movement);
      final created = await remoteDataSource.addMovement(model);
      return Success(created);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }
}
