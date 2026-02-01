import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/core/core.dart';

/// Handler for /api/v1/auth/profile
/// GET - Get current user's profile
/// PUT - Update current user's profile
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getProfile(context),
    HttpMethod.put => _updateProfile(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

/// GET /api/v1/auth/profile
Future<Response> _getProfile(RequestContext context) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    Logger.info('GET /auth/profile - Fetching profile for user $userId');

    final client = SupabaseClientManager.client;
    final response = await client
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Return empty profile if not found
      return Response.json(
        body: {
          'data': null,
          'message': 'Profile not found',
        },
      );
    }

    Logger.info('GET /auth/profile - Profile found for user $userId');

    return Response.json(
      body: {'data': response},
    );
  } catch (e, stackTrace) {
    Logger.error('GET /auth/profile - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}

/// PUT /api/v1/auth/profile
Future<Response> _updateProfile(RequestContext context) async {
  try {
    final userId = context.request.headers['x-user-id'];
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

    // Only allow these fields to be updated
    final allowedFields = ['display_name', 'bio', 'avatar_url'];
    final updateData = <String, dynamic>{
      'user_id': userId,
    };

    for (final field in allowedFields) {
      if (body.containsKey(field)) {
        updateData[field] = body[field];
      }
    }

    Logger.info('PUT /auth/profile - Updating profile for user $userId');

    final client = SupabaseClientManager.client;
    final response = await client
        .from('user_profiles')
        .upsert(updateData, onConflict: 'user_id')
        .select()
        .single();

    Logger.info('PUT /auth/profile - Profile updated for user $userId');

    return Response.json(
      body: {'data': response},
    );
  } catch (e, stackTrace) {
    Logger.error('PUT /auth/profile - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
