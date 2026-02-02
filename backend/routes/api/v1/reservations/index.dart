import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/reservations/data/repositories/reservation_repository_impl.dart';
import '../../../../lib/features/reservations/domain/entities/reservation.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getReservations(context),
    HttpMethod.post => _createReservation(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getReservations(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = ReservationRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.getReservations(userId);

    return result.fold(
      onSuccess: (reservations) => Response.json(body: {'data': reservations.map((r) => r.toJson()).toList(), 'count': reservations.length}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _createReservation(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final body = await context.request.json() as Map<String, dynamic>;
    final reservation = Reservation(
      id: '',
      userId: userId,
      date: body['date'] as String,
      customerName: body['customer_name'] as String,
      customerPhone: body['customer_phone'] as String,
      quantity: body['quantity'] as int,
      pricePerEgg: (body['price_per_egg'] as num).toDouble(),
      status: ReservationStatus.fromString((body['status'] as String?) ?? 'pending'),
      notes: body['notes'] as String?,
      createdAt: DateTime.now().toUtc(),
    );

    final repository = ReservationRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.createReservation(reservation);

    return result.fold(
      onSuccess: (r) => Response.json(statusCode: HttpStatus.created, body: {'data': r.toJson()}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}
