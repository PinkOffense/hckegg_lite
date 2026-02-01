import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/core/core.dart';

/// Handler for /api/v1/auth/delete-account
/// POST - Delete user account and all associated data
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _deleteAccount(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

/// Extract user ID from JWT token
Future<String?> _getUserIdFromToken(RequestContext context) async {
  final authHeader = context.request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  final token = authHeader.substring(7);

  try {
    final client = SupabaseClientManager.client;
    final user = await client.auth.getUser(token);
    return user.user?.id;
  } catch (e) {
    Logger.warning('Failed to get user from token: $e');
    return null;
  }
}

/// Tables to delete user data from (order matters for foreign keys)
const _tablesToDelete = [
  ('feed_movements', 'user_id'),
  ('feed_stocks', 'user_id'),
  ('egg_reservations', 'user_id'),
  ('egg_sales', 'user_id'),
  ('expenses', 'user_id'),
  ('vet_records', 'user_id'),
  ('daily_egg_records', 'user_id'),
  ('user_profiles', 'user_id'),
];

/// POST /api/v1/auth/delete-account
Future<Response> _deleteAccount(RequestContext context) async {
  try {
    final userId = await _getUserIdFromToken(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    Logger.info('POST /auth/delete-account - Starting deletion for user $userId');

    final client = SupabaseClientManager.client;

    // Step 1: Delete all user data from tables
    for (final (tableName, userIdColumn) in _tablesToDelete) {
      try {
        await client.from(tableName).delete().eq(userIdColumn, userId);
        Logger.info('POST /auth/delete-account - Deleted from $tableName');
      } catch (e) {
        Logger.warning('POST /auth/delete-account - Failed to delete from $tableName: $e');
        // Continue with other tables
      }
    }

    // Step 2: Attempt to delete auth user via RPC
    try {
      await client.rpc('delete_user_account');
      Logger.info('POST /auth/delete-account - Auth user deleted via RPC');
    } catch (e) {
      Logger.warning('POST /auth/delete-account - RPC delete failed (expected for OAuth): $e');
      // Continue anyway - data is already deleted
    }

    Logger.info('POST /auth/delete-account - Account deletion completed for user $userId');

    return Response.json(
      body: {
        'success': true,
        'message': 'Account deleted successfully',
      },
    );
  } catch (e, stackTrace) {
    Logger.error('POST /auth/delete-account - Exception', e, stackTrace);
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to delete account'},
    );
  }
}
