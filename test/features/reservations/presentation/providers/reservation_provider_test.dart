// test/features/reservations/presentation/providers/reservation_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/core.dart';
import 'package:hckegg_lite/features/reservations/domain/domain.dart';
import 'package:hckegg_lite/features/reservations/presentation/providers/reservation_provider.dart';
import 'package:hckegg_lite/models/egg_reservation.dart';

// Mock Use Cases
class MockGetReservations implements GetReservations {
  List<EggReservation> reservationsToReturn = [];
  Failure? failureToReturn;
  int callCount = 0;

  @override
  Future<Result<List<EggReservation>>> call(NoParams params) async {
    callCount++;
    if (failureToReturn != null) {
      return Result.fail(failureToReturn!);
    }
    return Result.success(reservationsToReturn);
  }
}

class MockGetReservationsInRange implements GetReservationsInRange {
  List<EggReservation> reservationsToReturn = [];
  int callCount = 0;

  @override
  Future<Result<List<EggReservation>>> call(GetReservationsInRangeParams params) async {
    callCount++;
    return Result.success(reservationsToReturn);
  }
}

class MockCreateReservation implements CreateReservation {
  EggReservation? reservationToReturn;
  Failure? failureToReturn;
  int callCount = 0;

  @override
  Future<Result<EggReservation>> call(CreateReservationParams params) async {
    callCount++;
    if (failureToReturn != null) {
      return Result.fail(failureToReturn!);
    }
    return Result.success(reservationToReturn ?? params.reservation);
  }
}

class MockUpdateReservation implements UpdateReservation {
  Failure? failureToReturn;
  int callCount = 0;

  @override
  Future<Result<EggReservation>> call(UpdateReservationParams params) async {
    callCount++;
    if (failureToReturn != null) {
      return Result.fail(failureToReturn!);
    }
    return Result.success(params.reservation);
  }
}

class MockDeleteReservation implements DeleteReservation {
  Failure? failureToReturn;
  int callCount = 0;

  @override
  Future<Result<void>> call(DeleteReservationParams params) async {
    callCount++;
    if (failureToReturn != null) {
      return Result.fail(failureToReturn!);
    }
    return Result.success(null);
  }
}

void main() {
  late MockGetReservations mockGetReservations;
  late MockGetReservationsInRange mockGetReservationsInRange;
  late MockCreateReservation mockCreateReservation;
  late MockUpdateReservation mockUpdateReservation;
  late MockDeleteReservation mockDeleteReservation;
  late ReservationProvider provider;

  setUp(() {
    mockGetReservations = MockGetReservations();
    mockGetReservationsInRange = MockGetReservationsInRange();
    mockCreateReservation = MockCreateReservation();
    mockUpdateReservation = MockUpdateReservation();
    mockDeleteReservation = MockDeleteReservation();

    provider = ReservationProvider(
      getReservations: mockGetReservations,
      getReservationsInRange: mockGetReservationsInRange,
      createReservation: mockCreateReservation,
      updateReservation: mockUpdateReservation,
      deleteReservation: mockDeleteReservation,
    );
  });

  group('ReservationProvider', () {
    group('initial state', () {
      test('starts with empty reservations list', () {
        expect(provider.reservations, isEmpty);
      });

      test('starts with initial state', () {
        expect(provider.state, ReservationState.initial);
      });

      test('starts with no error', () {
        expect(provider.errorMessage, isNull);
      });

      test('isLoading is false initially', () {
        expect(provider.isLoading, false);
      });
    });

    group('loadReservations', () {
      test('loads reservations successfully', () async {
        final testReservations = [
          _createReservation('1', 10, 'Customer A'),
          _createReservation('2', 20, 'Customer B'),
        ];
        mockGetReservations.reservationsToReturn = testReservations;

        await provider.loadReservations();

        expect(provider.reservations.length, 2);
        expect(provider.state, ReservationState.loaded);
        expect(mockGetReservations.callCount, 1);
      });

      test('sets error state on failure', () async {
        mockGetReservations.failureToReturn = ServerFailure(message: 'Network error');

        await provider.loadReservations();

        expect(provider.state, ReservationState.error);
        expect(provider.errorMessage, 'Network error');
        expect(provider.hasError, true);
      });
    });

    group('saveReservation', () {
      test('creates new reservation successfully', () async {
        final reservation = _createReservation('1', 10, 'Customer A');

        await provider.saveReservation(reservation);

        expect(provider.reservations.length, 1);
        expect(provider.state, ReservationState.loaded);
        expect(mockCreateReservation.callCount, 1);
      });

      test('updates existing reservation', () async {
        final reservation = _createReservation('1', 10, 'Customer A');
        mockGetReservations.reservationsToReturn = [reservation];
        await provider.loadReservations();

        final updatedReservation = _createReservation('1', 20, 'Customer A Updated');
        await provider.saveReservation(updatedReservation);

        expect(provider.reservations.length, 1);
        expect(provider.reservations[0].quantity, 20);
        expect(mockUpdateReservation.callCount, 1);
      });

      test('sets error on create failure', () async {
        mockCreateReservation.failureToReturn = ServerFailure(message: 'Create failed');
        final reservation = _createReservation('1', 10, 'Customer A');

        await provider.saveReservation(reservation);

        expect(provider.state, ReservationState.error);
        expect(provider.errorMessage, 'Create failed');
      });
    });

    group('deleteReservation', () {
      test('removes reservation from list', () async {
        mockGetReservations.reservationsToReturn = [
          _createReservation('1', 10, 'Customer A'),
          _createReservation('2', 20, 'Customer B'),
        ];
        await provider.loadReservations();

        await provider.deleteReservation('1');

        expect(provider.reservations.length, 1);
        expect(provider.reservations[0].id, '2');
        expect(mockDeleteReservation.callCount, 1);
      });

      test('sets error on delete failure', () async {
        mockDeleteReservation.failureToReturn = ServerFailure(message: 'Delete failed');

        await provider.deleteReservation('1');

        expect(provider.state, ReservationState.error);
        expect(provider.errorMessage, 'Delete failed');
      });
    });

    group('search', () {
      test('returns all reservations when query is empty', () async {
        mockGetReservations.reservationsToReturn = [
          _createReservation('1', 10, 'Alice'),
          _createReservation('2', 20, 'Bob'),
        ];
        await provider.loadReservations();

        final results = provider.search('');

        expect(results.length, 2);
      });

      test('filters by customer name', () async {
        mockGetReservations.reservationsToReturn = [
          _createReservation('1', 10, 'Alice'),
          _createReservation('2', 20, 'Bob'),
          _createReservation('3', 30, 'Alice Smith'),
        ];
        await provider.loadReservations();

        final results = provider.search('alice');

        expect(results.length, 2);
        expect(results.every((r) => r.customerName!.toLowerCase().contains('alice')), true);
      });

      test('filters by phone number', () async {
        mockGetReservations.reservationsToReturn = [
          _createReservation('1', 10, 'Alice', phone: '912345678'),
          _createReservation('2', 20, 'Bob', phone: '923456789'),
        ];
        await provider.loadReservations();

        final results = provider.search('912');

        expect(results.length, 1);
        expect(results[0].customerPhone, '912345678');
      });

      test('filters by quantity', () async {
        mockGetReservations.reservationsToReturn = [
          _createReservation('1', 10, 'Alice'),
          _createReservation('2', 100, 'Bob'),
          _createReservation('3', 1000, 'Charlie'),
        ];
        await provider.loadReservations();

        final results = provider.search('100');

        expect(results.length, 2); // 100 and 1000
      });

      test('search is case insensitive', () async {
        mockGetReservations.reservationsToReturn = [
          _createReservation('1', 10, 'ALICE'),
          _createReservation('2', 20, 'alice'),
          _createReservation('3', 30, 'Alice'),
        ];
        await provider.loadReservations();

        final results = provider.search('ALICE');

        expect(results.length, 3);
      });

      test('returns empty list when no matches', () async {
        mockGetReservations.reservationsToReturn = [
          _createReservation('1', 10, 'Alice'),
          _createReservation('2', 20, 'Bob'),
        ];
        await provider.loadReservations();

        final results = provider.search('xyz');

        expect(results, isEmpty);
      });
    });

    group('clearData', () {
      test('clears all reservations and resets state', () async {
        mockGetReservations.reservationsToReturn = [
          _createReservation('1', 10, 'Alice'),
        ];
        await provider.loadReservations();
        expect(provider.reservations.length, 1);

        provider.clearData();

        expect(provider.reservations, isEmpty);
        expect(provider.state, ReservationState.initial);
        expect(provider.errorMessage, isNull);
      });
    });

    group('clearError', () {
      test('clears error message', () async {
        mockGetReservations.failureToReturn = ServerFailure(message: 'Error');
        await provider.loadReservations();
        expect(provider.errorMessage, isNotNull);

        provider.clearError();

        expect(provider.errorMessage, isNull);
      });
    });
  });
}

EggReservation _createReservation(
  String id,
  int quantity,
  String? customerName, {
  String? phone,
}) {
  return EggReservation(
    id: id,
    date: '2024-01-15',
    quantity: quantity,
    customerName: customerName,
    customerPhone: phone,
    createdAt: DateTime.now(),
  );
}
