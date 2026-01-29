// test/state/providers/vet_record_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/models/vet_record.dart';
import 'package:hckegg_lite/state/providers/vet_record_provider.dart';
import '../../mocks/mock_vet_repository.dart';

void main() {
  late MockVetRepository mockRepository;
  late VetRecordProvider provider;

  setUp(() {
    mockRepository = MockVetRepository();
    provider = VetRecordProvider(repository: mockRepository);
  });

  tearDown(() {
    mockRepository.clear();
  });

  group('VetRecordProvider', () {
    group('initial state', () {
      test('starts with empty records list', () {
        expect(provider.vetRecords, isEmpty);
      });

      test('starts with isLoading false', () {
        expect(provider.isLoading, false);
      });

      test('starts with no error', () {
        expect(provider.error, isNull);
      });

      test('statistics are zero initially', () {
        expect(provider.totalVetRecords, 0);
        expect(provider.totalDeaths, 0);
        expect(provider.totalVetCosts, 0.0);
        expect(provider.totalHensAffected, 0);
      });
    });

    group('loadVetRecords', () {
      test('loads records from repository', () async {
        final testRecords = [
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.checkup),
        ];
        mockRepository.seedRecords(testRecords);

        await provider.loadVetRecords();

        expect(provider.vetRecords.length, 2);
        expect(mockRepository.getAllCallCount, 1);
      });

      test('sets error on failure', () async {
        mockRepository.shouldThrowOnLoad = true;

        await provider.loadVetRecords();

        expect(provider.error, isNotNull);
        expect(provider.error, contains('Simulated load error'));
      });
    });

    group('saveVetRecord', () {
      test('adds new record to list', () async {
        final record = _createVetRecord('1', '2024-01-15', VetRecordType.vaccine);

        await provider.saveVetRecord(record);

        expect(provider.vetRecords.length, 1);
        expect(provider.vetRecords[0].type, VetRecordType.vaccine);
        expect(mockRepository.saveCallCount, 1);
      });

      test('updates existing record with same id', () async {
        final record1 = _createVetRecord('1', '2024-01-15', VetRecordType.vaccine);
        await provider.saveVetRecord(record1);

        final record2 = _createVetRecord('1', '2024-01-15', VetRecordType.treatment);
        await provider.saveVetRecord(record2);

        expect(provider.vetRecords.length, 1);
        expect(provider.vetRecords[0].type, VetRecordType.treatment);
      });

      test('sets error and rethrows on repository failure', () async {
        mockRepository.shouldThrowOnSave = true;
        final record = _createVetRecord('1', '2024-01-15', VetRecordType.vaccine);

        await expectLater(provider.saveVetRecord(record), throwsException);
        expect(provider.error, isNotNull);
      });
    });

    group('deleteVetRecord', () {
      test('removes record from list', () async {
        mockRepository.seedRecords([
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.checkup),
        ]);
        await provider.loadVetRecords();

        await provider.deleteVetRecord('1');

        expect(provider.vetRecords.length, 1);
        expect(provider.vetRecords[0].id, '2');
        expect(mockRepository.deleteCallCount, 1);
      });

      test('sets error and rethrows on repository failure', () async {
        mockRepository.shouldThrowOnDelete = true;

        await expectLater(provider.deleteVetRecord('1'), throwsException);
        expect(provider.error, isNotNull);
      });
    });

    group('statistics', () {
      test('calculates totalVetRecords correctly', () async {
        mockRepository.seedRecords([
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.checkup),
          _createVetRecord('3', '2024-01-17', VetRecordType.treatment),
        ]);
        await provider.loadVetRecords();

        expect(provider.totalVetRecords, 3);
      });

      test('calculates totalDeaths correctly', () async {
        mockRepository.seedRecords([
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.death),
          _createVetRecord('3', '2024-01-17', VetRecordType.death),
        ]);
        await provider.loadVetRecords();

        expect(provider.totalDeaths, 2);
      });

      test('calculates totalVetCosts correctly', () async {
        mockRepository.seedRecords([
          _createVetRecordWithCost('1', '2024-01-15', 50.0),
          _createVetRecordWithCost('2', '2024-01-16', 75.50),
          _createVetRecordWithCost('3', '2024-01-17', 25.0),
        ]);
        await provider.loadVetRecords();

        expect(provider.totalVetCosts, closeTo(150.50, 0.01));
      });

      test('calculates totalHensAffected correctly', () async {
        mockRepository.seedRecords([
          _createVetRecordWithHens('1', '2024-01-15', 5),
          _createVetRecordWithHens('2', '2024-01-16', 10),
          _createVetRecordWithHens('3', '2024-01-17', 3),
        ]);
        await provider.loadVetRecords();

        expect(provider.totalHensAffected, 18);
      });

      test('handles records with null cost', () async {
        mockRepository.seedRecords([
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine), // no cost
          _createVetRecordWithCost('2', '2024-01-16', 50.0),
        ]);
        await provider.loadVetRecords();

        expect(provider.totalVetCosts, closeTo(50.0, 0.01));
      });
    });

    group('getVetRecords', () {
      test('returns records sorted by date descending', () async {
        mockRepository.seedRecords([
          _createVetRecord('1', '2024-01-10', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-20', VetRecordType.checkup),
          _createVetRecord('3', '2024-01-15', VetRecordType.treatment),
        ]);
        await provider.loadVetRecords();

        final sorted = provider.getVetRecords();

        expect(sorted[0].date, '2024-01-20');
        expect(sorted[1].date, '2024-01-15');
        expect(sorted[2].date, '2024-01-10');
      });
    });

    group('getVetRecordsByType', () {
      test('returns records of specified type', () async {
        mockRepository.seedRecords([
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.checkup),
          _createVetRecord('3', '2024-01-17', VetRecordType.vaccine),
          _createVetRecord('4', '2024-01-18', VetRecordType.treatment),
        ]);
        await provider.loadVetRecords();

        final vaccines = provider.getVetRecordsByType(VetRecordType.vaccine);

        expect(vaccines.length, 2);
        expect(vaccines.every((r) => r.type == VetRecordType.vaccine), true);
      });

      test('returns empty list when no records of type', () async {
        mockRepository.seedRecords([
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
        ]);
        await provider.loadVetRecords();

        final deaths = provider.getVetRecordsByType(VetRecordType.death);

        expect(deaths, isEmpty);
      });
    });

    group('getUpcomingVetActions', () {
      test('returns records with future nextActionDate', () async {
        final futureDate = DateTime.now().add(const Duration(days: 10));
        final futureDateStr = _toIsoDate(futureDate);
        final pastDate = DateTime.now().subtract(const Duration(days: 10));
        final pastDateStr = _toIsoDate(pastDate);

        mockRepository.seedRecords([
          _createVetRecordWithNextAction('1', '2024-01-15', futureDateStr),
          _createVetRecordWithNextAction('2', '2024-01-16', pastDateStr),
          _createVetRecord('3', '2024-01-17', VetRecordType.checkup), // no next action
        ]);
        await provider.loadVetRecords();

        final upcoming = provider.getUpcomingVetActions();

        expect(upcoming.length, 1);
        expect(upcoming[0].id, '1');
      });

      test('returns sorted by nextActionDate ascending', () async {
        final future1 = DateTime.now().add(const Duration(days: 5));
        final future2 = DateTime.now().add(const Duration(days: 15));
        final future3 = DateTime.now().add(const Duration(days: 10));

        mockRepository.seedRecords([
          _createVetRecordWithNextAction('1', '2024-01-15', _toIsoDate(future2)),
          _createVetRecordWithNextAction('2', '2024-01-16', _toIsoDate(future1)),
          _createVetRecordWithNextAction('3', '2024-01-17', _toIsoDate(future3)),
        ]);
        await provider.loadVetRecords();

        final upcoming = provider.getUpcomingVetActions();

        expect(upcoming.length, 3);
        expect(upcoming[0].id, '2'); // 5 days
        expect(upcoming[1].id, '3'); // 10 days
        expect(upcoming[2].id, '1'); // 15 days
      });
    });

    group('getTodayAppointments', () {
      test('returns records scheduled for today', () async {
        final todayStr = _toIsoDate(DateTime.now());
        final tomorrowStr = _toIsoDate(DateTime.now().add(const Duration(days: 1)));

        mockRepository.seedRecords([
          _createVetRecordWithNextAction('1', '2024-01-15', todayStr),
          _createVetRecordWithNextAction('2', '2024-01-16', tomorrowStr),
          _createVetRecordWithNextAction('3', '2024-01-17', todayStr),
        ]);
        await provider.loadVetRecords();

        final today = provider.getTodayAppointments();

        expect(today.length, 2);
        expect(today.every((r) => r.nextActionDate == todayStr), true);
      });

      test('returns empty list when no appointments today', () async {
        final tomorrowStr = _toIsoDate(DateTime.now().add(const Duration(days: 1)));

        mockRepository.seedRecords([
          _createVetRecordWithNextAction('1', '2024-01-15', tomorrowStr),
        ]);
        await provider.loadVetRecords();

        final today = provider.getTodayAppointments();

        expect(today, isEmpty);
      });
    });

    group('clearData', () {
      test('clears all records', () async {
        mockRepository.seedRecords([
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
          _createVetRecord('2', '2024-01-16', VetRecordType.checkup),
        ]);
        await provider.loadVetRecords();
        expect(provider.vetRecords.length, 2);

        provider.clearData();

        expect(provider.vetRecords, isEmpty);
        expect(provider.error, isNull);
        expect(provider.isLoading, false);
      });
    });

    group('records immutability', () {
      test('vetRecords getter returns unmodifiable list', () async {
        mockRepository.seedRecords([
          _createVetRecord('1', '2024-01-15', VetRecordType.vaccine),
        ]);
        await provider.loadVetRecords();

        final records = provider.vetRecords;

        expect(
          () => records.add(_createVetRecord('2', '2024-01-16', VetRecordType.checkup)),
          throwsUnsupportedError,
        );
      });
    });
  });
}

VetRecord _createVetRecord(String id, String date, VetRecordType type) {
  return VetRecord(
    id: id,
    date: date,
    type: type,
    hensAffected: 1,
    description: 'Test record',
  );
}

VetRecord _createVetRecordWithCost(String id, String date, double cost) {
  return VetRecord(
    id: id,
    date: date,
    type: VetRecordType.treatment,
    hensAffected: 1,
    description: 'Test record',
    cost: cost,
  );
}

VetRecord _createVetRecordWithHens(String id, String date, int hensAffected) {
  return VetRecord(
    id: id,
    date: date,
    type: VetRecordType.vaccine,
    hensAffected: hensAffected,
    description: 'Test record',
  );
}

VetRecord _createVetRecordWithNextAction(String id, String date, String nextActionDate) {
  return VetRecord(
    id: id,
    date: date,
    type: VetRecordType.checkup,
    hensAffected: 1,
    description: 'Test record',
    nextActionDate: nextActionDate,
  );
}

String _toIsoDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
