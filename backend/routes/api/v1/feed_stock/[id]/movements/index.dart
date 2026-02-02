import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../../../lib/core/core.dart';
import '../../../../../../lib/features/feed_stock/data/repositories/feed_stock_repository_impl.dart';
import '../../../../../../lib/features/feed_stock/domain/entities/feed_stock.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getMovements(context, id),
    HttpMethod.post => _addMovement(context, id),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getMovements(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = FeedStockRepositoryImpl(SupabaseClientManager.client);

    // Verify the feed stock belongs to the user
    final stockResult = await repository.getFeedStockById(id);
    if (!stockResult.isSuccess || stockResult.valueOrNull == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Feed stock not found'},
      );
    }

    if (stockResult.valueOrNull!.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    final result = await repository.getFeedMovements(userId, id);

    return result.fold(
      onSuccess: (movements) => Response.json(
        body: {'data': movements.map((m) => m.toJson()).toList()},
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

Future<Response> _addMovement(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = FeedStockRepositoryImpl(SupabaseClientManager.client);

    // Verify the feed stock belongs to the user
    final stockResult = await repository.getFeedStockById(id);
    if (!stockResult.isSuccess || stockResult.valueOrNull == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Feed stock not found'},
      );
    }

    if (stockResult.valueOrNull!.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

    // Validate required fields
    final movementType = body['movement_type'] as String?;
    final quantityKg = body['quantity_kg'];
    final date = body['date'] as String?;

    if (movementType == null || movementType.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'movement_type is required'},
      );
    }

    if (quantityKg == null || (quantityKg as num) <= 0) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'quantity_kg must be a positive number'},
      );
    }

    if (date == null || date.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'date is required'},
      );
    }

    final movement = FeedMovement(
      id: '',
      userId: userId,
      feedStockId: id,
      movementType: StockMovementType.fromString(movementType),
      quantityKg: (quantityKg as num).toDouble(),
      cost: (body['cost'] as num?)?.toDouble(),
      date: date,
      notes: body['notes'] as String?,
      createdAt: DateTime.now().toUtc(),
    );

    final result = await repository.addFeedMovement(movement);

    return result.fold(
      onSuccess: (m) => Response.json(
        statusCode: HttpStatus.created,
        body: {'data': m.toJson()},
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
