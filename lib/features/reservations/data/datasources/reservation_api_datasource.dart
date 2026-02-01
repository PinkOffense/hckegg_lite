import '../../../../core/api/api_client.dart';
import '../models/egg_reservation_model.dart';
import 'reservation_remote_datasource.dart';

/// API implementation of ReservationRemoteDataSource
class ReservationApiDataSourceImpl implements ReservationRemoteDataSource {
  final ApiClient apiClient;
  static const _basePath = '/api/v1/reservations';

  ReservationApiDataSourceImpl({required this.apiClient});

  String _toIsoDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<EggReservationModel>> getReservations() async {
    final response = await apiClient.get<Map<String, dynamic>>(_basePath);
    final data = response['data'] as List;
    return data.map((json) => EggReservationModel.fromJson(json)).toList();
  }

  @override
  Future<EggReservationModel> getReservationById(String id) async {
    final response = await apiClient.get<Map<String, dynamic>>('$_basePath/$id');
    return EggReservationModel.fromJson(response['data']);
  }

  @override
  Future<List<EggReservationModel>> getReservationsInRange(DateTime start, DateTime end) async {
    final startStr = _toIsoDateString(start);
    final endStr = _toIsoDateString(end);

    final response = await apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'start_date': startStr, 'end_date': endStr},
    );
    final data = response['data'] as List;
    return data.map((json) => EggReservationModel.fromJson(json)).toList();
  }

  @override
  Future<EggReservationModel> createReservation(EggReservationModel reservation) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: reservation.toJson(),
    );
    return EggReservationModel.fromJson(response['data']);
  }

  @override
  Future<EggReservationModel> updateReservation(EggReservationModel reservation) async {
    final response = await apiClient.put<Map<String, dynamic>>(
      '$_basePath/${reservation.id}',
      data: reservation.toJson(),
    );
    return EggReservationModel.fromJson(response['data']);
  }

  @override
  Future<void> deleteReservation(String id) async {
    await apiClient.delete('$_basePath/$id');
  }
}
