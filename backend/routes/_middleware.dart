import 'package:dart_frog/dart_frog.dart';

import '../lib/core/core.dart';

/// Global middleware for all routes
Handler middleware(Handler handler) {
  // Configure logger from environment
  Logger.configureFromEnvironment();

  return handler
      .use(requestLogger())
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

/// CORS middleware
Middleware corsMiddleware() {
  return (handler) {
    return (context) async {
      // Handle preflight requests
      if (context.request.method == HttpMethod.options) {
        return Response(
          statusCode: 200,
          headers: _corsHeaders,
        );
      }

      final response = await handler(context);

      return response.copyWith(
        headers: {...response.headers, ..._corsHeaders},
      );
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, x-user-id',
  'Access-Control-Max-Age': '86400',
};

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
