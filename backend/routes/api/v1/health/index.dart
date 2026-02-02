import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/health/data/repositories/vet_repository_impl.dart';
import '../../../../lib/features/health/domain/entities/vet_record.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getVetRecords(context),
    HttpMethod.post => _createVetRecord(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getVetRecords(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final repository = VetRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.getVetRecords(userId);

    return result.fold(
      onSuccess: (vetRecords) => Response.json(
        body: {
          'data': vetRecords.map((v) => v.toJson()).toList(),
          'count': vetRecords.length,
        },
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

Future<Response> _createVetRecord(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

    // Validate required fields
    final validation = VetRecordValidator.validate(body);
    if (!validation.isValid) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Validation failed', 'details': validation.errors},
      );
    }

    final now = DateTime.now().toUtc();
    final vetRecord = VetRecord(
      id: '',
      userId: userId,
      date: body['date'] as String,
      type: VetRecordType.fromString(body['type'] as String),
      hensAffected: (body['hens_affected'] as int?) ?? 1,
      description: body['description'] as String,
      medication: body['medication'] as String?,
      cost: body['cost'] != null ? (body['cost'] as num).toDouble() : null,
      nextActionDate: body['next_action_date'] as String?,
      notes: body['notes'] as String?,
      severity: VetRecordSeverity.fromString(
        (body['severity'] as String?) ?? 'low',
      ),
      createdAt: now,
      updatedAt: now,
    );

    final repository = VetRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.createVetRecord(vetRecord);

    return result.fold(
      onSuccess: (v) => Response.json(
        statusCode: HttpStatus.created,
        body: {'data': v.toJson()},
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
