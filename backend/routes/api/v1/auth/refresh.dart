import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/core/core.dart';

/// Handler for /api/v1/auth/refresh
/// POST - Refresh access token
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _refresh(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

/// POST /api/v1/auth/refresh
Future<Response> _refresh(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final refreshToken = body['refresh_token'] as String?;

    if (refreshToken == null || refreshToken.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Refresh token is required'},
      );
    }

    Logger.info('POST /auth/refresh - Attempting token refresh');

    final client = SupabaseClientManager.client;
    final response = await client.auth.refreshSession(refreshToken);

    if (response.user == null || response.session == null) {
      Logger.warning('POST /auth/refresh - Refresh failed');
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid refresh token'},
      );
    }

    Logger.info('POST /auth/refresh - Token refreshed for user: ${response.user!.id}');

    return Response.json(
      body: {
        'user': {
          'id': response.user!.id,
          'email': response.user!.email,
        },
        'session': {
          'access_token': response.session!.accessToken,
          'refresh_token': response.session!.refreshToken,
          'expires_at': response.session!.expiresAt,
          'token_type': response.session!.tokenType,
        },
      },
    );
  } on AuthException catch (e) {
    Logger.error('POST /auth/refresh - AuthException', e.message);
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': e.message},
    );
  } catch (e, stackTrace) {
    Logger.error('POST /auth/refresh - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
