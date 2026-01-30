// lib/core/base_provider.dart

import 'package:flutter/foundation.dart';

/// State for data loading operations
enum LoadingState {
  initial,
  loading,
  loaded,
  error,
}

/// Base class for data providers following clean architecture
///
/// Provides common functionality for:
/// - Loading state management
/// - Error handling
/// - Data caching patterns
/// - Notification of listeners
abstract class BaseDataProvider<T> extends ChangeNotifier {
  // ============================================
  // State Management
  // ============================================

  LoadingState _state = LoadingState.initial;
  LoadingState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Alias for backward compatibility

  bool get isLoading => _state == LoadingState.loading;
  bool get hasError => _errorMessage != null;
  bool get isInitial => _state == LoadingState.initial;
  bool get isLoaded => _state == LoadingState.loaded;

  // ============================================
  // Data Storage
  // ============================================

  final List<T> _items = [];

  /// Get unmodifiable list of items
  List<T> get items => List.unmodifiable(_items);

  /// Get the count of items
  int get itemCount => _items.length;

  /// Check if there are no items
  bool get isEmpty => _items.isEmpty;

  /// Check if there are items
  bool get isNotEmpty => _items.isNotEmpty;

  // ============================================
  // Protected Methods for Subclasses
  // ============================================

  /// Set loading state
  @protected
  void setLoading() {
    _state = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loaded state with data
  @protected
  void setLoaded(List<T> data) {
    _items.clear();
    _items.addAll(data);
    _state = LoadingState.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set error state
  @protected
  void setError(String message) {
    _state = LoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Add a single item
  @protected
  void addItem(T item) {
    _items.add(item);
    invalidateCache();
    notifyListeners();
  }

  /// Update an item by finding it with the matcher
  @protected
  void updateItem(T item, bool Function(T) matcher) {
    final index = _items.indexWhere(matcher);
    if (index != -1) {
      _items[index] = item;
      invalidateCache();
      notifyListeners();
    }
  }

  /// Remove an item by finding it with the matcher
  @protected
  void removeItem(bool Function(T) matcher) {
    _items.removeWhere(matcher);
    invalidateCache();
    notifyListeners();
  }

  /// Add or update item based on existence
  @protected
  void upsertItem(T item, bool Function(T) existsMatcher) {
    final index = _items.indexWhere(existsMatcher);
    if (index != -1) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    invalidateCache();
    notifyListeners();
  }

  // ============================================
  // Cache Management
  // ============================================

  /// Override in subclasses to clear cached computed values
  @protected
  void invalidateCache() {
    // Override in subclasses
  }

  // ============================================
  // Public Methods
  // ============================================

  /// Clear all data and reset state
  void clearData() {
    _items.clear();
    _state = LoadingState.initial;
    _errorMessage = null;
    invalidateCache();
    notifyListeners();
  }

  /// Load data - must be implemented by subclasses
  Future<void> loadData();

  // ============================================
  // Error Handling Utilities
  // ============================================

  /// Execute an async operation with error handling
  @protected
  Future<R?> executeWithErrorHandling<R>(
    Future<R> Function() operation, {
    bool setLoadingState = false,
    bool rethrowError = false,
  }) async {
    if (setLoadingState) {
      setLoading();
    }

    try {
      final result = await operation();
      return result;
    } catch (e) {
      setError(e.toString());
      if (rethrowError) rethrow;
      return null;
    }
  }
}

/// Mixin for providers that need to compute totals
mixin TotalComputationMixin<T> on BaseDataProvider<T> {
  /// Compute sum of a numeric property
  double computeSum(double Function(T) selector) {
    return items.fold(0.0, (sum, item) => sum + selector(item));
  }

  /// Compute sum of an integer property
  int computeIntSum(int Function(T) selector) {
    return items.fold(0, (sum, item) => sum + selector(item));
  }

  /// Count items matching a condition
  int countWhere(bool Function(T) predicate) {
    return items.where(predicate).length;
  }
}

/// Mixin for providers that need date filtering
mixin DateFilterMixin<T> on BaseDataProvider<T> {
  /// Get items within a date range
  List<T> getItemsInRange(
    DateTime start,
    DateTime end,
    DateTime Function(T) dateSelector,
  ) {
    return items.where((item) {
      final date = dateSelector(item);
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  /// Get items for today
  List<T> getTodayItems(DateTime Function(T) dateSelector) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return getItemsInRange(today, tomorrow, dateSelector);
  }

  /// Get items for this month
  List<T> getThisMonthItems(DateTime Function(T) dateSelector) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
    return getItemsInRange(startOfMonth, startOfNextMonth, dateSelector);
  }
}
