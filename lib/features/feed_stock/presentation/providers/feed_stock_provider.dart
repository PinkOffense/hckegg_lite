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
  String? get error => _errorMessage;

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

    try {
      final result = await _getFeedStocks(const NoParams());

      if (result.isSuccess) {
        _feedStocks = List.from(result.value);
        _invalidateCache();
        _state = FeedStockState.loaded;
        notifyListeners();

        // Load total consumed in background - don't block UI
        _loadTotalConsumedInBackground();
      } else {
        _errorMessage = result.failure.message;
        _state = FeedStockState.error;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = FeedStockState.error;
      notifyListeners();
    }
  }

  /// Load total consumed from movements in background (non-blocking)
  void _loadTotalConsumedInBackground() {
    // Fire and forget - runs in parallel, updates UI when done
    _loadTotalConsumedParallel().then((_) {
      notifyListeners();
    });
  }

  /// Load total consumed from movements - parallelized for performance
  Future<void> _loadTotalConsumedParallel() async {
    if (_feedStocks.isEmpty) {
      _totalFeedConsumed = 0.0;
      return;
    }

    // Load all movements in parallel instead of sequentially
    final futures = _feedStocks.map((stock) async {
      try {
        final movementsResult = await _getFeedMovements(
          GetFeedMovementsParams(feedStockId: stock.id),
        );
        if (movementsResult.isSuccess) {
          double consumed = 0.0;
          for (final movement in movementsResult.value) {
            if (movement.movementType == StockMovementType.consumption ||
                movement.movementType == StockMovementType.loss) {
              consumed += movement.quantityKg;
            }
          }
          return consumed;
        }
      } catch (_) {
        // Ignore movement loading errors
      }
      return 0.0;
    });

    final results = await Future.wait(futures);
    _totalFeedConsumed = results.fold(0.0, (sum, value) => sum + value);
  }

  /// Get low stock items
  Future<List<FeedStock>> getLowStockItems() async {
    final result = await _getLowStockItems(const NoParams());
    return result.isSuccess ? result.value : [];
  }

  /// Get low stock items (local filtering)
  List<FeedStock> getLowStockFeeds() {
    return _feedStocks.where((s) => s.isLowStock).toList();
  }

  /// Search stocks by type, brand or notes
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

    try {
      final isNew = stock.id.isEmpty || !_feedStocks.any((s) => s.id == stock.id);
      final Result<FeedStock> result = isNew
          ? await _createFeedStock(CreateFeedStockParams(stock: stock))
          : await _updateFeedStock(UpdateFeedStockParams(stock: stock));

      if (result.isSuccess) {
        final savedStock = result.value;
        final index = _feedStocks.indexWhere((s) => s.id == savedStock.id);
        _feedStocks = List.from(_feedStocks);
        if (index >= 0) {
          _feedStocks[index] = savedStock;
        } else {
          _feedStocks.add(savedStock);
        }
        _invalidateCache();
        _state = FeedStockState.loaded;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.failure.message;
        _state = FeedStockState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = FeedStockState.error;
      notifyListeners();
      return false;
    }
  }

  /// Delete a feed stock
  Future<bool> deleteFeedStock(String id) async {
    _state = FeedStockState.loading;
    notifyListeners();

    try {
      final result = await _deleteFeedStock(DeleteFeedStockParams(id: id));

      if (result.isSuccess) {
        _feedStocks = _feedStocks.where((s) => s.id != id).toList();
        _invalidateCache();
        _state = FeedStockState.loaded;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.failure.message;
        _state = FeedStockState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = FeedStockState.error;
      notifyListeners();
      return false;
    }
  }

  /// Add movement (purchase, consumption, etc.)
  Future<bool> addFeedMovement(FeedMovement movement, FeedStock stock) async {
    _state = FeedStockState.loading;
    notifyListeners();

    try {
      // First, save the movement
      final movementResult = await _addFeedMovement(
        AddFeedMovementParams(movement: movement),
      );

      if (!movementResult.isSuccess) {
        _errorMessage = movementResult.failure.message;
        _state = FeedStockState.error;
        notifyListeners();
        return false;
      }

      // Calculate new quantity
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

      // Update stock with new quantity
      final updatedStock = stock.copyWith(
        currentQuantityKg: newQuantity < 0 ? 0 : newQuantity,
        lastUpdated: DateTime.now(),
      );

      final updateResult = await _updateFeedStock(
        UpdateFeedStockParams(stock: updatedStock),
      );

      if (updateResult.isSuccess) {
        final saved = updateResult.value;
        final index = _feedStocks.indexWhere((s) => s.id == saved.id);
        if (index >= 0) {
          _feedStocks = List.from(_feedStocks);
          _feedStocks[index] = saved;
        }
        _invalidateCache();
        _state = FeedStockState.loaded;
        notifyListeners();
        return true;
      } else {
        _errorMessage = updateResult.failure.message;
        _state = FeedStockState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = FeedStockState.error;
      notifyListeners();
      return false;
    }
  }

  /// Get movements for a stock
  Future<List<FeedMovement>> getFeedMovements(String feedStockId) async {
    try {
      final result = await _getFeedMovements(
        GetFeedMovementsParams(feedStockId: feedStockId),
      );
      return result.isSuccess ? result.value : [];
    } catch (_) {
      return [];
    }
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
