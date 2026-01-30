import '../../../../core/core.dart';
import '../entities/egg_reservation.dart';

abstract class ReservationRepository {
  Future<Result<List<EggReservation>>> getReservations();
  Future<Result<EggReservation>> getReservationById(String id);
  Future<Result<List<EggReservation>>> getReservationsInRange(DateTime start, DateTime end);
  Future<Result<EggReservation>> createReservation(EggReservation reservation);
  Future<Result<EggReservation>> updateReservation(EggReservation reservation);
  Future<Result<void>> deleteReservation(String id);
}
