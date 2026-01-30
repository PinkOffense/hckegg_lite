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
      return Result.success(stocks);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> getFeedStockById(String id) async {
    try {
      final stock = await remoteDataSource.getFeedStockById(id);
      return Result.success(stock);
    } catch (e) {
      if (e.toString().contains('no rows')) {
        return Result.fail(NotFoundFailure(message: 'Feed stock not found'));
      }
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FeedStock>>> getLowStockItems() async {
    try {
      final stocks = await remoteDataSource.getLowStockItems();
      return Result.success(stocks);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> createFeedStock(FeedStock stock) async {
    try {
      final model = FeedStockModel.fromEntity(stock);
      final created = await remoteDataSource.createFeedStock(model);
      return Result.success(created);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedStock>> updateFeedStock(FeedStock stock) async {
    try {
      final model = FeedStockModel.fromEntity(stock);
      final updated = await remoteDataSource.updateFeedStock(model);
      return Result.success(updated);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFeedStock(String id) async {
    try {
      await remoteDataSource.deleteFeedStock(id);
      return Result.success(null);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FeedMovement>>> getMovements(String feedStockId) async {
    try {
      final movements = await remoteDataSource.getMovements(feedStockId);
      return Result.success(movements);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FeedMovement>> addMovement(FeedMovement movement) async {
    try {
      final model = FeedMovementModel.fromEntity(movement);
      final created = await remoteDataSource.addMovement(model);
      return Result.success(created);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }
}
