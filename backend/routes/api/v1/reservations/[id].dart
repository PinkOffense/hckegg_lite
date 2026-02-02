import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/reservations/data/repositories/reservation_repository_impl.dart';
import '../../../../lib/features/reservations/domain/entities/reservation.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getReservation(context, id),
    HttpMethod.put => _updateReservation(context, id),
    HttpMethod.delete => _deleteReservation(context, id),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getReservation(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = ReservationRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.getReservationById(id);

    return result.fold(
      onSuccess: (reservation) => reservation.userId != userId
          ? Response.json(
              statusCode: HttpStatus.forbidden,
              body: {'error': 'Access denied'},
            )
          : Response.json(body: {'data': reservation.toJson()}),
      onFailure: (f) => Response.json(
        statusCode:
            f is NotFoundFailure ? HttpStatus.notFound : HttpStatus.internalServerError,
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

Future<Response> _updateReservation(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = ReservationRepositoryImpl(SupabaseClientManager.client);
    final existing = await repository.getReservationById(id);
    final existingReservation = existing.valueOrNull;
    if (existingReservation == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Not found'},
      );
    }
    if (existingReservation.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

    // Validate update data
    final validation = ReservationValidator.validate(body, isUpdate: true);
    if (!validation.isValid) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Validation failed', 'details': validation.errors},
      );
    }

    final updated = Reservation(
      id: id,
      userId: existingReservation.userId,
      date: (body['date'] as String?) ?? existingReservation.date,
      pickupDate: body.containsKey('pickup_date')
          ? body['pickup_date'] as String?
          : existingReservation.pickupDate,
      quantity: (body['quantity'] as int?) ?? existingReservation.quantity,
      pricePerEgg: body.containsKey('price_per_egg')
          ? (body['price_per_egg'] as num?)?.toDouble()
          : existingReservation.pricePerEgg,
      pricePerDozen: body.containsKey('price_per_dozen')
          ? (body['price_per_dozen'] as num?)?.toDouble()
          : existingReservation.pricePerDozen,
      customerName: body.containsKey('customer_name')
          ? body['customer_name'] as String?
          : existingReservation.customerName,
      customerEmail: body.containsKey('customer_email')
          ? body['customer_email'] as String?
          : existingReservation.customerEmail,
      customerPhone: body.containsKey('customer_phone')
          ? body['customer_phone'] as String?
          : existingReservation.customerPhone,
      notes: body.containsKey('notes')
          ? body['notes'] as String?
          : existingReservation.notes,
      createdAt: existingReservation.createdAt,
    );

    final result = await repository.updateReservation(updated);
    return result.fold(
      onSuccess: (r) => Response.json(body: {'data': r.toJson()}),
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

Future<Response> _deleteReservation(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = ReservationRepositoryImpl(SupabaseClientManager.client);
    final existing = await repository.getReservationById(id);
    final existingReservation = existing.valueOrNull;
    if (existingReservation == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Not found'},
      );
    }
    if (existingReservation.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    final result = await repository.deleteReservation(id);
    return result.fold(
      onSuccess: (_) => Response(statusCode: HttpStatus.noContent),
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
