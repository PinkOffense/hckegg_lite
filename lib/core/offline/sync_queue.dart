// lib/core/offline/sync_queue.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Types of sync operations
enum SyncOperationType { create, update, delete }

/// A queued operation waiting to be synced
class SyncOperation {
  final String id;
  final String entityType;
  final String entityId;
  final SyncOperationType operationType;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  String? lastError;

  SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.lastError,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'operationType': operationType.name,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operationType: SyncOperationType.values.byName(json['operationType'] as String),
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? serverData;

  const SyncResult.success([this.serverData]) : success = true, error = null;
  const SyncResult.failure(this.error) : success = false, serverData = null;
}

/// Handler for syncing a specific entity type
typedef SyncHandler = Future<SyncResult> Function(SyncOperation operation);

/// Interface for connectivity checking (for testability)
abstract class ConnectivityChecker {
  bool get isOnline;
  Stream<bool> get onConnectivityChanged;
}

/// Sync queue for offline-first functionality
/// Queues operations when offline and syncs when connection is restored
class SyncQueue extends ChangeNotifier {
  /// Singleton instance for production use
  static final SyncQueue _instance = SyncQueue._internal(null);

  /// Factory constructor returns singleton
  factory SyncQueue() => _instance;

  /// Create a test instance with custom connectivity checker
  factory SyncQueue.forTesting({ConnectivityChecker? connectivity}) {
    return SyncQueue._internal(connectivity);
  }

  SyncQueue._internal(this._connectivity);

  final List<SyncOperation> _queue = [];
  final Map<String, SyncHandler> _handlers = {};
  final ConnectivityChecker? _connectivity;

  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySubscription;

  /// Maximum retry attempts before giving up on an operation
  static const int maxRetries = 5;

  /// Delay between retries (exponential backoff)
  static Duration retryDelay(int attempt) => Duration(
        seconds: (2 << attempt).clamp(1, 60),
      );

  /// Current queue
  List<SyncOperation> get queue => List.unmodifiable(_queue);

  /// Number of pending operations
  int get pendingCount => _queue.length;

  /// Whether sync is in progress
  bool get isSyncing => _isSyncing;

  /// Initialize the sync queue
  void initialize() {
    if (_connectivity != null) {
      _connectivitySubscription = _connectivity!.onConnectivityChanged.listen((online) {
        if (online && _queue.isNotEmpty) {
          processQueue();
        }
      });
    }
  }

  /// Register a handler for a specific entity type
  void registerHandler(String entityType, SyncHandler handler) {
    _handlers[entityType] = handler;
  }

  /// Unregister a handler
  void unregisterHandler(String entityType) {
    _handlers.remove(entityType);
  }

  /// Add an operation to the queue
  void enqueue(SyncOperation operation) {
    // Check for existing operation on same entity (merge/deduplicate)
    final existingIndex = _queue.indexWhere(
      (op) => op.entityType == operation.entityType && op.entityId == operation.entityId,
    );

    if (existingIndex >= 0) {
      final existing = _queue[existingIndex];
      // Handle merge logic
      if (existing.operationType == SyncOperationType.create) {
        if (operation.operationType == SyncOperationType.update) {
          // Merge update into create
          _queue[existingIndex] = SyncOperation(
            id: existing.id,
            entityType: existing.entityType,
            entityId: existing.entityId,
            operationType: SyncOperationType.create,
            data: {...existing.data, ...operation.data},
            createdAt: existing.createdAt,
          );
          notifyListeners();
          return;
        } else if (operation.operationType == SyncOperationType.delete) {
          // Remove the create operation entirely
          _queue.removeAt(existingIndex);
          notifyListeners();
          return;
        }
      } else if (existing.operationType == SyncOperationType.update) {
        if (operation.operationType == SyncOperationType.update) {
          // Merge updates
          _queue[existingIndex] = SyncOperation(
            id: existing.id,
            entityType: existing.entityType,
            entityId: existing.entityId,
            operationType: SyncOperationType.update,
            data: {...existing.data, ...operation.data},
            createdAt: existing.createdAt,
          );
          notifyListeners();
          return;
        } else if (operation.operationType == SyncOperationType.delete) {
          // Replace update with delete
          _queue[existingIndex] = operation;
          notifyListeners();
          return;
        }
      }
    }

    _queue.add(operation);
    notifyListeners();

    // Try to sync immediately if online
    if (_connectivity?.isOnline ?? false) {
      processQueue();
    }
  }

  /// Process the sync queue
  Future<void> processQueue() async {
    if (_isSyncing || _queue.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // Process operations in order
      while (_queue.isNotEmpty && (_connectivity?.isOnline ?? true)) {
        final operation = _queue.first;
        final handler = _handlers[operation.entityType];

        if (handler == null) {
          debugPrint('No handler registered for entity type: ${operation.entityType}');
          _queue.removeAt(0);
          continue;
        }

        try {
          final result = await handler(operation);

          if (result.success) {
            _queue.removeAt(0);
            debugPrint('Synced: ${operation.entityType}/${operation.entityId}');
          } else {
            operation.retryCount++;
            operation.lastError = result.error;

            if (operation.retryCount >= maxRetries) {
              debugPrint('Max retries reached for: ${operation.entityType}/${operation.entityId}');
              _queue.removeAt(0);
              // Could emit an event or store failed operations for manual retry
            } else {
              // Move to end of queue for retry
              _queue.removeAt(0);
              _queue.add(operation);

              // Wait before retrying
              await Future<void>.delayed(retryDelay(operation.retryCount));
            }
          }
        } catch (e) {
          debugPrint('Sync error for ${operation.entityType}/${operation.entityId}: $e');
          operation.retryCount++;
          operation.lastError = e.toString();

          if (operation.retryCount >= maxRetries) {
            _queue.removeAt(0);
          } else {
            _queue.removeAt(0);
            _queue.add(operation);
            await Future<void>.delayed(retryDelay(operation.retryCount));
          }
        }

        notifyListeners();
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Clear all pending operations
  void clear() {
    _queue.clear();
    notifyListeners();
  }

  /// Remove a specific operation by ID
  void remove(String operationId) {
    _queue.removeWhere((op) => op.id == operationId);
    notifyListeners();
  }

  /// Export queue to JSON (for persistence)
  String exportToJson() {
    return jsonEncode(_queue.map((op) => op.toJson()).toList());
  }

  /// Import queue from JSON (for persistence)
  void importFromJson(String json) {
    try {
      final List<dynamic> data = jsonDecode(json) as List<dynamic>;
      _queue.clear();
      _queue.addAll(
        data.map((item) => SyncOperation.fromJson(item as Map<String, dynamic>)),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing sync queue: $e');
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
