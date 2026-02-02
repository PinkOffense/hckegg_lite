import 'package:test/test.dart';

import '../../../lib/core/middleware/rate_limiter.dart';

void main() {
  group('RateLimitConfig', () {
    test('default configuration has sensible defaults', () {
      const config = RateLimitConfig();
      expect(config.maxRequests, 100);
      expect(config.windowDuration, const Duration(minutes: 1));
      expect(config.exemptPaths, contains('/health'));
      expect(config.exemptPaths, contains('/docs'));
    });

    test('production configuration has stricter limits for auth', () {
      const config = RateLimitConfig.production;
      expect(config.maxRequests, 100);
      expect(config.authenticatedMaxRequests, 200);
      expect(config.pathOverrides, contains('/api/v1/auth/signin'));
      expect(config.pathOverrides['/api/v1/auth/signin']!.maxRequests, 5);
      expect(config.pathOverrides['/api/v1/auth/signup']!.maxRequests, 3);
    });

    test('development configuration is more permissive', () {
      const config = RateLimitConfig.development;
      expect(config.maxRequests, 1000);
    });
  });

  group('RateLimiterStore', () {
    late RateLimiterStore store;

    setUp(() {
      store = RateLimiterStore();
    });

    tearDown(() {
      store.dispose();
    });

    test('allows requests within limit', () {
      const config = RateLimitConfig(maxRequests: 5);

      for (var i = 0; i < 5; i++) {
        final remaining = store.checkAndIncrement('test-client', config);
        expect(remaining, greaterThanOrEqualTo(0));
      }
    });

    test('blocks requests over limit', () {
      const config = RateLimitConfig(maxRequests: 3);

      // Use up the limit
      for (var i = 0; i < 3; i++) {
        store.checkAndIncrement('test-client', config);
      }

      // Next request should be blocked
      final remaining = store.checkAndIncrement('test-client', config);
      expect(remaining, -1);
    });

    test('tracks different clients separately', () {
      const config = RateLimitConfig(maxRequests: 2);

      // Client A uses 2 requests
      store.checkAndIncrement('client-a', config);
      store.checkAndIncrement('client-a', config);

      // Client A should be blocked
      expect(store.checkAndIncrement('client-a', config), -1);

      // Client B should still have requests
      expect(store.checkAndIncrement('client-b', config), greaterThanOrEqualTo(0));
    });

    test('returns correct remaining count', () {
      const config = RateLimitConfig(maxRequests: 5);

      expect(store.checkAndIncrement('test', config), 4);
      expect(store.checkAndIncrement('test', config), 3);
      expect(store.checkAndIncrement('test', config), 2);
      expect(store.checkAndIncrement('test', config), 1);
      expect(store.checkAndIncrement('test', config), 0);
      expect(store.checkAndIncrement('test', config), -1);
    });

    test('getResetTime returns correct duration', () {
      const config = RateLimitConfig(
        maxRequests: 1,
        windowDuration: Duration(seconds: 60),
      );

      store.checkAndIncrement('test', config);

      final resetTime = store.getResetTime('test', config.windowDuration);
      expect(resetTime.inSeconds, lessThanOrEqualTo(60));
      expect(resetTime.inSeconds, greaterThan(0));
    });

    test('getResetTime returns zero for unknown client', () {
      final resetTime = store.getResetTime('unknown', const Duration(minutes: 1));
      expect(resetTime, Duration.zero);
    });
  });
}
