import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/egg_reservation_model.dart';

abstract class ReservationRemoteDataSource {
  Future<List<EggReservationModel>> getReservations();
  Future<EggReservationModel> getReservationById(String id);
  Future<List<EggReservationModel>> getReservationsInRange(DateTime start, DateTime end);
  Future<EggReservationModel> createReservation(EggReservationModel reservation);
  Future<EggReservationModel> updateReservation(EggReservationModel reservation);
  Future<void> deleteReservation(String id);
}

class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  final SupabaseClient client;

  ReservationRemoteDataSourceImpl({required this.client});

  String _toIsoDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<EggReservationModel>> getReservations() async {
    final response = await client
        .from('egg_reservations')
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((json) => EggReservationModel.fromJson(json))
        .toList();
  }

  @override
  Future<EggReservationModel> getReservationById(String id) async {
    final response = await client
        .from('egg_reservations')
        .select()
        .eq('id', id)
        .single();

    return EggReservationModel.fromJson(response);
  }

  @override
  Future<List<EggReservationModel>> getReservationsInRange(DateTime start, DateTime end) async {
    final startStr = _toIsoDateString(start);
    final endStr = _toIsoDateString(end);

    final response = await client
        .from('egg_reservations')
        .select()
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => EggReservationModel.fromJson(json))
        .toList();
  }

  @override
  Future<EggReservationModel> createReservation(EggReservationModel reservation) async {
    final response = await client
        .from('egg_reservations')
        .insert(reservation.toJson())
        .select()
        .single();

    return EggReservationModel.fromJson(response);
  }

  @override
  Future<EggReservationModel> updateReservation(EggReservationModel reservation) async {
    final response = await client
        .from('egg_reservations')
        .update(reservation.toJson())
        .eq('id', reservation.id)
        .select()
        .single();

    return EggReservationModel.fromJson(response);
  }

  @override
  Future<void> deleteReservation(String id) async {
    await client.from('egg_reservations').delete().eq('id', id);
  }
}
