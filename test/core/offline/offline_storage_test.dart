import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/offline/offline_storage.dart';

void main() {
  group('InMemoryOfflineStorage', () {
    late InMemoryOfflineStorage storage;

    setUp(() {
      storage = InMemoryOfflineStorage();
    });

    test('initializes without error', () async {
      await expectLater(storage.initialize(), completes);
    });

    test('saves and loads string value', () async {
      await storage.save('key1', 'value1');
      final result = await storage.load<String>('key1');
      expect(result, 'value1');
    });

    test('saves and loads int value', () async {
      await storage.save('count', 42);
      final result = await storage.load<int>('count');
      expect(result, 42);
    });

    test('saves and loads map value', () async {
      await storage.save('data', {'name': 'test', 'value': 123});
      final result = await storage.load<Map<String, dynamic>>('data');
      expect(result, {'name': 'test', 'value': 123});
    });

    test('returns null for non-existent key', () async {
      final result = await storage.load<String>('non-existent');
      expect(result, isNull);
    });

    test('deletes value', () async {
      await storage.save('key1', 'value1');
      await storage.delete('key1');
      final result = await storage.load<String>('key1');
      expect(result, isNull);
    });

    test('clears all values', () async {
      await storage.save('key1', 'value1');
      await storage.save('key2', 'value2');
      await storage.save('key3', 'value3');

      await storage.clear();

      expect(await storage.load<String>('key1'), isNull);
      expect(await storage.load<String>('key2'), isNull);
      expect(await storage.load<String>('key3'), isNull);
    });

    test('returns all keys', () async {
      await storage.save('key1', 'value1');
      await storage.save('key2', 'value2');
      await storage.save('key3', 'value3');

      final keys = await storage.getAllKeys();

      expect(keys, containsAll(['key1', 'key2', 'key3']));
      expect(keys.length, 3);
    });

    test('overwrites existing value', () async {
      await storage.save('key1', 'original');
      await storage.save('key1', 'updated');

      final result = await storage.load<String>('key1');
      expect(result, 'updated');
    });
  });

  group('OfflineDataManager', () {
    late OfflineDataManager manager;
    late InMemoryOfflineStorage storage;

    setUp(() {
      manager = OfflineDataManager();
      storage = InMemoryOfflineStorage();
      manager.initialize(storage);
    });

    test('caches and retrieves entities', () async {
      final entities = [
        {'id': '1', 'name': 'Entity 1'},
        {'id': '2', 'name': 'Entity 2'},
      ];

      await manager.cacheEntities(
        'test_entity',
        entities,
        (e) => e,
      );

      final cached = await manager.getCachedEntities<Map<String, dynamic>>(
        'test_entity',
        (json) => json,
      );

      expect(cached.length, 2);
      expect(cached[0]['name'], 'Entity 1');
      expect(cached[1]['name'], 'Entity 2');
    });

    test('returns empty list for expired cache', () async {
      final entities = [
        {'id': '1', 'name': 'Entity 1'},
      ];

      await manager.cacheEntities(
        'test_entity',
        entities,
        (e) => e,
      );

      // Request with very short max age (already expired)
      final cached = await manager.getCachedEntities<Map<String, dynamic>>(
        'test_entity',
        (json) => json,
        maxAge: Duration.zero,
      );

      expect(cached, isEmpty);
    });

    test('caches and retrieves single entity', () async {
      final entity = {'id': '123', 'name': 'Single Entity', 'value': 42};

      await manager.cacheEntity(
        'item',
        '123',
        entity,
        (e) => e,
      );

      final cached = await manager.getCachedEntity<Map<String, dynamic>>(
        'item',
        '123',
        (json) => json,
      );

      expect(cached, isNotNull);
      expect(cached!['id'], '123');
      expect(cached['name'], 'Single Entity');
      expect(cached['value'], 42);
    });

    test('returns null for non-existent single entity', () async {
      final cached = await manager.getCachedEntity<Map<String, dynamic>>(
        'item',
        'non-existent',
        (json) => json,
      );

      expect(cached, isNull);
    });

    test('invalidates cache for entity type', () async {
      await manager.cacheEntities(
        'eggs',
        [{'id': '1'}],
        (e) => e,
      );
      await manager.cacheEntities(
        'sales',
        [{'id': '1'}],
        (e) => e,
      );

      await manager.invalidateCache('eggs');

      final eggs = await manager.getCachedEntities<Map<String, dynamic>>(
        'eggs',
        (json) => json,
      );
      final sales = await manager.getCachedEntities<Map<String, dynamic>>(
        'sales',
        (json) => json,
      );

      expect(eggs, isEmpty);
      expect(sales, isNotEmpty);
    });

    test('clears all caches', () async {
      await manager.cacheEntities(
        'eggs',
        [{'id': '1'}],
        (e) => e,
      );
      await manager.cacheEntities(
        'sales',
        [{'id': '1'}],
        (e) => e,
      );

      await manager.clearAll();

      final eggs = await manager.getCachedEntities<Map<String, dynamic>>(
        'eggs',
        (json) => json,
      );
      final sales = await manager.getCachedEntities<Map<String, dynamic>>(
        'sales',
        (json) => json,
      );

      expect(eggs, isEmpty);
      expect(sales, isEmpty);
    });
  });
}
