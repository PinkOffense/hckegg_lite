import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/core/core.dart';
import '../../../../lib/features/eggs/data/repositories/egg_repository_impl.dart';
import '../../../../lib/features/eggs/domain/entities/egg_record.dart';
import '../../../../lib/features/eggs/domain/usecases/egg_usecases.dart';

/// Handler for /api/v1/eggs/:id
/// GET - Get egg record by ID (or statistics if id == 'statistics')
/// PUT - Update egg record
/// DELETE - Delete egg record
Future<Response> onRequest(RequestContext context, String id) async {
  // Handle statistics route (workaround for route conflict)
  if (id == 'statistics') {
    return _handleStatistics(context);
  }

  // Validate ID format
  if (!Validators.isValidUuid(id)) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid ID format'},
    );
  }

  return switch (context.request.method) {
    HttpMethod.get => _getEggRecord(context, id),
    HttpMethod.put => _updateEggRecord(context, id),
    HttpMethod.delete => _deleteEggRecord(context, id),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

/// GET /api/v1/eggs/statistics
Future<Response> _handleStatistics(RequestContext context) async {
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

/// GET /api/v1/eggs/:id
Future<Response> _getEggRecord(RequestContext context, String id) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
      Logger.warning('GET /eggs/$id - Missing user ID');
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = EggRepositoryImpl(SupabaseClientManager.client);
    final useCase = GetEggRecordById(repository);
    final result = await useCase(GetEggRecordByIdParams(id: id));

    return result.fold(
      onSuccess: (record) {
        if (record.userId != userId) {
          Logger.warning('GET /eggs/$id - Access denied for user $userId');
          return Response.json(
            statusCode: HttpStatus.forbidden,
            body: {'error': 'Access denied'},
          );
        }
        Logger.debug('GET /eggs/$id - Retrieved for user $userId');
        return Response.json(body: {'data': record.toJson()});
      },
      onFailure: (failure) {
        final statusCode = failure is NotFoundFailure
            ? HttpStatus.notFound
            : HttpStatus.internalServerError;
        Logger.error('GET /eggs/$id - Failed', failure.message);
        return Response.json(
          statusCode: statusCode,
          body: {'error': failure.message},
        );
      },
    );
  } catch (e, stackTrace) {
    Logger.error('GET /eggs/$id - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}

/// PUT /api/v1/eggs/:id
Future<Response> _updateEggRecord(RequestContext context, String id) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
      Logger.warning('PUT /eggs/$id - Missing user ID');
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = EggRepositoryImpl(SupabaseClientManager.client);
    final getUseCase = GetEggRecordById(repository);
    final existingResult = await getUseCase(GetEggRecordByIdParams(id: id));

    final existingRecord = existingResult.valueOrNull;
    if (existingRecord == null) {
      Logger.warning('PUT /eggs/$id - Record not found');
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Egg record not found'},
      );
    }

    if (existingRecord.userId != userId) {
      Logger.warning('PUT /eggs/$id - Access denied for user $userId');
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

    // Validate input
    final validation = EggRecordValidator.validate(body, isUpdate: true);
    if (!validation.isValid) {
      Logger.warning('PUT /eggs/$id - Validation failed: ${validation.errors}');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Validation failed', 'details': validation.errors},
      );
    }

    final updatedRecord = EggRecord(
      id: id,
      userId: existingRecord.userId,
      date: (body['date'] as String?) ?? existingRecord.date,
      eggsCollected:
          (body['eggs_collected'] as int?) ?? existingRecord.eggsCollected,
      eggsBroken: (body['eggs_broken'] as int?) ?? existingRecord.eggsBroken,
      eggsConsumed:
          (body['eggs_consumed'] as int?) ?? existingRecord.eggsConsumed,
      notes: body.containsKey('notes')
          ? body['notes'] as String?
          : existingRecord.notes,
      createdAt: existingRecord.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );

    final updateUseCase = UpdateEggRecord(repository);
    final result =
        await updateUseCase(UpdateEggRecordParams(record: updatedRecord));

    return result.fold(
      onSuccess: (record) {
        Logger.info('PUT /eggs/$id - Updated for user $userId');
        return Response.json(body: {'data': record.toJson()});
      },
      onFailure: (failure) {
        Logger.error('PUT /eggs/$id - Failed to update', failure.message);
        return Response.json(
          statusCode: HttpStatus.internalServerError,
          body: {'error': failure.message},
        );
      },
    );
  } catch (e, stackTrace) {
    Logger.error('PUT /eggs/$id - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}

/// DELETE /api/v1/eggs/:id
Future<Response> _deleteEggRecord(RequestContext context, String id) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
      Logger.warning('DELETE /eggs/$id - Missing user ID');
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = EggRepositoryImpl(SupabaseClientManager.client);
    final getUseCase = GetEggRecordById(repository);
    final existingResult = await getUseCase(GetEggRecordByIdParams(id: id));

    final existingRecord = existingResult.valueOrNull;
    if (existingRecord == null) {
      Logger.warning('DELETE /eggs/$id - Record not found');
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Egg record not found'},
      );
    }

    if (existingRecord.userId != userId) {
      Logger.warning('DELETE /eggs/$id - Access denied for user $userId');
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    final deleteUseCase = DeleteEggRecord(repository);
    final result = await deleteUseCase(DeleteEggRecordParams(id: id));

    return result.fold(
      onSuccess: (_) {
        Logger.info('DELETE /eggs/$id - Deleted for user $userId');
        return Response(statusCode: HttpStatus.noContent);
      },
      onFailure: (failure) {
        Logger.error('DELETE /eggs/$id - Failed to delete', failure.message);
        return Response.json(
          statusCode: HttpStatus.internalServerError,
          body: {'error': failure.message},
        );
      },
    );
  } catch (e, stackTrace) {
    Logger.error('DELETE /eggs/$id - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
