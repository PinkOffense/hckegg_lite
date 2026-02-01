import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Serves the OpenAPI specification
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final file = File('docs/openapi.yaml');
    if (!file.existsSync()) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'OpenAPI specification not found'},
      );
    }

    final content = await file.readAsString();
    return Response(
      body: content,
      headers: {
        'Content-Type': 'application/x-yaml',
        'Access-Control-Allow-Origin': '*',
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to read OpenAPI specification'},
    );
  }
}
