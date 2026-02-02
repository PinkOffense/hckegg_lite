import 'package:test/test.dart';

import '../../../lib/core/middleware/cors.dart';

void main() {
  group('CorsConfig', () {
    test('default configuration allows all origins', () {
      const config = CorsConfig();
      expect(config.allowedOrigins, contains('*'));
      expect(config.allowedMethods, contains('GET'));
      expect(config.allowedMethods, contains('POST'));
      expect(config.allowedMethods, contains('PUT'));
      expect(config.allowedMethods, contains('DELETE'));
      expect(config.allowedHeaders, contains('Authorization'));
      expect(config.allowedHeaders, contains('Content-Type'));
    });

    test('production configuration requires specific origins', () {
      final config = CorsConfig.production(
        allowedOrigins: ['https://example.com', 'https://app.example.com'],
      );

      expect(config.allowedOrigins, contains('https://example.com'));
      expect(config.allowedOrigins, contains('https://app.example.com'));
      expect(config.allowedOrigins, isNot(contains('*')));
      expect(config.allowCredentials, true);
    });

    test('development configuration is permissive', () {
      const config = CorsConfig.development;
      expect(config.allowedOrigins, contains('*'));
      expect(config.allowCredentials, false); // Can't use credentials with wildcard
    });

    test('exposed headers include rate limit headers', () {
      const config = CorsConfig();
      expect(config.exposedHeaders, contains('X-RateLimit-Limit'));
      expect(config.exposedHeaders, contains('X-RateLimit-Remaining'));
      expect(config.exposedHeaders, contains('X-RateLimit-Reset'));
    });

    test('max age is set correctly', () {
      const config = CorsConfig();
      expect(config.maxAge, 86400); // 24 hours

      const devConfig = CorsConfig.development;
      expect(devConfig.maxAge, 3600); // 1 hour
    });
  });
}
