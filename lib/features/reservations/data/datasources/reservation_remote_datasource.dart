import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/context/farm_context.dart';
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

  String? get _farmId => FarmContext().farmId;

  String get _userId {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.id;
  }

  String _toIsoDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<EggReservationModel>> getReservations() async {
    var query = client.from('egg_reservations').select();

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query.order('date', ascending: false);

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

    var query = client.from('egg_reservations').select();

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => EggReservationModel.fromJson(json))
        .toList();
  }

  @override
  Future<EggReservationModel> createReservation(EggReservationModel reservation) async {
    final data = reservation.toJson();
    data['user_id'] = _userId;
    if (_farmId != null) {
      data['farm_id'] = _farmId;
    }

    final response = await client
        .from('egg_reservations')
        .insert(data)
        .select()
        .single();

    return EggReservationModel.fromJson(response);
  }

  @override
  Future<EggReservationModel> updateReservation(EggReservationModel reservation) async {
    final data = reservation.toJson();
    if (_farmId != null) {
      data['farm_id'] = _farmId;
    }

    final response = await client
        .from('egg_reservations')
        .update(data)
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
