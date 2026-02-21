import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/analytics/data/repositories/analytics_repository.dart';

/// GET /api/v1/analytics/expenses - Get expenses analytics
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
    final result = await repository.getExpensesAnalytics(userId, farmId: farmId);

    return result.fold(
      onSuccess: (expenses) => Response.json(body: {'data': expenses.toJson()}),
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
