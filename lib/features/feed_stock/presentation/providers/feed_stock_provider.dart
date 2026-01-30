import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/domain.dart';

/// State for the feed stock feature
enum FeedStockState { initial, loading, loaded, error }

/// Provider for feed stock following clean architecture
class FeedStockProvider extends ChangeNotifier {
  final GetFeedStocks _getFeedStocks;
  final GetLowStockItems _getLowStockItems;
  final CreateFeedStock _createFeedStock;
  final UpdateFeedStock _updateFeedStock;
  final DeleteFeedStock _deleteFeedStock;
  final GetFeedMovements _getFeedMovements;
  final AddFeedMovement _addFeedMovement;

  FeedStockProvider({
    required GetFeedStocks getFeedStocks,
    required GetLowStockItems getLowStockItems,
    required CreateFeedStock createFeedStock,
    required UpdateFeedStock updateFeedStock,
    required DeleteFeedStock deleteFeedStock,
    required GetFeedMovements getFeedMovements,
    required AddFeedMovement addFeedMovement,
  })  : _getFeedStocks = getFeedStocks,
        _getLowStockItems = getLowStockItems,
        _createFeedStock = createFeedStock,
        _updateFeedStock = updateFeedStock,
        _deleteFeedStock = deleteFeedStock,
        _getFeedMovements = getFeedMovements,
        _addFeedMovement = addFeedMovement;

  // State
  FeedStockState _state = FeedStockState.initial;
  FeedStockState get state => _state;

  List<FeedStock> _feedStocks = [];
  List<FeedStock> get feedStocks => List.unmodifiable(_feedStocks);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Backward compatibility

  bool get isLoading => _state == FeedStockState.loading;
  bool get hasError => _state == FeedStockState.error;

  // Cached statistics
  double? _cachedTotalFeed;
  int? _cachedLowStockCount;
  double _totalFeedConsumed = 0.0;

  double get totalFeedStock {
    _cachedTotalFeed ??= _feedStocks.fold<double>(0.0, (sum, s) => sum + s.currentQuantityKg);
    return _cachedTotalFeed!;
  }

  int get lowStockCount {
    _cachedLowStockCount ??= _feedStocks.where((s) => s.isLowStock).length;
    return _cachedLowStockCount!;
  }

  double get totalFeedConsumed => _totalFeedConsumed;

  void _invalidateCache() {
    _cachedTotalFeed = null;
    _cachedLowStockCount = null;
  }

  /// Load all feed stocks
  Future<void> loadFeedStocks() async {
    _state = FeedStockState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _getFeedStocks(const NoParams());

    await result.fold(
      onSuccess: (data) async {
        _feedStocks = data;
        _invalidateCache();

        // Load total consumed from all movements
        _totalFeedConsumed = 0.0;
        for (final stock in _feedStocks) {
          final movementsResult = await _getFeedMovements(
            GetFeedMovementsParams(feedStockId: stock.id),
          );
          movementsResult.fold(
            onSuccess: (movements) {
              for (final movement in movements) {
                if (movement.movementType == StockMovementType.consumption ||
                    movement.movementType == StockMovementType.loss) {
                  _totalFeedConsumed += movement.quantityKg;
                }
              }
            },
            onFailure: (_) {},
          );
        }

        _state = FeedStockState.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = FeedStockState.error;
      },
    );

    notifyListeners();
  }

  /// Get low stock items
  Future<List<FeedStock>> getLowStockItems() async {
    final result = await _getLowStockItems(const NoParams());
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (_) => [],
    );
  }

  /// Get low stock items (local filtering)
  List<FeedStock> getLowStockFeeds() {
    return _feedStocks.where((s) => s.isLowStock).toList();
  }

  /// Pesquisar stocks de ração por tipo, marca ou notas
  List<FeedStock> search(String query) {
    if (query.isEmpty) return _feedStocks;
    final q = query.toLowerCase();
    return _feedStocks.where((stock) {
      final typeMatch = stock.type.name.toLowerCase().contains(q);
      final brandMatch = stock.brand?.toLowerCase().contains(q) ?? false;
      final notesMatch = stock.notes?.toLowerCase().contains(q) ?? false;
      return typeMatch || brandMatch || notesMatch;
    }).toList();
  }

  /// Save a feed stock (create or update)
  Future<bool> saveFeedStock(FeedStock stock) async {
    _state = FeedStockState.loading;
    notifyListeners();

    final Result<FeedStock> result;

    if (stock.id.isEmpty || !_feedStocks.any((s) => s.id == stock.id)) {
      result = await _createFeedStock(CreateFeedStockParams(stock: stock));
    } else {
      result = await _updateFeedStock(UpdateFeedStockParams(stock: stock));
    }

    final success = result.fold(
      onSuccess: (savedStock) {
        final index = _feedStocks.indexWhere((s) => s.id == savedStock.id);
        if (index >= 0) {
          _feedStocks[index] = savedStock;
        } else {
          _feedStocks.add(savedStock);
        }
        _invalidateCache();
        _state = FeedStockState.loaded;
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = FeedStockState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
  }

  /// Delete a feed stock
  Future<bool> deleteFeedStock(String id) async {
    _state = FeedStockState.loading;
    notifyListeners();

    final result = await _deleteFeedStock(DeleteFeedStockParams(id: id));

    final success = result.fold(
      onSuccess: (_) {
        _feedStocks.removeWhere((s) => s.id == id);
        _invalidateCache();
        _state = FeedStockState.loaded;
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = FeedStockState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
  }

  /// Add movement (purchase, consumption, etc.)
  Future<bool> addFeedMovement(FeedMovement movement, FeedStock stock) async {
    _state = FeedStockState.loading;
    notifyListeners();

    final movementResult = await _addFeedMovement(
      AddFeedMovementParams(movement: movement),
    );

    final success = await movementResult.fold(
      onSuccess: (savedMovement) async {
        double newQuantity = stock.currentQuantityKg;
        if (movement.movementType == StockMovementType.purchase) {
          newQuantity += movement.quantityKg;
        } else {
          newQuantity -= movement.quantityKg;
          if (movement.movementType == StockMovementType.consumption ||
              movement.movementType == StockMovementType.loss) {
            _totalFeedConsumed += movement.quantityKg;
          }
        }

        final updatedStock = stock.copyWith(
          currentQuantityKg: newQuantity < 0 ? 0 : newQuantity,
          lastUpdated: DateTime.now(),
        );

        final updateResult = await _updateFeedStock(
          UpdateFeedStockParams(stock: updatedStock),
        );

        return updateResult.fold(
          onSuccess: (saved) {
            final index = _feedStocks.indexWhere((s) => s.id == saved.id);
            if (index >= 0) {
              _feedStocks[index] = saved;
            }
            _invalidateCache();
            _state = FeedStockState.loaded;
            return true;
          },
          onFailure: (failure) {
            _errorMessage = failure.message;
            _state = FeedStockState.error;
            return false;
          },
        );
      },
      onFailure: (failure) async {
        _errorMessage = failure.message;
        _state = FeedStockState.error;
        return false;
      },
    );

    notifyListeners();
    return success;
  }

  /// Get movements for a stock
  Future<List<FeedMovement>> getFeedMovements(String feedStockId) async {
    final result = await _getFeedMovements(
      GetFeedMovementsParams(feedStockId: feedStockId),
    );
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (_) => [],
    );
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data (used on logout)
  void clearData() {
    _feedStocks = [];
    _errorMessage = null;
    _state = FeedStockState.initial;
    _totalFeedConsumed = 0.0;
    _invalidateCache();
    notifyListeners();
  }
}
