import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/sales/data/repositories/sale_repository_impl.dart';
import '../../../../lib/features/sales/domain/entities/sale.dart';
import '../../../../lib/features/sales/domain/usecases/sale_usecases.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getSales(context),
    HttpMethod.post => _createSale(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getSales(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});
    }

    final queryParams = context.request.uri.queryParameters;
    final farmId = queryParams['farm_id'];

    final repository = SaleRepositoryImpl(SupabaseClientManager.client);
    final useCase = GetSales(repository);
    final result = await useCase(GetSalesParams(userId: userId, farmId: farmId));

    return result.fold(
      onSuccess: (sales) => Response.json(body: {'data': sales.map((s) => s.toJson()).toList(), 'count': sales.length}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _createSale(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});
    }

    final body = await context.request.json() as Map<String, dynamic>;

    final farmId = body['farm_id'] as String?;
    final sale = Sale(
      id: '',
      userId: userId,
      farmId: farmId,
      date: body['date'] as String,
      quantitySold: body['quantity_sold'] as int,
      pricePerEgg: (body['price_per_egg'] as num).toDouble(),
      pricePerDozen: (body['price_per_dozen'] as num).toDouble(),
      customerName: body['customer_name'] as String?,
      customerEmail: body['customer_email'] as String?,
      customerPhone: body['customer_phone'] as String?,
      notes: body['notes'] as String?,
      paymentStatus: PaymentStatus.fromString(body['payment_status'] as String? ?? 'pending'),
      paymentDate: body['payment_date'] as String?,
      isReservation: body['is_reservation'] as bool? ?? false,
      reservationNotes: body['reservation_notes'] as String?,
      isLost: body['is_lost'] as bool? ?? false,
      createdAt: DateTime.now().toUtc(),
    );

    final repository = SaleRepositoryImpl(SupabaseClientManager.client);
    final useCase = CreateSale(repository);
    final result = await useCase(CreateSaleParams(sale: sale));

    return result.fold(
      onSuccess: (s) => Response.json(statusCode: HttpStatus.created, body: {'data': s.toJson()}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}
