import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Serves Swagger UI for API documentation
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final host = context.request.headers['host'] ?? 'localhost:8080';
  final scheme = context.request.headers['x-forwarded-proto'] ?? 'http';
  final openApiUrl = '$scheme://$host/docs/openapi';

  const html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>HCKEgg API - Documentation</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css">
  <style>
    body { margin: 0; padding: 0; }
    .swagger-ui .topbar { display: none; }
    .swagger-ui .info { margin: 20px 0; }
    .swagger-ui .info .title { font-size: 2em; }
  </style>
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js"></script>
  <script>
    window.onload = () => {
      SwaggerUIBundle({
        url: '{{OPENAPI_URL}}',
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIBundle.SwaggerUIStandalonePreset
        ],
        layout: 'BaseLayout',
        persistAuthorization: true,
        tryItOutEnabled: true
      });
    };
  </script>
</body>
</html>
''';

  final renderedHtml = html.replaceAll('{{OPENAPI_URL}}', openApiUrl);

  return Response(
    body: renderedHtml,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
    },
  );
}
