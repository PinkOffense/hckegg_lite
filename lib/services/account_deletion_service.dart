// lib/services/account_deletion_service.dart

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of account deletion operation
class AccountDeletionResult {
  final bool success;
  final String? errorMessage;
  final AccountDeletionError? errorType;

  const AccountDeletionResult._({
    required this.success,
    this.errorMessage,
    this.errorType,
  });

  factory AccountDeletionResult.success() => const AccountDeletionResult._(success: true);

  factory AccountDeletionResult.failure(String message, AccountDeletionError type) =>
      AccountDeletionResult._(success: false, errorMessage: message, errorType: type);
}

/// Types of errors that can occur during account deletion
enum AccountDeletionError {
  notAuthenticated,
  sessionExpired,
  databaseError,
  authError,
  unknown,
}

/// Service responsible for account deletion operations
///
/// Follows Single Responsibility Principle - only handles account deletion
class AccountDeletionService {
  final SupabaseClient _client;

  AccountDeletionService(this._client);

  /// Factory constructor using default Supabase instance
  factory AccountDeletionService.instance() =>
      AccountDeletionService(Supabase.instance.client);

  /// List of tables to delete user data from (order matters for foreign keys)
  static const List<_TableDeleteConfig> _tablesToDelete = [
    _TableDeleteConfig('feed_movements', 'user_id'),
    _TableDeleteConfig('feed_stocks', 'user_id'),
    _TableDeleteConfig('egg_reservations', 'user_id'),
    _TableDeleteConfig('egg_sales', 'user_id'),
    _TableDeleteConfig('expenses', 'user_id'),
    _TableDeleteConfig('vet_records', 'user_id'),
    _TableDeleteConfig('daily_egg_records', 'user_id'),
    _TableDeleteConfig('user_profiles', 'user_id'),
  ];

  /// Check if current user is authenticated via Google OAuth
  bool get isGoogleUser {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    return user.appMetadata['provider'] == 'google' ||
        (user.identities?.any((i) => i.provider == 'google') ?? false);
  }

  /// Delete user account and all associated data
  ///
  /// This method:
  /// 1. Validates user authentication
  /// 2. Deletes all user data from app tables
  /// 3. Attempts to delete auth user (may fail for OAuth)
  /// 4. Signs out from Google if applicable
  /// 5. Signs out from Supabase
  Future<AccountDeletionResult> deleteAccount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      final user = _client.auth.currentUser;

      if (userId == null || user == null) {
        return AccountDeletionResult.failure(
          'User not authenticated',
          AccountDeletionError.notAuthenticated,
        );
      }

      debugPrint('AccountDeletionService: Starting deletion for user $userId');

      // Step 1: Delete all user data from tables
      await _deleteUserData(userId);
      debugPrint('AccountDeletionService: User data deleted successfully');

      // Step 2: Attempt to delete auth user (may fail for OAuth users)
      await _deleteAuthUser();

      // Step 3: Sign out from Google if applicable
      if (isGoogleUser) {
        await _signOutFromGoogle();
      }

      // Step 4: Sign out from Supabase
      await _signOutFromSupabase();
      debugPrint('AccountDeletionService: Sign out completed');

      return AccountDeletionResult.success();
    } on AuthException catch (e) {
      debugPrint('AccountDeletionService: Auth error - ${e.message}');

      if (e.message.contains('JWT') || e.message.contains('expired')) {
        return AccountDeletionResult.failure(
          e.message,
          AccountDeletionError.sessionExpired,
        );
      }
      return AccountDeletionResult.failure(
        e.message,
        AccountDeletionError.authError,
      );
    } on PostgrestException catch (e) {
      debugPrint('AccountDeletionService: Database error - ${e.message}');
      return AccountDeletionResult.failure(
        e.message,
        AccountDeletionError.databaseError,
      );
    } catch (e) {
      debugPrint('AccountDeletionService: Unknown error - $e');
      return AccountDeletionResult.failure(
        e.toString(),
        AccountDeletionError.unknown,
      );
    }
  }

  /// Delete all user data from application tables
  Future<void> _deleteUserData(String userId) async {
    for (final config in _tablesToDelete) {
      await _client.from(config.tableName).delete().eq(config.userIdColumn, userId);
      debugPrint('AccountDeletionService: Deleted from ${config.tableName}');
    }
  }

  /// Attempt to delete user from Supabase Auth
  ///
  /// This may fail for OAuth users, which is acceptable since
  /// all user data has already been deleted.
  Future<void> _deleteAuthUser() async {
    try {
      await _client.rpc('delete_user_account');
      debugPrint('AccountDeletionService: Auth user deleted via RPC');
    } catch (e) {
      debugPrint('AccountDeletionService: RPC delete failed (expected for OAuth): $e');
      // Continue anyway - data is already deleted
    }
  }

  /// Sign out from Google (mobile/desktop only)
  Future<void> _signOutFromGoogle() async {
    if (kIsWeb) return;

    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
        debugPrint('AccountDeletionService: Google account disconnected');
      }
    } catch (e) {
      debugPrint('AccountDeletionService: Google disconnect failed: $e');
      // Continue anyway
    }
  }

  /// Sign out from Supabase
  Future<void> _signOutFromSupabase() async {
    await _client.auth.signOut();
  }
}

/// Configuration for table deletion
class _TableDeleteConfig {
  final String tableName;
  final String userIdColumn;

  const _TableDeleteConfig(this.tableName, this.userIdColumn);
}
