import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/core/core.dart';

/// Handler for /api/v1/auth/signin
/// POST - Sign in a user
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _signin(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

/// POST /api/v1/auth/signin
Future<Response> _signin(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;

    final email = body['email'] as String?;
    final password = body['password'] as String?;

    // Validate email format
    if (!Validators.isValidEmail(email)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Valid email is required'},
      );
    }

    // Validate password not empty
    if (password == null || password.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Password is required'},
      );
    }

    // Log with masked email for privacy
    Logger.info('POST /auth/signin - Attempting signin for ${AuthUtils.maskEmail(email!)}');

    final client = SupabaseClientManager.client;
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null || response.session == null) {
      Logger.warning('POST /auth/signin - Signin failed');
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid credentials'},
      );
    }

    Logger.info('POST /auth/signin - User signed in: ${AuthUtils.maskUserId(response.user!.id)}');

    return Response.json(
      body: {
        'user': {
          'id': response.user!.id,
          'email': response.user!.email,
          'created_at': response.user!.createdAt,
          'user_metadata': response.user!.userMetadata,
        },
        'session': {
          'access_token': response.session!.accessToken,
          'refresh_token': response.session!.refreshToken,
          'expires_at': response.session!.expiresAt,
          'token_type': response.session!.tokenType,
        },
      },
    );
  } on AuthException catch (_) {
    // Don't log email or specific error - security best practice
    Logger.warning('POST /auth/signin - Authentication failed');
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Invalid credentials'},
    );
  } catch (e, stackTrace) {
    Logger.error('POST /auth/signin - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
