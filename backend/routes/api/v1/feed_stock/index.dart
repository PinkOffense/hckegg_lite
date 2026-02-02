import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/feed_stock/data/repositories/feed_stock_repository_impl.dart';
import '../../../../lib/features/feed_stock/domain/entities/feed_stock.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getFeedStocks(context),
    HttpMethod.post => _createFeedStock(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getFeedStocks(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = FeedStockRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.getFeedStocks(userId);

    return result.fold(
      onSuccess: (feedStocks) => Response.json(body: {'data': feedStocks.map((f) => f.toJson()).toList(), 'count': feedStocks.length}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _createFeedStock(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final body = await context.request.json() as Map<String, dynamic>;

    // Validate required fields
    final validation = FeedStockValidator.validate(body);
    if (!validation.isValid) {
      return Response.json(statusCode: HttpStatus.badRequest, body: {'error': validation.errors.join(', ')});
    }

    final now = DateTime.now().toUtc();
    final feedStock = FeedStock(
      id: '',
      userId: userId,
      type: FeedType.fromString(body['type'] as String),
      brand: body['brand'] as String?,
      currentQuantityKg: (body['current_quantity_kg'] as num?)?.toDouble() ?? 0.0,
      minimumQuantityKg: (body['minimum_quantity_kg'] as num?)?.toDouble() ?? 10.0,
      pricePerKg: (body['price_per_kg'] as num?)?.toDouble(),
      notes: body['notes'] as String?,
      lastUpdated: now,
      createdAt: now,
    );

    final repository = FeedStockRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.createFeedStock(feedStock);

    return result.fold(
      onSuccess: (f) => Response.json(statusCode: HttpStatus.created, body: {'data': f.toJson()}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}
