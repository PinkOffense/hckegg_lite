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
    final userId = context.request.headers['x-user-id'];
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
    final userId = context.request.headers['x-user-id'];
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final body = await context.request.json() as Map<String, dynamic>;
    final feedStock = FeedStock(
      id: '',
      userId: userId,
      date: body['date'] as String,
      feedType: body['feed_type'] as String,
      quantityKg: (body['quantity_kg'] as num).toDouble(),
      cost: (body['cost'] as num).toDouble(),
      supplier: body['supplier'] as String?,
      notes: body['notes'] as String?,
      createdAt: DateTime.now().toUtc(),
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
