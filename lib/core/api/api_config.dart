/// API Configuration
/// The frontend always uses the backend API for all data operations
class ApiConfig {
  /// Always use the backend API (no direct Supabase access for data)
  static const bool useApi = true;

  /// API Base URL
  /// Can be overridden via --dart-define=API_URL=https://custom-url.com
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://hckegg-api.onrender.com',
  );

  /// Whether the API is configured and should be used
  static bool get isApiEnabled => useApi && apiUrl.isNotEmpty;
}
