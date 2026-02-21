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
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final queryParams = context.request.uri.queryParameters;
    final farmId = queryParams['farm_id'];

    final repository = ReservationRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.getReservations(userId, farmId: farmId);

    return result.fold(
      onSuccess: (reservations) => Response.json(
        body: {
          'data': reservations.map((r) => r.toJson()).toList(),
          'count': reservations.length,
        },
      ),
      onFailure: (f) => Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': f.message},
      ),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _createReservation(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

    // Validate required fields
    final validation = ReservationValidator.validate(body);
    if (!validation.isValid) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Validation failed', 'details': validation.errors},
      );
    }

    final farmId = body['farm_id'] as String?;
    final reservation = Reservation(
      id: '',
      userId: userId,
      farmId: farmId,
      date: body['date'] as String,
      pickupDate: body['pickup_date'] as String?,
      quantity: body['quantity'] as int,
      pricePerEgg: (body['price_per_egg'] as num?)?.toDouble(),
      pricePerDozen: (body['price_per_dozen'] as num?)?.toDouble(),
      customerName: body['customer_name'] as String?,
      customerEmail: body['customer_email'] as String?,
      customerPhone: body['customer_phone'] as String?,
      notes: body['notes'] as String?,
      createdAt: DateTime.now().toUtc(),
    );

    final repository = ReservationRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.createReservation(reservation);

    return result.fold(
      onSuccess: (r) => Response.json(
        statusCode: HttpStatus.created,
        body: {'data': r.toJson()},
      ),
      onFailure: (f) => Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': f.message},
      ),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}
