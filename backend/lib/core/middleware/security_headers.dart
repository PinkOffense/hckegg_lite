import 'package:dart_frog/dart_frog.dart';

/// Security headers middleware configuration
class SecurityHeadersConfig {
  const SecurityHeadersConfig({
    this.contentTypeOptions = 'nosniff',
    this.frameOptions = 'DENY',
    this.xssProtection = '1; mode=block',
    this.strictTransportSecurity = 'max-age=31536000; includeSubDomains',
    this.referrerPolicy = 'strict-origin-when-cross-origin',
    this.contentSecurityPolicy,
    this.permissionsPolicy,
  });

  /// X-Content-Type-Options header value
  final String contentTypeOptions;

  /// X-Frame-Options header value
  final String frameOptions;

  /// X-XSS-Protection header value
  final String xssProtection;

  /// Strict-Transport-Security header value
  final String strictTransportSecurity;

  /// Referrer-Policy header value
  final String referrerPolicy;

  /// Content-Security-Policy header value (optional)
  final String? contentSecurityPolicy;

  /// Permissions-Policy header value (optional)
  final String? permissionsPolicy;

  /// Default configuration for production
  static SecurityHeadersConfig production() {
    return const SecurityHeadersConfig(
      contentSecurityPolicy: "default-src 'self'; "
          "script-src 'self'; "
          "style-src 'self' 'unsafe-inline'; "
          "img-src 'self' data: https:; "
          "font-src 'self'; "
          "connect-src 'self' https://*.supabase.co; "
          "frame-ancestors 'none'",
      permissionsPolicy: 'geolocation=(), microphone=(), camera=()',
    );
  }

  /// Relaxed configuration for development
  static SecurityHeadersConfig development() {
    return const SecurityHeadersConfig(
      strictTransportSecurity: '',
      contentSecurityPolicy: null,
    );
  }
}

/// Security headers middleware
///
/// Adds security headers to all responses to protect against common attacks:
/// - X-Content-Type-Options: Prevents MIME type sniffing
/// - X-Frame-Options: Prevents clickjacking
/// - X-XSS-Protection: Enables browser XSS filtering
/// - Strict-Transport-Security: Enforces HTTPS
/// - Referrer-Policy: Controls referrer information
/// - Content-Security-Policy: Restricts resource loading
/// - Permissions-Policy: Restricts browser features
Middleware securityHeadersMiddleware([SecurityHeadersConfig? config]) {
  final effectiveConfig = config ?? _getConfigFromEnvironment();

  return (handler) {
    return (context) async {
      final response = await handler(context);

      final headers = <String, String>{
        ...response.headers,
      };

      // Always add these headers
      headers['X-Content-Type-Options'] = effectiveConfig.contentTypeOptions;
      headers['X-Frame-Options'] = effectiveConfig.frameOptions;
      headers['X-XSS-Protection'] = effectiveConfig.xssProtection;
      headers['Referrer-Policy'] = effectiveConfig.referrerPolicy;

      // Add HSTS only if configured (skip in development)
      if (effectiveConfig.strictTransportSecurity.isNotEmpty) {
        headers['Strict-Transport-Security'] =
            effectiveConfig.strictTransportSecurity;
      }

      // Add CSP if configured
      if (effectiveConfig.contentSecurityPolicy != null) {
        headers['Content-Security-Policy'] =
            effectiveConfig.contentSecurityPolicy!;
      }

      // Add Permissions-Policy if configured
      if (effectiveConfig.permissionsPolicy != null) {
        headers['Permissions-Policy'] = effectiveConfig.permissionsPolicy!;
      }

      return response.copyWith(headers: headers);
    };
  };
}

/// Gets security headers config based on environment
SecurityHeadersConfig _getConfigFromEnvironment() {
  const env = String.fromEnvironment('ENV', defaultValue: 'development');

  if (env == 'production') {
    return SecurityHeadersConfig.production();
  }

  return SecurityHeadersConfig.development();
}
