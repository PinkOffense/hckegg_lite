import '../../../../core/api/api_client.dart';
import '../../../../core/date_utils.dart';
import '../../../../core/errors/failures.dart';
import '../models/egg_reservation_model.dart';
import 'reservation_remote_datasource.dart';

/// API implementation of ReservationRemoteDataSource
class ReservationApiDataSourceImpl implements ReservationRemoteDataSource {
  final ApiClient _apiClient;
  static const _basePath = '/api/v1/reservations';

  ReservationApiDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data == null) {
      throw const ServerFailure(message: 'Invalid response: missing data', code: 'INVALID_RESPONSE');
    }
    return data as List;
  }

  Map<String, dynamic> _extractMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data == null) {
      throw const ServerFailure(message: 'Invalid response: missing data', code: 'INVALID_RESPONSE');
    }
    return data as Map<String, dynamic>;
  }

  @override
  Future<List<EggReservationModel>> getReservations() async {
    final response = await _apiClient.get<Map<String, dynamic>>(_basePath);
    final data = _extractList(response);
    return data.map((json) => EggReservationModel.fromJson(json)).toList();
  }

  @override
  Future<EggReservationModel> getReservationById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_basePath/$id');
    return EggReservationModel.fromJson(_extractMap(response));
  }

  @override
  Future<List<EggReservationModel>> getReservationsInRange(DateTime start, DateTime end) async {
    final startStr = AppDateUtils.toIsoDateString(start);
    final endStr = AppDateUtils.toIsoDateString(end);

    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {'start_date': startStr, 'end_date': endStr},
    );
    final data = _extractList(response);
    return data.map((json) => EggReservationModel.fromJson(json)).toList();
  }

  @override
  Future<EggReservationModel> createReservation(EggReservationModel reservation) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: reservation.toJson(),
    );
    return EggReservationModel.fromJson(_extractMap(response));
  }

  @override
  Future<EggReservationModel> updateReservation(EggReservationModel reservation) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/${reservation.id}',
      data: reservation.toJson(),
    );
    return EggReservationModel.fromJson(_extractMap(response));
  }

  @override
  Future<void> deleteReservation(String id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
