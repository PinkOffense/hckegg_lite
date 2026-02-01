import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/core/core.dart';
import '../../../../lib/features/eggs/data/repositories/egg_repository_impl.dart';
import '../../../../lib/features/eggs/domain/entities/egg_record.dart';
import '../../../../lib/features/eggs/domain/usecases/egg_usecases.dart';

/// Handler for /api/v1/eggs/:id
/// GET - Get egg record by ID
/// PUT - Update egg record
/// DELETE - Delete egg record
Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getEggRecord(context, id),
    HttpMethod.put => _updateEggRecord(context, id),
    HttpMethod.delete => _deleteEggRecord(context, id),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

/// GET /api/v1/eggs/:id
Future<Response> _getEggRecord(RequestContext context, String id) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
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
        // Verify ownership
        if (record.userId != userId) {
          return Response.json(
            statusCode: HttpStatus.forbidden,
            body: {'error': 'Access denied'},
          );
        }
        return Response.json(body: {'data': record.toJson()});
      },
      onFailure: (failure) {
        final statusCode = failure is NotFoundFailure
            ? HttpStatus.notFound
            : HttpStatus.internalServerError;
        return Response.json(
          statusCode: statusCode,
          body: {'error': failure.message},
        );
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

/// PUT /api/v1/eggs/:id
Future<Response> _updateEggRecord(RequestContext context, String id) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    // First get existing record to verify ownership
    final repository = EggRepositoryImpl(SupabaseClientManager.client);
    final getUseCase = GetEggRecordById(repository);
    final existingResult = await getUseCase(GetEggRecordByIdParams(id: id));

    final existingRecord = existingResult.valueOrNull;
    if (existingRecord == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Egg record not found'},
      );
    }

    if (existingRecord.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

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
      onSuccess: (record) => Response.json(body: {'data': record.toJson()}),
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

/// DELETE /api/v1/eggs/:id
Future<Response> _deleteEggRecord(RequestContext context, String id) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    // First verify ownership
    final repository = EggRepositoryImpl(SupabaseClientManager.client);
    final getUseCase = GetEggRecordById(repository);
    final existingResult = await getUseCase(GetEggRecordByIdParams(id: id));

    final existingRecord = existingResult.valueOrNull;
    if (existingRecord == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Egg record not found'},
      );
    }

    if (existingRecord.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    final deleteUseCase = DeleteEggRecord(repository);
    final result = await deleteUseCase(DeleteEggRecordParams(id: id));

    return result.fold(
      onSuccess: (_) => Response(statusCode: HttpStatus.noContent),
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
