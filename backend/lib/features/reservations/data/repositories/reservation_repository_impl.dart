import 'package:supabase/supabase.dart';
import '../../../../core/core.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  ReservationRepositoryImpl(this._client);
  final SupabaseClient _client;
  static const _table = 'egg_reservations';

  @override
  Future<Result<List<Reservation>>> getReservations(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      return Result.success(
        (response as List)
            .map((j) => Reservation.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Reservation>> getReservationById(String id) async {
    try {
      final response =
          await _client.from(_table).select().eq('id', id).single();
      return Result.success(Reservation.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Result.failure(
          const NotFoundFailure(message: 'Reservation not found'),
        );
      }
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Reservation>>> getReservationsInRange(
    String userId,
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', ascending: false);
      return Result.success(
        (response as List)
            .map((j) => Reservation.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Reservation>>> getUpcomingPickups(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .gte('pickup_date', today)
          .order('pickup_date', ascending: true);
      return Result.success(
        (response as List)
            .map((j) => Reservation.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
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
        'pickup_date': reservation.pickupDate,
        'quantity': reservation.quantity,
        'price_per_egg': reservation.pricePerEgg,
        'price_per_dozen': reservation.pricePerDozen,
        'customer_name': reservation.customerName,
        'customer_email': reservation.customerEmail,
        'customer_phone': reservation.customerPhone,
        'notes': reservation.notes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      final response =
          await _client.from(_table).insert(data).select().single();
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
        'pickup_date': reservation.pickupDate,
        'quantity': reservation.quantity,
        'price_per_egg': reservation.pricePerEgg,
        'price_per_dozen': reservation.pricePerDozen,
        'customer_name': reservation.customerName,
        'customer_email': reservation.customerEmail,
        'customer_phone': reservation.customerPhone,
        'notes': reservation.notes,
      };
      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', reservation.id)
          .select()
          .single();
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
}
