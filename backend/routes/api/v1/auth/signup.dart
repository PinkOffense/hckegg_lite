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

    // Validate email
    if (!Validators.isValidEmail(email)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Valid email is required'},
      );
    }

    // Validate password (minimum 8 characters)
    if (!Validators.isValidPassword(password)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Password must be at least 8 characters'},
      );
    }

    // Validate display name if provided
    if (name != null && !Validators.isValidDisplayName(name)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Invalid display name'},
      );
    }

    // Log with masked email for privacy
    Logger.info('POST /auth/signup - Attempting signup for ${AuthUtils.maskEmail(email!)}');

    final client = SupabaseClientManager.client;
    final response = await client.auth.signUp(
      email: email,
      password: password!,
      data: name != null ? {'name': name} : null,
    );

    if (response.user == null) {
      Logger.warning('POST /auth/signup - Signup failed');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Signup failed'},
      );
    }

    Logger.info('POST /auth/signup - User created: ${AuthUtils.maskUserId(response.user!.id)}');

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
    Logger.warning('POST /auth/signup - Auth error');
    // Return generic error to avoid leaking information
    final isEmailTaken = e.message.toLowerCase().contains('already registered') ||
        e.message.toLowerCase().contains('already exists');
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': isEmailTaken ? 'Email already registered' : 'Signup failed'},
    );
  } catch (e, stackTrace) {
    Logger.error('POST /auth/signup - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
