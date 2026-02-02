// backend/lib/core/middleware/rate_limiter.dart
import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Rate limiter configuration
class RateLimitConfig {
  /// Maximum number of requests allowed in the time window
  final int maxRequests;

  /// Time window duration
  final Duration windowDuration;

  /// Optional: Different limits for authenticated users
  final int? authenticatedMaxRequests;

  /// Paths that are exempt from rate limiting
  final List<String> exemptPaths;

  /// Paths with stricter rate limits (e.g., auth endpoints)
  final Map<String, RateLimitConfig> pathOverrides;

  const RateLimitConfig({
    this.maxRequests = 100,
    this.windowDuration = const Duration(minutes: 1),
    this.authenticatedMaxRequests,
    this.exemptPaths = const ['/health', '/docs'],
    this.pathOverrides = const {},
  });

  /// Default configuration for production
  static const production = RateLimitConfig(
    maxRequests: 100,
    windowDuration: Duration(minutes: 1),
    authenticatedMaxRequests: 200,
    exemptPaths: ['/health', '/docs', '/docs/openapi'],
    pathOverrides: {
      '/api/v1/auth/signin': RateLimitConfig(
        maxRequests: 5,
        windowDuration: Duration(minutes: 1),
      ),
      '/api/v1/auth/signup': RateLimitConfig(
        maxRequests: 3,
        windowDuration: Duration(minutes: 1),
      ),
      '/api/v1/auth/refresh': RateLimitConfig(
        maxRequests: 10,
        windowDuration: Duration(minutes: 1),
      ),
    },
  );

  /// Development configuration (more permissive)
  static const development = RateLimitConfig(
    maxRequests: 1000,
    windowDuration: Duration(minutes: 1),
    exemptPaths: ['/health', '/docs', '/docs/openapi'],
  );
}

/// Entry tracking for rate limiting
class _RateLimitEntry {
  int requestCount;
  DateTime windowStart;

  _RateLimitEntry({
    required this.requestCount,
    required this.windowStart,
  });

  bool isExpired(Duration windowDuration) {
    return DateTime.now().difference(windowStart) > windowDuration;
  }

  void reset() {
    requestCount = 1;
    windowStart = DateTime.now();
  }

  void increment() {
    requestCount++;
  }
}

/// In-memory rate limiter store
/// For production, consider Redis or another distributed store
class RateLimiterStore {
  final Map<String, _RateLimitEntry> _entries = {};
  Timer? _cleanupTimer;

  RateLimiterStore() {
    // Cleanup expired entries every 5 minutes
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanup(),
    );
  }

  /// Check if the request should be allowed
  /// Returns remaining requests or -1 if rate limited
  int checkAndIncrement(String key, RateLimitConfig config) {
    final entry = _entries[key];
    final now = DateTime.now();

    if (entry == null) {
      _entries[key] = _RateLimitEntry(
        requestCount: 1,
        windowStart: now,
      );
      return config.maxRequests - 1;
    }

    if (entry.isExpired(config.windowDuration)) {
      entry.reset();
      return config.maxRequests - 1;
    }

    if (entry.requestCount >= config.maxRequests) {
      return -1; // Rate limited
    }

    entry.increment();
    return config.maxRequests - entry.requestCount;
  }

  /// Get time until the rate limit window resets
  Duration getResetTime(String key, Duration windowDuration) {
    final entry = _entries[key];
    if (entry == null) return Duration.zero;

    final elapsed = DateTime.now().difference(entry.windowStart);
    final remaining = windowDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _cleanup() {
    final keysToRemove = <String>[];
    for (final entry in _entries.entries) {
      // Remove entries that have been inactive for more than 10 minutes
      if (entry.value.isExpired(const Duration(minutes: 10))) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _entries.remove(key);
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _entries.clear();
  }
}

/// Global rate limiter store instance
final _store = RateLimiterStore();

/// Rate limiting middleware
/// Limits requests based on IP address (or user ID if authenticated)
Middleware rateLimiter([RateLimitConfig? config]) {
  final effectiveConfig = config ?? _getConfigFromEnvironment();

  return (handler) {
    return (context) async {
      final request = context.request;
      final path = request.uri.path;

      // Check if path is exempt
      if (effectiveConfig.exemptPaths.any((p) => path.startsWith(p))) {
        return handler(context);
      }

      // Get the effective config for this path
      RateLimitConfig pathConfig = effectiveConfig;
      for (final override in effectiveConfig.pathOverrides.entries) {
        if (path.startsWith(override.key)) {
          pathConfig = override.value;
          break;
        }
      }

      // Get client identifier (IP address or forwarded IP)
      final clientId = _getClientId(request);

      // Check rate limit
      final remaining = _store.checkAndIncrement(clientId, pathConfig);

      if (remaining < 0) {
        // Rate limited
        final resetTime = _store.getResetTime(clientId, pathConfig.windowDuration);
        return Response.json(
          statusCode: HttpStatus.tooManyRequests,
          headers: {
            'X-RateLimit-Limit': pathConfig.maxRequests.toString(),
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Reset': resetTime.inSeconds.toString(),
            'Retry-After': resetTime.inSeconds.toString(),
          },
          body: {
            'error': 'Too many requests',
            'message': 'Rate limit exceeded. Please try again later.',
            'retryAfter': resetTime.inSeconds,
          },
        );
      }

      // Add rate limit headers to response
      final response = await handler(context);
      return response.copyWith(
        headers: {
          ...response.headers,
          'X-RateLimit-Limit': pathConfig.maxRequests.toString(),
          'X-RateLimit-Remaining': remaining.toString(),
        },
      );
    };
  };
}

/// Get client identifier from request
String _getClientId(Request request) {
  // Check for forwarded IP (when behind a proxy/load balancer)
  final forwarded = request.headers['x-forwarded-for'];
  if (forwarded != null && forwarded.isNotEmpty) {
    // Take the first IP in the chain
    return forwarded.split(',').first.trim();
  }

  final realIp = request.headers['x-real-ip'];
  if (realIp != null && realIp.isNotEmpty) {
    return realIp;
  }

  // Fallback to a default (in production, you'd get the actual client IP)
  return request.headers['host'] ?? 'unknown';
}

/// Get rate limit config from environment
RateLimitConfig _getConfigFromEnvironment() {
  final env = const String.fromEnvironment('ENV', defaultValue: 'development');
  return env == 'production'
      ? RateLimitConfig.production
      : RateLimitConfig.development;
}
