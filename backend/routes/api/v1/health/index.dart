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
    final userId = context.request.headers['x-user-id'];
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = VetRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.getVetRecords(userId);

    return result.fold(
      onSuccess: (vetRecords) => Response.json(body: {'data': vetRecords.map((v) => v.toJson()).toList(), 'count': vetRecords.length}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _createVetRecord(RequestContext context) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final body = await context.request.json() as Map<String, dynamic>;
    final vetRecord = VetRecord(
      id: '',
      userId: userId,
      date: body['date'] as String,
      recordType: VetRecordType.fromString(body['record_type'] as String),
      hensAffected: body['hens_affected'] as int,
      description: body['description'] as String,
      vetName: body['vet_name'] as String?,
      cost: (body['cost'] as num).toDouble(),
      notes: body['notes'] as String?,
      createdAt: DateTime.now().toUtc(),
    );

    final repository = VetRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.createVetRecord(vetRecord);

    return result.fold(
      onSuccess: (v) => Response.json(statusCode: HttpStatus.created, body: {'data': v.toJson()}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}
