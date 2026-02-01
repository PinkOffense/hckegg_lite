/// API Configuration
/// Controls whether to use the custom API backend or direct Supabase
class ApiConfig {
  /// Whether to use the custom API backend
  /// Set via --dart-define=USE_API=true
  static const bool useApi = bool.fromEnvironment('USE_API', defaultValue: false);

  /// API Base URL
  /// Set via --dart-define=API_URL=http://localhost:8080
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Whether the API is configured and should be used
  static bool get isApiEnabled => useApi && apiUrl.isNotEmpty;
}

/// Data source mode
enum DataSourceMode {
  /// Use Supabase directly (default)
  supabase,

  /// Use custom API backend
  api,
}
