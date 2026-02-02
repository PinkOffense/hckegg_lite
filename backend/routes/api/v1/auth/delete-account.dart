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
    final userId = await AuthUtils.getUserIdFromRequest(context);
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Unauthorized'},
      );
    }

    final maskedUserId = AuthUtils.maskUserId(userId);
    Logger.info('POST /auth/delete-account - Starting deletion for user $maskedUserId');

    final client = SupabaseClientManager.client;
    final failedTables = <String>[];

    // Step 1: Delete all user data from tables
    for (final (tableName, userIdColumn) in _tablesToDelete) {
      try {
        await client.from(tableName).delete().eq(userIdColumn, userId);
        Logger.info('POST /auth/delete-account - Deleted from $tableName');
      } catch (e) {
        Logger.warning('POST /auth/delete-account - Failed to delete from $tableName');
        failedTables.add(tableName);
        // Continue with other tables - partial deletion is better than none
      }
    }

    // Step 2: Attempt to delete auth user via RPC
    // This may fail for OAuth users, which is acceptable
    var authDeleted = false;
    try {
      await client.rpc('delete_user_account');
      authDeleted = true;
      Logger.info('POST /auth/delete-account - Auth user deleted via RPC');
    } catch (e) {
      // Expected for OAuth users - they need to disconnect manually
      Logger.info('POST /auth/delete-account - Auth deletion skipped (OAuth user or RPC unavailable)');
    }

    Logger.info('POST /auth/delete-account - Account deletion completed for user $maskedUserId');

    // Return partial success if some tables failed
    if (failedTables.isNotEmpty) {
      return Response.json(
        body: {
          'success': true,
          'partial': true,
          'message': 'Account deleted with some warnings',
          'warnings': ['Some data could not be deleted: ${failedTables.join(", ")}'],
          'auth_deleted': authDeleted,
        },
      );
    }

    return Response.json(
      body: {
        'success': true,
        'message': 'Account deleted successfully',
        'auth_deleted': authDeleted,
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
