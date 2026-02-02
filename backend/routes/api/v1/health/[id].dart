import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/health/data/repositories/vet_repository_impl.dart';
import '../../../../lib/features/health/domain/entities/vet_record.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getVetRecord(context, id),
    HttpMethod.put => _updateVetRecord(context, id),
    HttpMethod.delete => _deleteVetRecord(context, id),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getVetRecord(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = VetRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.getVetRecordById(id);

    return result.fold(
      onSuccess: (vetRecord) => vetRecord.userId != userId
          ? Response.json(
              statusCode: HttpStatus.forbidden,
              body: {'error': 'Access denied'},
            )
          : Response.json(body: {'data': vetRecord.toJson()}),
      onFailure: (f) => Response.json(
        statusCode:
            f is NotFoundFailure ? HttpStatus.notFound : HttpStatus.internalServerError,
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

Future<Response> _updateVetRecord(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = VetRepositoryImpl(SupabaseClientManager.client);
    final existing = await repository.getVetRecordById(id);
    final existingVetRecord = existing.valueOrNull;
    if (existingVetRecord == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Not found'},
      );
    }
    if (existingVetRecord.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

    // Validate update data
    final validation = VetRecordValidator.validate(body, isUpdate: true);
    if (!validation.isValid) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Validation failed', 'details': validation.errors},
      );
    }

    final updated = VetRecord(
      id: id,
      userId: existingVetRecord.userId,
      date: (body['date'] as String?) ?? existingVetRecord.date,
      type: body['type'] != null
          ? VetRecordType.fromString(body['type'] as String)
          : existingVetRecord.type,
      hensAffected:
          (body['hens_affected'] as int?) ?? existingVetRecord.hensAffected,
      description:
          (body['description'] as String?) ?? existingVetRecord.description,
      medication: body.containsKey('medication')
          ? body['medication'] as String?
          : existingVetRecord.medication,
      cost: body.containsKey('cost')
          ? (body['cost'] as num?)?.toDouble()
          : existingVetRecord.cost,
      nextActionDate: body.containsKey('next_action_date')
          ? body['next_action_date'] as String?
          : existingVetRecord.nextActionDate,
      notes: body.containsKey('notes')
          ? body['notes'] as String?
          : existingVetRecord.notes,
      severity: body['severity'] != null
          ? VetRecordSeverity.fromString(body['severity'] as String)
          : existingVetRecord.severity,
      createdAt: existingVetRecord.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await repository.updateVetRecord(updated);
    return result.fold(
      onSuccess: (v) => Response.json(body: {'data': v.toJson()}),
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

Future<Response> _deleteVetRecord(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = VetRepositoryImpl(SupabaseClientManager.client);
    final existing = await repository.getVetRecordById(id);
    final existingVetRecord = existing.valueOrNull;
    if (existingVetRecord == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Not found'},
      );
    }
    if (existingVetRecord.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    final result = await repository.deleteVetRecord(id);
    return result.fold(
      onSuccess: (_) => Response(statusCode: HttpStatus.noContent),
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
