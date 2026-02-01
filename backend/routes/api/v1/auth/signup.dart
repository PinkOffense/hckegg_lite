import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/core/core.dart';

/// Handler for /api/v1/auth/signup
/// POST - Register a new user
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _signup(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

/// POST /api/v1/auth/signup
Future<Response> _signup(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;

    final email = body['email'] as String?;
    final password = body['password'] as String?;
    final name = body['name'] as String?;

    // Validate input
    if (email == null || email.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Email is required'},
      );
    }
    if (password == null || password.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Password is required'},
      );
    }
    if (password.length < 6) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Password must be at least 6 characters'},
      );
    }

    Logger.info('POST /auth/signup - Attempting signup for $email');

    final client = SupabaseClientManager.client;
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );

    if (response.user == null) {
      Logger.warning('POST /auth/signup - Signup failed for $email');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Signup failed'},
      );
    }

    Logger.info('POST /auth/signup - User created: ${response.user!.id}');

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'user': {
          'id': response.user!.id,
          'email': response.user!.email,
          'created_at': response.user!.createdAt,
        },
        'session': response.session != null
            ? {
                'access_token': response.session!.accessToken,
                'refresh_token': response.session!.refreshToken,
                'expires_at': response.session!.expiresAt,
              }
            : null,
        'message': response.session == null
            ? 'Please check your email to confirm your account'
            : 'Account created successfully',
      },
    );
  } on AuthException catch (e) {
    Logger.error('POST /auth/signup - AuthException', e.message);
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  } catch (e, stackTrace) {
    Logger.error('POST /auth/signup - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
