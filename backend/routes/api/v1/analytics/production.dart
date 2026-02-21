import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/analytics/data/repositories/analytics_repository.dart';

/// GET /api/v1/analytics/production - Get production analytics with predictions
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

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

    final repository = AnalyticsRepository(SupabaseClientManager.client);
    final result = await repository.getProductionAnalytics(userId, farmId: farmId);

    return result.fold(
      onSuccess: (production) => Response.json(body: {'data': production.toJson()}),
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
