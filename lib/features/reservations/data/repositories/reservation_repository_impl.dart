import '../../../../core/core.dart';
import '../../domain/entities/egg_reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../datasources/reservation_remote_datasource.dart';
import '../models/egg_reservation_model.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationRemoteDataSource remoteDataSource;

  ReservationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<EggReservation>>> getReservations() async {
    try {
      final reservations = await remoteDataSource.getReservations();
      return Result.success(reservations);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggReservation>> getReservationById(String id) async {
    try {
      final reservation = await remoteDataSource.getReservationById(id);
      return Result.success(reservation);
    } catch (e) {
      if (e.toString().contains('no rows')) {
        return Result.fail(NotFoundFailure(message: 'Reservation not found'));
      }
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<EggReservation>>> getReservationsInRange(DateTime start, DateTime end) async {
    try {
      final reservations = await remoteDataSource.getReservationsInRange(start, end);
      return Result.success(reservations);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggReservation>> createReservation(EggReservation reservation) async {
    try {
      final model = EggReservationModel.fromEntity(reservation);
      final created = await remoteDataSource.createReservation(model);
      return Result.success(created);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EggReservation>> updateReservation(EggReservation reservation) async {
    try {
      final model = EggReservationModel.fromEntity(reservation);
      final updated = await remoteDataSource.updateReservation(model);
      return Result.success(updated);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteReservation(String id) async {
    try {
      await remoteDataSource.deleteReservation(id);
      return Result.success(null);
    } catch (e) {
      return Result.fail(ServerFailure(message: e.toString()));
    }
  }
}
