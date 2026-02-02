// lib/core/offline/offline_storage.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Abstract interface for offline storage
/// Implementations can use SharedPreferences, Hive, SQLite, etc.
abstract class OfflineStorage {
  Future<void> initialize();
  Future<void> save(String key, dynamic value);
  Future<T?> load<T>(String key);
  Future<void> delete(String key);
  Future<void> clear();
  Future<List<String>> getAllKeys();
}

/// In-memory implementation for testing and web fallback
class InMemoryOfflineStorage implements OfflineStorage {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> save(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<T?> load<T>(String key) async {
    return _data[key] as T?;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<List<String>> getAllKeys() async {
    return _data.keys.toList();
  }
}

/// Offline data manager for caching entities
class OfflineDataManager {
  static final OfflineDataManager _instance = OfflineDataManager._internal();
  factory OfflineDataManager() => _instance;
  OfflineDataManager._internal();

  OfflineStorage? _storage;

  /// Initialize with a storage implementation
  void initialize(OfflineStorage storage) {
    _storage = storage;
  }

  OfflineStorage get _safeStorage {
    if (_storage == null) {
      debugPrint('OfflineDataManager not initialized, using in-memory storage');
      _storage = InMemoryOfflineStorage();
    }
    return _storage!;
  }

  /// Cache a list of entities
  Future<void> cacheEntities<T>(
    String entityType,
    List<T> entities,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final key = 'cache_$entityType';
    final data = entities.map(toJson).toList();
    await _safeStorage.save(key, jsonEncode(data));
    await _safeStorage.save('${key}_timestamp', DateTime.now().toIso8601String());
  }

  /// Get cached entities
  Future<List<T>> getCachedEntities<T>(
    String entityType,
    T Function(Map<String, dynamic>) fromJson, {
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final key = 'cache_$entityType';

    // Check cache age
    final timestampStr = await _safeStorage.load<String>('${key}_timestamp');
    if (timestampStr != null) {
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > maxAge) {
        // Cache expired
        return [];
      }
    }

    final dataStr = await _safeStorage.load<String>(key);
    if (dataStr == null) return [];

    try {
      final List<dynamic> data = jsonDecode(dataStr) as List<dynamic>;
      return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error reading cache for $entityType: $e');
      return [];
    }
  }

  /// Cache a single entity
  Future<void> cacheEntity<T>(
    String entityType,
    String entityId,
    T entity,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final key = 'entity_${entityType}_$entityId';
    await _safeStorage.save(key, jsonEncode(toJson(entity)));
    await _safeStorage.save('${key}_timestamp', DateTime.now().toIso8601String());
  }

  /// Get a cached entity
  Future<T?> getCachedEntity<T>(
    String entityType,
    String entityId,
    T Function(Map<String, dynamic>) fromJson, {
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final key = 'entity_${entityType}_$entityId';

    // Check cache age
    final timestampStr = await _safeStorage.load<String>('${key}_timestamp');
    if (timestampStr != null) {
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > maxAge) {
        return null;
      }
    }

    final dataStr = await _safeStorage.load<String>(key);
    if (dataStr == null) return null;

    try {
      final data = jsonDecode(dataStr) as Map<String, dynamic>;
      return fromJson(data);
    } catch (e) {
      debugPrint('Error reading entity cache for $entityType/$entityId: $e');
      return null;
    }
  }

  /// Invalidate cache for an entity type
  Future<void> invalidateCache(String entityType) async {
    final keys = await _safeStorage.getAllKeys();
    for (final key in keys) {
      if (key.startsWith('cache_$entityType') || key.startsWith('entity_$entityType')) {
        await _safeStorage.delete(key);
      }
    }
  }

  /// Clear all caches
  Future<void> clearAll() async {
    await _safeStorage.clear();
  }
}

/// Mixin for repositories to add offline support
mixin OfflineSupport<T> {
  String get entityType;
  Map<String, dynamic> entityToJson(T entity);
  T entityFromJson(Map<String, dynamic> json);

  final OfflineDataManager _offlineManager = OfflineDataManager();

  Future<void> cacheAll(List<T> entities) async {
    await _offlineManager.cacheEntities(entityType, entities, entityToJson);
  }

  Future<List<T>> getCached({Duration maxAge = const Duration(hours: 24)}) async {
    return _offlineManager.getCachedEntities(entityType, entityFromJson, maxAge: maxAge);
  }

  Future<void> cacheOne(String id, T entity) async {
    await _offlineManager.cacheEntity(entityType, id, entity, entityToJson);
  }

  Future<T?> getCachedOne(String id, {Duration maxAge = const Duration(hours: 24)}) async {
    return _offlineManager.getCachedEntity(entityType, id, entityFromJson, maxAge: maxAge);
  }

  Future<void> invalidate() async {
    await _offlineManager.invalidateCache(entityType);
  }
}
