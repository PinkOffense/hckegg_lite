// lib/services/account_deletion_service.dart

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../core/errors/failures.dart';

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
/// Uses backend API to delete user data, then handles client-side cleanup
class AccountDeletionService {
  final ApiClient _apiClient;
  final SupabaseClient _supabaseClient;

  AccountDeletionService({
    ApiClient? apiClient,
    SupabaseClient? supabaseClient,
  })  : _apiClient = apiClient ?? ApiClient(baseUrl: ApiConfig.apiUrl),
        _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Factory constructor using default instances
  factory AccountDeletionService.instance() => AccountDeletionService();

  /// Check if current user is authenticated via Google OAuth
  bool get isGoogleUser {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return false;
    return user.appMetadata['provider'] == 'google' ||
        (user.identities?.any((i) => i.provider == 'google') ?? false);
  }

  /// Delete user account and all associated data
  ///
  /// This method:
  /// 1. Validates user authentication
  /// 2. Calls backend API to delete all user data
  /// 3. Signs out from Google if applicable
  /// 4. Signs out from Supabase
  Future<AccountDeletionResult> deleteAccount() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;

      if (userId == null) {
        return AccountDeletionResult.failure(
          'User not authenticated',
          AccountDeletionError.notAuthenticated,
        );
      }

      debugPrint('AccountDeletionService: Starting deletion for user $userId');

      // Step 1: Call backend API to delete all user data
      try {
        await _apiClient.post<Map<String, dynamic>>(
          '/api/v1/auth/delete-account',
        );
        debugPrint('AccountDeletionService: User data deleted via API');
      } on Failure catch (e) {
        if (e is AuthFailure) {
          return AccountDeletionResult.failure(
            e.message,
            AccountDeletionError.sessionExpired,
          );
        }
        return AccountDeletionResult.failure(
          e.message,
          AccountDeletionError.databaseError,
        );
      }

      // Step 2: Sign out from Google if applicable
      if (isGoogleUser) {
        await _signOutFromGoogle();
      }

      // Step 3: Sign out from Supabase
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
    } catch (e) {
      debugPrint('AccountDeletionService: Unknown error - $e');
      return AccountDeletionResult.failure(
        e.toString(),
        AccountDeletionError.unknown,
      );
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
    await _supabaseClient.auth.signOut();
  }
}
