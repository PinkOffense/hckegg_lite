import 'package:dart_frog/dart_frog.dart';

import '../lib/core/core.dart';
import '../lib/core/middleware/cors.dart';
import '../lib/core/middleware/rate_limiter.dart';

/// Global middleware for all routes
Handler middleware(Handler handler) {
  // Configure logger from environment
  Logger.configureFromEnvironment();

  return handler
      .use(requestLogger())
      .use(rateLimiter())
      .use(corsMiddleware())
      .use(supabaseProvider());
}

/// Request logging middleware
Middleware requestLogger() {
  return (handler) {
    return (context) async {
      final request = context.request;
      final stopwatch = Stopwatch()..start();

      final response = await handler(context);

      stopwatch.stop();
      Logger.request(
        request.method.value,
        request.uri.path,
        statusCode: response.statusCode,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      return response;
    };
  };
}

/// Supabase client provider middleware
Middleware supabaseProvider() {
  return (handler) {
    return (context) async {
      // Initialize Supabase if not already done
      if (!SupabaseClientManager.isInitialized) {
        final supabaseUrl = const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: '',
        );
        final supabaseKey = const String.fromEnvironment(
          'SUPABASE_SERVICE_ROLE_KEY',
          defaultValue: '',
        );

        if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
          SupabaseClientManager.initialize(
            url: supabaseUrl,
            anonKey: supabaseKey,
          );
          Logger.info('Supabase client initialized');
        } else {
          Logger.warning('Supabase credentials not configured');
        }
      }

      return handler(context);
    };
  };
}
