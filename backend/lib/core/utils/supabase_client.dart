import 'package:supabase/supabase.dart';

/// Singleton Supabase client for the backend
class SupabaseClientManager {
  SupabaseClientManager._();

  static SupabaseClient? _client;

  /// Initialize the Supabase client
  static void initialize({
    required String url,
    required String anonKey,
    String? serviceRoleKey,
  }) {
    _client = SupabaseClient(
      url,
      serviceRoleKey ?? anonKey,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        persistSession: false,
      ),
    );
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'SupabaseClient not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  /// Check if client is initialized
  static bool get isInitialized => _client != null;
}
