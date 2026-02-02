import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/offline/sync_queue.dart';

void main() {
  group('SyncOperation', () {
    test('creates with correct properties', () {
      final operation = SyncOperation(
        id: 'op-1',
        entityType: 'eggs',
        entityId: 'egg-123',
        operationType: SyncOperationType.create,
        data: {'collected': 10},
      );

      expect(operation.id, 'op-1');
      expect(operation.entityType, 'eggs');
      expect(operation.entityId, 'egg-123');
      expect(operation.operationType, SyncOperationType.create);
      expect(operation.data['collected'], 10);
      expect(operation.retryCount, 0);
      expect(operation.lastError, isNull);
    });

    test('serializes to JSON correctly', () {
      final operation = SyncOperation(
        id: 'op-1',
        entityType: 'eggs',
        entityId: 'egg-123',
        operationType: SyncOperationType.update,
        data: {'collected': 15},
        retryCount: 2,
        lastError: 'Network error',
      );

      final json = operation.toJson();

      expect(json['id'], 'op-1');
      expect(json['entityType'], 'eggs');
      expect(json['entityId'], 'egg-123');
      expect(json['operationType'], 'update');
      expect(json['data']['collected'], 15);
      expect(json['retryCount'], 2);
      expect(json['lastError'], 'Network error');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'op-2',
        'entityType': 'sales',
        'entityId': 'sale-456',
        'operationType': 'delete',
        'data': <String, dynamic>{},
        'createdAt': '2024-01-15T10:30:00.000Z',
        'retryCount': 1,
        'lastError': null,
      };

      final operation = SyncOperation.fromJson(json);

      expect(operation.id, 'op-2');
      expect(operation.entityType, 'sales');
      expect(operation.entityId, 'sale-456');
      expect(operation.operationType, SyncOperationType.delete);
      expect(operation.retryCount, 1);
    });
  });

  group('SyncResult', () {
    test('success result has correct properties', () {
      const result = SyncResult.success({'id': '123'});
      expect(result.success, true);
      expect(result.error, isNull);
      expect(result.serverData, {'id': '123'});
    });

    test('failure result has correct properties', () {
      const result = SyncResult.failure('Network error');
      expect(result.success, false);
      expect(result.error, 'Network error');
      expect(result.serverData, isNull);
    });
  });

  group('SyncQueue', () {
    late SyncQueue queue;

    setUp(() {
      queue = SyncQueue();
      queue.clear();
    });

    test('starts with empty queue', () {
      expect(queue.pendingCount, 0);
      expect(queue.queue, isEmpty);
      expect(queue.isSyncing, false);
    });

    test('enqueues operations', () {
      final operation = SyncOperation(
        id: 'op-1',
        entityType: 'eggs',
        entityId: 'egg-123',
        operationType: SyncOperationType.create,
        data: {'collected': 10},
      );

      queue.enqueue(operation);

      expect(queue.pendingCount, 1);
      expect(queue.queue.first.id, 'op-1');
    });

    test('removes operation by ID', () {
      final op1 = SyncOperation(
        id: 'op-1',
        entityType: 'eggs',
        entityId: 'egg-1',
        operationType: SyncOperationType.create,
        data: {},
      );
      final op2 = SyncOperation(
        id: 'op-2',
        entityType: 'eggs',
        entityId: 'egg-2',
        operationType: SyncOperationType.create,
        data: {},
      );

      queue.enqueue(op1);
      queue.enqueue(op2);
      expect(queue.pendingCount, 2);

      queue.remove('op-1');
      expect(queue.pendingCount, 1);
      expect(queue.queue.first.id, 'op-2');
    });

    test('clears all operations', () {
      queue.enqueue(SyncOperation(
        id: 'op-1',
        entityType: 'eggs',
        entityId: 'egg-1',
        operationType: SyncOperationType.create,
        data: {},
      ));
      queue.enqueue(SyncOperation(
        id: 'op-2',
        entityType: 'eggs',
        entityId: 'egg-2',
        operationType: SyncOperationType.create,
        data: {},
      ));

      queue.clear();

      expect(queue.pendingCount, 0);
    });

    test('merges update into create for same entity', () {
      final createOp = SyncOperation(
        id: 'op-1',
        entityType: 'eggs',
        entityId: 'egg-123',
        operationType: SyncOperationType.create,
        data: {'collected': 10},
      );
      final updateOp = SyncOperation(
        id: 'op-2',
        entityType: 'eggs',
        entityId: 'egg-123',
        operationType: SyncOperationType.update,
        data: {'sold': 5},
      );

      queue.enqueue(createOp);
      queue.enqueue(updateOp);

      expect(queue.pendingCount, 1);
      expect(queue.queue.first.operationType, SyncOperationType.create);
      expect(queue.queue.first.data['collected'], 10);
      expect(queue.queue.first.data['sold'], 5);
    });

    test('removes create when delete is enqueued for same entity', () {
      final createOp = SyncOperation(
        id: 'op-1',
        entityType: 'eggs',
        entityId: 'egg-123',
        operationType: SyncOperationType.create,
        data: {'collected': 10},
      );
      final deleteOp = SyncOperation(
        id: 'op-2',
        entityType: 'eggs',
        entityId: 'egg-123',
        operationType: SyncOperationType.delete,
        data: {},
      );

      queue.enqueue(createOp);
      queue.enqueue(deleteOp);

      expect(queue.pendingCount, 0);
    });

    test('replaces update with delete for same entity', () {
      final updateOp = SyncOperation(
        id: 'op-1',
        entityType: 'eggs',
        entityId: 'egg-123',
        operationType: SyncOperationType.update,
        data: {'collected': 10},
      );
      final deleteOp = SyncOperation(
        id: 'op-2',
        entityType: 'eggs',
        entityId: 'egg-123',
        operationType: SyncOperationType.delete,
        data: {},
      );

      queue.enqueue(updateOp);
      queue.enqueue(deleteOp);

      expect(queue.pendingCount, 1);
      expect(queue.queue.first.operationType, SyncOperationType.delete);
    });

    test('exports and imports JSON correctly', () {
      queue.enqueue(SyncOperation(
        id: 'op-1',
        entityType: 'eggs',
        entityId: 'egg-1',
        operationType: SyncOperationType.create,
        data: {'collected': 10},
      ));
      queue.enqueue(SyncOperation(
        id: 'op-2',
        entityType: 'sales',
        entityId: 'sale-1',
        operationType: SyncOperationType.update,
        data: {'amount': 25.0},
      ));

      final json = queue.exportToJson();
      queue.clear();
      expect(queue.pendingCount, 0);

      queue.importFromJson(json);
      expect(queue.pendingCount, 2);
      expect(queue.queue[0].entityType, 'eggs');
      expect(queue.queue[1].entityType, 'sales');
    });

    test('retry delay uses exponential backoff', () {
      expect(SyncQueue.retryDelay(0).inSeconds, 2);
      expect(SyncQueue.retryDelay(1).inSeconds, 4);
      expect(SyncQueue.retryDelay(2).inSeconds, 8);
      expect(SyncQueue.retryDelay(3).inSeconds, 16);
      expect(SyncQueue.retryDelay(4).inSeconds, 32);
      expect(SyncQueue.retryDelay(5).inSeconds, 60); // Capped at 60
    });
  });
}
