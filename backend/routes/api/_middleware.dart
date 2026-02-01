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
        Logger.auth('Token validation', success: false);
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {
            'error': 'Missing or invalid Authorization header',
            'hint': 'Use format: Authorization: Bearer <token>',
          },
        );
      }

      final token = authHeader.substring(7); // Remove 'Bearer ' prefix

      try {
        // Verify token with Supabase
        final client = SupabaseClientManager.client;
        final response = await client.auth.getUser(token);

        if (response.user == null) {
          Logger.auth('Token validation', success: false);
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: {'error': 'Invalid or expired token'},
          );
        }

        final userId = response.user!.id;
        Logger.auth('Token validation', userId: userId, success: true);

        // Add user ID to request headers for downstream handlers
        final updatedRequest = context.request.copyWith(
          headers: {
            ...context.request.headers,
            'x-user-id': userId,
          },
        );

        // Create new context with updated request
        final updatedContext = context.provide<String>(
          () => userId,
        );

        return handler(updatedContext);
      } on AuthException catch (e) {
        Logger.warning('Auth exception: ${e.message}');
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'Authentication failed: ${e.message}'},
        );
      } catch (e, stackTrace) {
        Logger.error('Auth error', e, stackTrace);
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'Authentication failed'},
        );
      }
    };
  };
}

/// Custom auth exception for typed error handling
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
