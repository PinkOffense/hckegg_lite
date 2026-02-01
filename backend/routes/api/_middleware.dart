import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/core/core.dart';

/// Middleware for /api routes - requires authentication
Handler middleware(Handler handler) {
  return handler.use(authMiddleware());
}

/// Authentication middleware
/// Validates JWT token from Authorization header
Middleware authMiddleware() {
  return (handler) {
    return (context) async {
      final authHeader = context.request.headers['authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'Missing or invalid Authorization header'},
        );
      }

      final token = authHeader.substring(7); // Remove 'Bearer ' prefix

      try {
        // Verify token with Supabase
        final client = SupabaseClientManager.client;
        final response = await client.auth.getUser(token);

        if (response.user == null) {
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: {'error': 'Invalid token'},
          );
        }

        // Add user ID to request headers for downstream handlers
        final updatedRequest = context.request.copyWith(
          headers: {
            ...context.request.headers,
            'x-user-id': response.user!.id,
          },
        );

        // Create new context with updated request
        final updatedContext = context.provide<String>(
          () => response.user!.id,
        );

        return handler(updatedContext);
      } catch (e) {
        print('Auth error: $e');
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'Authentication failed'},
        );
      }
    };
  };
}
