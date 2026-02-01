import 'package:dart_frog/dart_frog.dart';

import '../lib/core/core.dart';

/// Health check endpoint
/// GET /health
Response onRequest(RequestContext context) {
  final supabaseStatus =
      SupabaseClientManager.isInitialized ? 'connected' : 'not_initialized';

  return Response.json(
    body: {
      'status': 'ok',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'services': {
        'supabase': supabaseStatus,
      },
    },
  );
}
