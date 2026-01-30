import '../../../../core/core.dart';
import '../entities/feed_stock.dart';
import '../repositories/feed_stock_repository.dart';

// Get all feed stocks
class GetFeedStocks extends UseCase<List<FeedStock>, NoParams> {
  final FeedStockRepository repository;

  GetFeedStocks(this.repository);

  @override
  Future<Result<List<FeedStock>>> call(NoParams params) {
    return repository.getFeedStocks();
  }
}

// Get feed stock by ID
class GetFeedStockByIdParams {
  final String id;
  const GetFeedStockByIdParams({required this.id});
}

class GetFeedStockById extends UseCase<FeedStock, GetFeedStockByIdParams> {
  final FeedStockRepository repository;

  GetFeedStockById(this.repository);

  @override
  Future<Result<FeedStock>> call(GetFeedStockByIdParams params) {
    return repository.getFeedStockById(params.id);
  }
}

// Get low stock items
class GetLowStockItems extends UseCase<List<FeedStock>, NoParams> {
  final FeedStockRepository repository;

  GetLowStockItems(this.repository);

  @override
  Future<Result<List<FeedStock>>> call(NoParams params) {
    return repository.getLowStockItems();
  }
}

// Create feed stock
class CreateFeedStockParams {
  final FeedStock stock;
  const CreateFeedStockParams({required this.stock});
}

class CreateFeedStock extends UseCase<FeedStock, CreateFeedStockParams> {
  final FeedStockRepository repository;

  CreateFeedStock(this.repository);

  @override
  Future<Result<FeedStock>> call(CreateFeedStockParams params) {
    return repository.createFeedStock(params.stock);
  }
}

// Update feed stock
class UpdateFeedStockParams {
  final FeedStock stock;
  const UpdateFeedStockParams({required this.stock});
}

class UpdateFeedStock extends UseCase<FeedStock, UpdateFeedStockParams> {
  final FeedStockRepository repository;

  UpdateFeedStock(this.repository);

  @override
  Future<Result<FeedStock>> call(UpdateFeedStockParams params) {
    return repository.updateFeedStock(params.stock);
  }
}

// Delete feed stock
class DeleteFeedStockParams {
  final String id;
  const DeleteFeedStockParams({required this.id});
}

class DeleteFeedStock extends UseCase<void, DeleteFeedStockParams> {
  final FeedStockRepository repository;

  DeleteFeedStock(this.repository);

  @override
  Future<Result<void>> call(DeleteFeedStockParams params) {
    return repository.deleteFeedStock(params.id);
  }
}

// Get movements for a feed stock
class GetFeedMovementsParams {
  final String feedStockId;
  const GetFeedMovementsParams({required this.feedStockId});
}

class GetFeedMovements extends UseCase<List<FeedMovement>, GetFeedMovementsParams> {
  final FeedStockRepository repository;

  GetFeedMovements(this.repository);

  @override
  Future<Result<List<FeedMovement>>> call(GetFeedMovementsParams params) {
    return repository.getMovements(params.feedStockId);
  }
}

// Add movement
class AddFeedMovementParams {
  final FeedMovement movement;
  const AddFeedMovementParams({required this.movement});
}

class AddFeedMovement extends UseCase<FeedMovement, AddFeedMovementParams> {
  final FeedStockRepository repository;

  AddFeedMovement(this.repository);

  @override
  Future<Result<FeedMovement>> call(AddFeedMovementParams params) {
    return repository.addMovement(params.movement);
  }
}
