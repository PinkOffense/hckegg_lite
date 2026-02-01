import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/core/core.dart';
import '../../../../lib/features/eggs/data/repositories/egg_repository_impl.dart';
import '../../../../lib/features/eggs/domain/usecases/egg_usecases.dart';

/// Handler for /api/v1/eggs/statistics
/// GET - Get egg statistics for a date range
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final queryParams = context.request.uri.queryParameters;
    final startDate = queryParams['start_date'];
    final endDate = queryParams['end_date'];

    if (startDate == null || endDate == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Missing required query parameters: start_date, end_date'},
      );
    }

    final repository = EggRepositoryImpl(SupabaseClientManager.client);
    final useCase = GetEggStatistics(repository);
    final result = await useCase(
      GetEggStatisticsParams(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      ),
    );

    return result.fold(
      onSuccess: (stats) => Response.json(body: {'data': stats.toJson()}),
      onFailure: (failure) => Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': failure.message},
      ),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}
