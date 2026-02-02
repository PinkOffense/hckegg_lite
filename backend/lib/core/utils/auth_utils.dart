import 'package:dart_frog/dart_frog.dart';

import 'logger.dart';
import 'supabase_client.dart';

/// Wrapper class for authenticated user ID
/// Used with dart_frog's provider system to pass userId from middleware to handlers
class AuthenticatedUserId {
  final String value;
  const AuthenticatedUserId(this.value);

  @override
  String toString() => value;
}

/// Authentication utilities for API endpoints
class AuthUtils {
  AuthUtils._();

  /// Get the authenticated user ID from the request context
  /// This reads from the provider set by the auth middleware
  ///
  /// Returns null if user is not authenticated (middleware should have blocked this)
  static String? getUserIdFromContext(RequestContext context) {
    try {
      final authUser = context.read<AuthenticatedUserId>();
      return authUser.value;
    } catch (_) {
      return null;
    }
  }

  /// Extract and validate user ID from JWT token in Authorization header
  ///
  /// Returns the user ID if valid, null otherwise.
  /// Logs warnings for invalid tokens.
  static Future<String?> getUserIdFromRequest(RequestContext context) async {
    final authHeader = context.request.headers['authorization'];

    if (authHeader == null) {
      Logger.warning('Auth: Missing Authorization header');
      return null;
    }

    if (!authHeader.startsWith('Bearer ')) {
      Logger.warning('Auth: Invalid Authorization header format');
      return null;
    }

    final token = authHeader.substring(7);

    if (token.isEmpty) {
      Logger.warning('Auth: Empty token');
      return null;
    }

    try {
      final client = SupabaseClientManager.client;
      final userResponse = await client.auth.getUser(token);

      if (userResponse.user == null) {
        Logger.warning('Auth: Token valid but no user found');
        return null;
      }

      return userResponse.user!.id;
    } catch (e) {
      Logger.warning('Auth: Token validation failed - ${e.runtimeType}');
      return null;
    }
  }

  /// Mask email for logging (privacy)
  /// "user@example.com" -> "u***@e***.com"
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';

    final local = parts[0];
    final domain = parts[1];

    final maskedLocal = local.isNotEmpty
        ? '${local[0]}***'
        : '***';

    final domainParts = domain.split('.');
    final maskedDomain = domainParts.isNotEmpty && domainParts[0].isNotEmpty
        ? '${domainParts[0][0]}***.${domainParts.length > 1 ? domainParts.last : 'com'}'
        : '***';

    return '$maskedLocal@$maskedDomain';
  }

  /// Mask user ID for logging (show only last 4 chars)
  static String maskUserId(String userId) {
    if (userId.length <= 4) return '****';
    return '****${userId.substring(userId.length - 4)}';
  }
}
