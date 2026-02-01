import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/sales/data/repositories/sale_repository_impl.dart';
import '../../../../lib/features/sales/domain/entities/sale.dart';
import '../../../../lib/features/sales/domain/usecases/sale_usecases.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getSale(context, id),
    HttpMethod.put => _updateSale(context, id),
    HttpMethod.delete => _deleteSale(context, id),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getSale(RequestContext context, String id) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = SaleRepositoryImpl(SupabaseClientManager.client);
    final result = await GetSaleById(repository)(GetSaleByIdParams(id: id));

    return result.fold(
      onSuccess: (sale) => sale.userId != userId
          ? Response.json(statusCode: HttpStatus.forbidden, body: {'error': 'Access denied'})
          : Response.json(body: {'data': sale.toJson()}),
      onFailure: (f) => Response.json(
        statusCode: f is NotFoundFailure ? HttpStatus.notFound : HttpStatus.internalServerError,
        body: {'error': f.message},
      ),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _updateSale(RequestContext context, String id) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = SaleRepositoryImpl(SupabaseClientManager.client);
    final existing = await GetSaleById(repository)(GetSaleByIdParams(id: id));
    final existingSale = existing.valueOrNull;
    if (existingSale == null) return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Not found'});
    if (existingSale.userId != userId) return Response.json(statusCode: HttpStatus.forbidden, body: {'error': 'Access denied'});

    final body = await context.request.json() as Map<String, dynamic>;
    final updated = Sale(
      id: id,
      userId: existingSale.userId,
      date: (body['date'] as String?) ?? existingSale.date,
      quantitySold: (body['quantity_sold'] as int?) ?? existingSale.quantitySold,
      pricePerEgg: (body['price_per_egg'] as num?)?.toDouble() ?? existingSale.pricePerEgg,
      pricePerDozen: (body['price_per_dozen'] as num?)?.toDouble() ?? existingSale.pricePerDozen,
      customerName: body['customer_name'] as String? ?? existingSale.customerName,
      customerEmail: body['customer_email'] as String? ?? existingSale.customerEmail,
      customerPhone: body['customer_phone'] as String? ?? existingSale.customerPhone,
      notes: body['notes'] as String? ?? existingSale.notes,
      paymentStatus: body['payment_status'] != null
          ? PaymentStatus.fromString(body['payment_status'] as String)
          : existingSale.paymentStatus,
      paymentDate: body['payment_date'] as String? ?? existingSale.paymentDate,
      isReservation: (body['is_reservation'] as bool?) ?? existingSale.isReservation,
      reservationNotes: body['reservation_notes'] as String? ?? existingSale.reservationNotes,
      isLost: (body['is_lost'] as bool?) ?? existingSale.isLost,
      createdAt: existingSale.createdAt,
    );

    final result = await UpdateSale(repository)(UpdateSaleParams(sale: updated));
    return result.fold(
      onSuccess: (s) => Response.json(body: {'data': s.toJson()}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _deleteSale(RequestContext context, String id) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = SaleRepositoryImpl(SupabaseClientManager.client);
    final existing = await GetSaleById(repository)(GetSaleByIdParams(id: id));
    final existingSale = existing.valueOrNull;
    if (existingSale == null) return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Not found'});
    if (existingSale.userId != userId) return Response.json(statusCode: HttpStatus.forbidden, body: {'error': 'Access denied'});

    final result = await DeleteSale(repository)(DeleteSaleParams(id: id));
    return result.fold(
      onSuccess: (_) => Response(statusCode: HttpStatus.noContent),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}
