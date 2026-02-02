import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../../lib/core/core.dart';
import '../../../../../lib/features/feed_stock/data/repositories/feed_stock_repository_impl.dart';
import '../../../../../lib/features/feed_stock/domain/entities/feed_stock.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getFeedStock(context, id),
    HttpMethod.put => _updateFeedStock(context, id),
    HttpMethod.delete => _deleteFeedStock(context, id),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getFeedStock(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = FeedStockRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.getFeedStockById(id);

    return result.fold(
      onSuccess: (feedStock) => feedStock.userId != userId
          ? Response.json(statusCode: HttpStatus.forbidden, body: {'error': 'Access denied'})
          : Response.json(body: {'data': feedStock.toJson()}),
      onFailure: (f) => Response.json(statusCode: f is NotFoundFailure ? HttpStatus.notFound : HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _updateFeedStock(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = FeedStockRepositoryImpl(SupabaseClientManager.client);
    final existing = await repository.getFeedStockById(id);
    final existingFeedStock = existing.valueOrNull;
    if (existingFeedStock == null) return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Not found'});
    if (existingFeedStock.userId != userId) return Response.json(statusCode: HttpStatus.forbidden, body: {'error': 'Access denied'});

    final body = await context.request.json() as Map<String, dynamic>;

    // Validate for update
    final validation = FeedStockValidator.validate(body, isUpdate: true);
    if (!validation.isValid) {
      return Response.json(statusCode: HttpStatus.badRequest, body: {'error': validation.errors.join(', ')});
    }

    final updated = FeedStock(
      id: id,
      userId: existingFeedStock.userId,
      type: body['type'] != null
          ? FeedType.fromString(body['type'] as String)
          : existingFeedStock.type,
      brand: body.containsKey('brand') ? body['brand'] as String? : existingFeedStock.brand,
      currentQuantityKg: (body['current_quantity_kg'] as num?)?.toDouble() ?? existingFeedStock.currentQuantityKg,
      minimumQuantityKg: (body['minimum_quantity_kg'] as num?)?.toDouble() ?? existingFeedStock.minimumQuantityKg,
      pricePerKg: body.containsKey('price_per_kg') ? (body['price_per_kg'] as num?)?.toDouble() : existingFeedStock.pricePerKg,
      notes: body.containsKey('notes') ? body['notes'] as String? : existingFeedStock.notes,
      lastUpdated: DateTime.now().toUtc(),
      createdAt: existingFeedStock.createdAt,
    );

    final result = await repository.updateFeedStock(updated);
    return result.fold(
      onSuccess: (f) => Response.json(body: {'data': f.toJson()}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _deleteFeedStock(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = FeedStockRepositoryImpl(SupabaseClientManager.client);
    final existing = await repository.getFeedStockById(id);
    final existingFeedStock = existing.valueOrNull;
    if (existingFeedStock == null) return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Not found'});
    if (existingFeedStock.userId != userId) return Response.json(statusCode: HttpStatus.forbidden, body: {'error': 'Access denied'});

    final result = await repository.deleteFeedStock(id);
    return result.fold(
      onSuccess: (_) => Response(statusCode: HttpStatus.noContent),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}
