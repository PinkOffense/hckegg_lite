import 'package:test/test.dart';
import 'package:hckegg_api/features/eggs/domain/entities/egg_record.dart';

void main() {
  group('EggRecord', () {
    final testRecord = EggRecord(
      id: 'test-id',
      userId: 'user-123',
      date: '2024-01-15',
      eggsCollected: 30,
      eggsBroken: 2,
      eggsConsumed: 4,
      notes: 'Good day',
      createdAt: DateTime(2024, 1, 15, 10, 0),
      updatedAt: DateTime(2024, 1, 15, 10, 0),
    );

    group('constructor', () {
      test('should create EggRecord with all properties', () {
        expect(testRecord.id, 'test-id');
        expect(testRecord.userId, 'user-123');
        expect(testRecord.date, '2024-01-15');
        expect(testRecord.eggsCollected, 30);
        expect(testRecord.eggsBroken, 2);
        expect(testRecord.eggsConsumed, 4);
        expect(testRecord.notes, 'Good day');
      });
    });

    group('eggsAvailable', () {
      test('should calculate eggs available correctly', () {
        // 30 collected - 2 broken - 4 consumed = 24 available
        expect(testRecord.eggsAvailable, 24);
      });

      test('should return 0 when all eggs used', () {
        final record = EggRecord(
          id: 'id',
          userId: 'user',
          date: '2024-01-15',
          eggsCollected: 10,
          eggsBroken: 5,
          eggsConsumed: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(record.eggsAvailable, 0);
      });

      test('should return negative when overused', () {
        final record = EggRecord(
          id: 'id',
          userId: 'user',
          date: '2024-01-15',
          eggsCollected: 10,
          eggsBroken: 5,
          eggsConsumed: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(record.eggsAvailable, -5);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final updated = testRecord.copyWith(eggsCollected: 50);

        expect(updated.id, testRecord.id);
        expect(updated.eggsCollected, 50);
        expect(updated.eggsBroken, testRecord.eggsBroken);
      });

      test('should preserve original when no changes', () {
        final copy = testRecord.copyWith();

        expect(copy.id, testRecord.id);
        expect(copy.eggsCollected, testRecord.eggsCollected);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final json = testRecord.toJson();

        expect(json['id'], 'test-id');
        expect(json['user_id'], 'user-123');
        expect(json['date'], '2024-01-15');
        expect(json['eggs_collected'], 30);
        expect(json['eggs_broken'], 2);
        expect(json['eggs_consumed'], 4);
        expect(json['notes'], 'Good day');
      });

      test('should include null notes when not set', () {
        final record = EggRecord(
          id: 'id',
          userId: 'user',
          date: '2024-01-15',
          eggsCollected: 10,
          eggsBroken: 0,
          eggsConsumed: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = record.toJson();
        expect(json['notes'], isNull);
      });
    });

    group('fromJson', () {
      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-123',
          'date': '2024-01-15',
          'eggs_collected': 30,
          'eggs_broken': 2,
          'eggs_consumed': 4,
          'notes': 'Good day',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final record = EggRecord.fromJson(json);

        expect(record.id, 'test-id');
        expect(record.userId, 'user-123');
        expect(record.eggsCollected, 30);
        expect(record.eggsBroken, 2);
        expect(record.eggsConsumed, 4);
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-123',
          'date': '2024-01-15',
          'eggs_collected': 30,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final record = EggRecord.fromJson(json);

        expect(record.eggsBroken, 0);
        expect(record.eggsConsumed, 0);
        expect(record.notes, isNull);
      });
    });

    group('equality', () {
      test('records with same props should be equal', () {
        final record1 = EggRecord(
          id: 'id',
          userId: 'user',
          date: '2024-01-15',
          eggsCollected: 10,
          eggsBroken: 0,
          eggsConsumed: 0,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        );

        final record2 = EggRecord(
          id: 'id',
          userId: 'user',
          date: '2024-01-15',
          eggsCollected: 10,
          eggsBroken: 0,
          eggsConsumed: 0,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        );

        expect(record1, equals(record2));
      });

      test('records with different props should not be equal', () {
        final record1 = EggRecord(
          id: 'id1',
          userId: 'user',
          date: '2024-01-15',
          eggsCollected: 10,
          eggsBroken: 0,
          eggsConsumed: 0,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        );

        final record2 = EggRecord(
          id: 'id2',
          userId: 'user',
          date: '2024-01-15',
          eggsCollected: 10,
          eggsBroken: 0,
          eggsConsumed: 0,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        );

        expect(record1, isNot(equals(record2)));
      });
    });
  });

  group('EggStatistics', () {
    test('should serialize to JSON correctly', () {
      const stats = EggStatistics(
        totalCollected: 100,
        totalBroken: 5,
        totalConsumed: 10,
        totalAvailable: 85,
        averageDaily: 14.28,
        recordCount: 7,
      );

      final json = stats.toJson();

      expect(json['total_collected'], 100);
      expect(json['total_broken'], 5);
      expect(json['total_consumed'], 10);
      expect(json['total_available'], 85);
      expect(json['average_daily'], 14.28);
      expect(json['record_count'], 7);
    });
  });
}
