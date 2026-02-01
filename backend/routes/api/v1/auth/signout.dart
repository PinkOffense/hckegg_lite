import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/core/core.dart';

/// Handler for /api/v1/auth/signout
/// POST - Sign out a user
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _signout(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

/// POST /api/v1/auth/signout
Future<Response> _signout(RequestContext context) async {
  try {
    final authHeader = context.request.headers['authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Authorization token required'},
      );
    }

    final token = authHeader.substring(7);
    Logger.info('POST /auth/signout - Attempting signout');

    // Verify the token and get user
    final client = SupabaseClientManager.client;

    try {
      final user = await client.auth.getUser(token);
      if (user.user == null) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'Invalid token'},
        );
      }

      // Sign out the user (invalidate tokens)
      await client.auth.admin.signOut(token);

      Logger.info('POST /auth/signout - User signed out: ${user.user!.id}');

      return Response.json(
        body: {'message': 'Signed out successfully'},
      );
    } on AuthException catch (e) {
      Logger.warning('POST /auth/signout - Token validation failed: ${e.message}');
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid or expired token'},
      );
    }
  } catch (e, stackTrace) {
    Logger.error('POST /auth/signout - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
