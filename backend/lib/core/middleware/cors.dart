// backend/lib/core/middleware/cors.dart
import 'package:dart_frog/dart_frog.dart';

/// CORS configuration
class CorsConfig {
  /// Allowed origins (use ['*'] for all origins - not recommended for production)
  final List<String> allowedOrigins;

  /// Allowed HTTP methods
  final List<String> allowedMethods;

  /// Allowed headers
  final List<String> allowedHeaders;

  /// Headers exposed to the client
  final List<String> exposedHeaders;

  /// Whether to allow credentials (cookies, authorization headers)
  final bool allowCredentials;

  /// Preflight cache duration in seconds
  final int maxAge;

  const CorsConfig({
    this.allowedOrigins = const ['*'],
    this.allowedMethods = const ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    this.allowedHeaders = const [
      'Origin',
      'Content-Type',
      'Authorization',
      'Accept',
      'X-Requested-With',
      'x-user-id',
    ],
    this.exposedHeaders = const [
      'X-RateLimit-Limit',
      'X-RateLimit-Remaining',
      'X-RateLimit-Reset',
    ],
    this.allowCredentials = true,
    this.maxAge = 86400, // 24 hours
  });

  /// Production configuration with specific origins
  static CorsConfig production({required List<String> allowedOrigins}) {
    return CorsConfig(
      allowedOrigins: allowedOrigins,
      allowCredentials: true,
      maxAge: 86400,
    );
  }

  /// Development configuration (more permissive)
  static const development = CorsConfig(
    allowedOrigins: ['*'],
    allowCredentials: false, // Can't use credentials with wildcard
    maxAge: 3600,
  );
}

/// CORS middleware with configurable options
Middleware corsMiddleware([CorsConfig? config]) {
  final effectiveConfig = config ?? _getConfigFromEnvironment();

  return (handler) {
    return (context) async {
      final request = context.request;
      final origin = request.headers['origin'];

      // Build CORS headers
      final corsHeaders = _buildCorsHeaders(effectiveConfig, origin);

      // Handle preflight requests
      if (request.method == HttpMethod.options) {
        return Response(
          statusCode: 204, // No Content
          headers: corsHeaders,
        );
      }

      // Process the request
      final response = await handler(context);

      // Add CORS headers to response
      return response.copyWith(
        headers: {...response.headers, ...corsHeaders},
      );
    };
  };
}

/// Build CORS headers based on configuration and request origin
Map<String, String> _buildCorsHeaders(CorsConfig config, String? origin) {
  final headers = <String, String>{};

  // Handle origin
  if (config.allowedOrigins.contains('*')) {
    headers['Access-Control-Allow-Origin'] = '*';
  } else if (origin != null && config.allowedOrigins.contains(origin)) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Vary'] = 'Origin';
  } else if (origin != null && _matchesWildcardOrigin(origin, config.allowedOrigins)) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Vary'] = 'Origin';
  }

  // Methods
  headers['Access-Control-Allow-Methods'] = config.allowedMethods.join(', ');

  // Headers
  headers['Access-Control-Allow-Headers'] = config.allowedHeaders.join(', ');

  // Exposed headers
  if (config.exposedHeaders.isNotEmpty) {
    headers['Access-Control-Expose-Headers'] = config.exposedHeaders.join(', ');
  }

  // Credentials
  if (config.allowCredentials && !config.allowedOrigins.contains('*')) {
    headers['Access-Control-Allow-Credentials'] = 'true';
  }

  // Max age
  headers['Access-Control-Max-Age'] = config.maxAge.toString();

  return headers;
}

/// Check if origin matches a wildcard pattern (e.g., *.example.com)
bool _matchesWildcardOrigin(String origin, List<String> patterns) {
  for (final pattern in patterns) {
    if (pattern.startsWith('*.')) {
      final domain = pattern.substring(2);
      final uri = Uri.tryParse(origin);
      if (uri != null && uri.host.endsWith(domain)) {
        return true;
      }
    }
  }
  return false;
}

/// Get CORS config from environment
CorsConfig _getConfigFromEnvironment() {
  final env = const String.fromEnvironment('ENV', defaultValue: 'development');

  if (env == 'production') {
    // Get allowed origins from environment
    final originsStr = const String.fromEnvironment(
      'CORS_ALLOWED_ORIGINS',
      defaultValue: '',
    );

    if (originsStr.isEmpty) {
      // Default production origins
      return CorsConfig.production(
        allowedOrigins: [
          'https://hckegg.app',
          'https://www.hckegg.app',
          'https://*.hckegg.app',
          // Add your Flutter web app domains here
        ],
      );
    }

    return CorsConfig.production(
      allowedOrigins: originsStr.split(',').map((s) => s.trim()).toList(),
    );
  }

  return CorsConfig.development;
}
