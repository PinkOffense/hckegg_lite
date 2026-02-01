import 'package:dart_frog/dart_frog.dart';

/// Root route - API information
Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'name': 'HCKEgg API',
      'version': '1.0.0',
      'description': 'Backend API for HCKEgg egg production management',
      'endpoints': {
        'health': '/health',
        'api': '/api/v1',
        'eggs': '/api/v1/eggs',
        'sales': '/api/v1/sales',
        'expenses': '/api/v1/expenses',
        'reservations': '/api/v1/reservations',
        'feed_stock': '/api/v1/feed_stock',
        'health_records': '/api/v1/health',
      },
      'documentation': 'https://github.com/PinkOffense/hckegg_lite',
    },
  );
}
