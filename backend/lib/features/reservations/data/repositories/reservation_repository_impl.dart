import 'package:supabase/supabase.dart';
import '../../../../core/core.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  ReservationRepositoryImpl(this._client);
  final SupabaseClient _client;
  static const _table = 'reservations';

  @override
  Future<Result<List<Reservation>>> getReservations(String userId) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).order('date', ascending: false);
      return Result.success((response as List).map((j) => Reservation.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Reservation>> getReservationById(String id) async {
    try {
      final response = await _client.from(_table).select().eq('id', id).single();
      return Result.success(Reservation.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return Result.failure(const NotFoundFailure(message: 'Reservation not found'));
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Reservation>>> getReservationsInRange(String userId, String startDate, String endDate) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).gte('date', startDate).lte('date', endDate).order('date', ascending: false);
      return Result.success((response as List).map((j) => Reservation.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Reservation>>> getReservationsByStatus(String userId, ReservationStatus status) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).eq('status', status.name);
      return Result.success((response as List).map((j) => Reservation.fromJson(j as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Reservation>> createReservation(Reservation reservation) async {
    try {
      final data = {
        'user_id': reservation.userId,
        'date': reservation.date,
        'customer_name': reservation.customerName,
        'customer_phone': reservation.customerPhone,
        'quantity': reservation.quantity,
        'price_per_egg': reservation.pricePerEgg,
        'status': reservation.status.name,
        'notes': reservation.notes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      final response = await _client.from(_table).insert(data).select().single();
      return Result.success(Reservation.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Reservation>> updateReservation(Reservation reservation) async {
    try {
      final data = {
        'date': reservation.date,
        'customer_name': reservation.customerName,
        'customer_phone': reservation.customerPhone,
        'quantity': reservation.quantity,
        'price_per_egg': reservation.pricePerEgg,
        'status': reservation.status.name,
        'notes': reservation.notes,
      };
      final response = await _client.from(_table).update(data).eq('id', reservation.id).select().single();
      return Result.success(Reservation.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteReservation(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ReservationStatistics>> getStatistics(String userId, String startDate, String endDate) async {
    try {
      final response = await _client.from(_table).select().eq('user_id', userId).gte('date', startDate).lte('date', endDate);
      final reservations = (response as List).map((j) => Reservation.fromJson(j as Map<String, dynamic>)).toList();

      final byStatus = <String, int>{};
      var totalQuantity = 0;
      var totalAmount = 0.0;
      for (final r in reservations) {
        totalQuantity += r.quantity;
        totalAmount += r.totalAmount;
        byStatus[r.status.name] = (byStatus[r.status.name] ?? 0) + 1;
      }

      return Result.success(ReservationStatistics(
        totalReservations: reservations.length,
        totalQuantity: totalQuantity,
        totalAmount: totalAmount,
        byStatus: byStatus,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
