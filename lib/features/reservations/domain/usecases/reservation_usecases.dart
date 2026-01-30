import '../../../../core/core.dart';
import '../entities/egg_reservation.dart';
import '../repositories/reservation_repository.dart';

// Get all reservations
class GetReservations extends UseCase<List<EggReservation>, NoParams> {
  final ReservationRepository repository;

  GetReservations(this.repository);

  @override
  Future<Result<List<EggReservation>>> call(NoParams params) {
    return repository.getReservations();
  }
}

// Get reservation by ID
class GetReservationByIdParams {
  final String id;
  const GetReservationByIdParams({required this.id});
}

class GetReservationById extends UseCase<EggReservation, GetReservationByIdParams> {
  final ReservationRepository repository;

  GetReservationById(this.repository);

  @override
  Future<Result<EggReservation>> call(GetReservationByIdParams params) {
    return repository.getReservationById(params.id);
  }
}

// Get reservations in date range
class GetReservationsInRangeParams {
  final DateTime start;
  final DateTime end;
  const GetReservationsInRangeParams({required this.start, required this.end});
}

class GetReservationsInRange extends UseCase<List<EggReservation>, GetReservationsInRangeParams> {
  final ReservationRepository repository;

  GetReservationsInRange(this.repository);

  @override
  Future<Result<List<EggReservation>>> call(GetReservationsInRangeParams params) {
    return repository.getReservationsInRange(params.start, params.end);
  }
}

// Create reservation
class CreateReservationParams {
  final EggReservation reservation;
  const CreateReservationParams({required this.reservation});
}

class CreateReservation extends UseCase<EggReservation, CreateReservationParams> {
  final ReservationRepository repository;

  CreateReservation(this.repository);

  @override
  Future<Result<EggReservation>> call(CreateReservationParams params) {
    return repository.createReservation(params.reservation);
  }
}

// Update reservation
class UpdateReservationParams {
  final EggReservation reservation;
  const UpdateReservationParams({required this.reservation});
}

class UpdateReservation extends UseCase<EggReservation, UpdateReservationParams> {
  final ReservationRepository repository;

  UpdateReservation(this.repository);

  @override
  Future<Result<EggReservation>> call(UpdateReservationParams params) {
    return repository.updateReservation(params.reservation);
  }
}

// Delete reservation
class DeleteReservationParams {
  final String id;
  const DeleteReservationParams({required this.id});
}

class DeleteReservation extends UseCase<void, DeleteReservationParams> {
  final ReservationRepository repository;

  DeleteReservation(this.repository);

  @override
  Future<Result<void>> call(DeleteReservationParams params) {
    return repository.deleteReservation(params.id);
  }
}
