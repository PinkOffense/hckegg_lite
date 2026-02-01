import 'package:dart_frog/dart_frog.dart';

/// Middleware for docs routes - no authentication required
Handler middleware(Handler handler) {
  return handler.use(_corsMiddleware());
}

/// CORS middleware for docs
Middleware _corsMiddleware() {
  return (handler) {
    return (context) async {
      // Handle preflight requests
      if (context.request.method == HttpMethod.options) {
        return Response(
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
          },
        );
      }

      final response = await handler(context);
      return response.copyWith(
        headers: {
          ...response.headers,
          'Access-Control-Allow-Origin': '*',
        },
      );
    };
  };
}
