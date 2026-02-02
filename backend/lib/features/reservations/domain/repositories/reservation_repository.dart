import '../../../../core/core.dart';
import '../entities/reservation.dart';

abstract class ReservationRepository {
  Future<Result<List<Reservation>>> getReservations(String userId);
  Future<Result<Reservation>> getReservationById(String id);
  Future<Result<List<Reservation>>> getReservationsInRange(
    String userId,
    String startDate,
    String endDate,
  );
  Future<Result<List<Reservation>>> getUpcomingPickups(String userId);
  Future<Result<Reservation>> createReservation(Reservation reservation);
  Future<Result<Reservation>> updateReservation(Reservation reservation);
  Future<Result<void>> deleteReservation(String id);
}

class ReservationStatistics {
  const ReservationStatistics({
    required this.totalReservations,
    required this.totalQuantity,
    required this.totalAmount,
  });

  final int totalReservations;
  final int totalQuantity;
  final double totalAmount;

  Map<String, dynamic> toJson() => {
        'total_reservations': totalReservations,
        'total_quantity': totalQuantity,
        'total_amount': totalAmount,
      };
}
