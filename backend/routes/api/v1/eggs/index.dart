import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/core/core.dart';
import '../../../../lib/features/eggs/data/repositories/egg_repository_impl.dart';
import '../../../../lib/features/eggs/domain/entities/egg_record.dart';
import '../../../../lib/features/eggs/domain/usecases/egg_usecases.dart';

/// Handler for /api/v1/eggs
/// GET - Get all egg records for authenticated user
/// POST - Create a new egg record
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getEggRecords(context),
    HttpMethod.post => _createEggRecord(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

/// GET /api/v1/eggs
Future<Response> _getEggRecords(RequestContext context) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
      Logger.warning('GET /eggs - Missing user ID');
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final queryParams = context.request.uri.queryParameters;
    final startDate = queryParams['start_date'];
    final endDate = queryParams['end_date'];
    final limit = int.tryParse(queryParams['limit'] ?? '') ?? 100;
    final offset = int.tryParse(queryParams['offset'] ?? '') ?? 0;

    // Validate date parameters if provided
    if (startDate != null && !Validators.isValidDate(startDate)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Invalid start_date format. Use YYYY-MM-DD'},
      );
    }
    if (endDate != null && !Validators.isValidDate(endDate)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Invalid end_date format. Use YYYY-MM-DD'},
      );
    }

    final repository = EggRepositoryImpl(SupabaseClientManager.client);

    final Result<List<EggRecord>> result;
    if (startDate != null && endDate != null) {
      final useCase = GetEggRecordsInRange(repository);
      result = await useCase(
        GetEggRecordsInRangeParams(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } else {
      final useCase = GetEggRecords(repository);
      result = await useCase(GetEggRecordsParams(userId: userId));
    }

    return result.fold(
      onSuccess: (records) {
        // Apply pagination
        final paginatedRecords = records.skip(offset).take(limit).toList();
        Logger.debug('GET /eggs - Returned ${paginatedRecords.length} records for user $userId');
        return Response.json(
          body: {
            'data': paginatedRecords.map((r) => r.toJson()).toList(),
            'count': paginatedRecords.length,
            'total': records.length,
            'limit': limit,
            'offset': offset,
          },
        );
      },
      onFailure: (failure) {
        Logger.error('GET /eggs - Failed', failure.message);
        return Response.json(
          statusCode: HttpStatus.internalServerError,
          body: {'error': failure.message},
        );
      },
    );
  } catch (e, stackTrace) {
    Logger.error('GET /eggs - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}

/// POST /api/v1/eggs
Future<Response> _createEggRecord(RequestContext context) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
      Logger.warning('POST /eggs - Missing user ID');
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

    // Validate input
    final validation = EggRecordValidator.validate(body);
    if (!validation.isValid) {
      Logger.warning('POST /eggs - Validation failed: ${validation.errors}');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Validation failed', 'details': validation.errors},
      );
    }

    final now = DateTime.now().toUtc();
    final record = EggRecord(
      id: '',
      userId: userId,
      date: body['date'] as String,
      eggsCollected: body['eggs_collected'] as int,
      eggsBroken: (body['eggs_broken'] as int?) ?? 0,
      eggsConsumed: (body['eggs_consumed'] as int?) ?? 0,
      notes: body['notes'] as String?,
      createdAt: now,
      updatedAt: now,
    );

    final repository = EggRepositoryImpl(SupabaseClientManager.client);
    final useCase = CreateEggRecord(repository);
    final result = await useCase(CreateEggRecordParams(record: record));

    return result.fold(
      onSuccess: (created) {
        Logger.info('POST /eggs - Created record ${created.id} for user $userId');
        return Response.json(
          statusCode: HttpStatus.created,
          body: {'data': created.toJson()},
        );
      },
      onFailure: (failure) {
        Logger.error('POST /eggs - Failed to create', failure.message);
        final statusCode = failure is ValidationFailure
            ? HttpStatus.badRequest
            : HttpStatus.internalServerError;
        return Response.json(
          statusCode: statusCode,
          body: {'error': failure.message},
        );
      },
    );
  } catch (e, stackTrace) {
    Logger.error('POST /eggs - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
