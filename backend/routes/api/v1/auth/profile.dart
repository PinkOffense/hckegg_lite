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
    final userId = await AuthUtils.getUserIdFromRequest(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    Logger.info('GET /auth/profile - Fetching profile for user ${AuthUtils.maskUserId(userId)}');

    final client = SupabaseClientManager.client;
    final response = await client
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return Response.json(
        body: {
          'data': null,
          'message': 'Profile not found',
        },
      );
    }

    Logger.info('GET /auth/profile - Profile found');

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
    final userId = await AuthUtils.getUserIdFromRequest(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

    // Validate and sanitize input
    final errors = <String>[];
    final updateData = <String, dynamic>{
      'user_id': userId,
    };

    // Validate display_name
    if (body.containsKey('display_name')) {
      final displayName = body['display_name'] as String?;
      if (displayName != null && !Validators.isValidDisplayName(displayName)) {
        errors.add('Invalid display name (max 100 chars, letters/numbers/spaces only)');
      } else {
        updateData['display_name'] = displayName;
      }
    }

    // Validate bio
    if (body.containsKey('bio')) {
      final bio = body['bio'] as String?;
      if (bio != null && !Validators.isValidBio(bio)) {
        errors.add('Bio cannot exceed 500 characters');
      } else {
        updateData['bio'] = bio;
      }
    }

    // Validate avatar_url
    if (body.containsKey('avatar_url')) {
      final avatarUrl = body['avatar_url'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty && !Validators.isValidUrl(avatarUrl)) {
        errors.add('Invalid avatar URL');
      } else {
        updateData['avatar_url'] = avatarUrl;
      }
    }

    // Return validation errors
    if (errors.isNotEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': errors.join('; ')},
      );
    }

    Logger.info('PUT /auth/profile - Updating profile for user ${AuthUtils.maskUserId(userId)}');

    final client = SupabaseClientManager.client;
    final response = await client
        .from('user_profiles')
        .upsert(updateData, onConflict: 'user_id')
        .select()
        .single();

    Logger.info('PUT /auth/profile - Profile updated');

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
