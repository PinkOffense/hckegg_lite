import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'lib/core/core.dart';

/// Main entry point for the HCKEgg API server
Future<void> main() async {
  // Load environment variables
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
  final supabaseServiceKey =
      Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  // Initialize Supabase
  if (supabaseUrl.isNotEmpty && supabaseServiceKey.isNotEmpty) {
    SupabaseClientManager.initialize(
      url: supabaseUrl,
      anonKey: supabaseServiceKey,
    );
    print('✓ Supabase initialized');
  } else {
    print('⚠ Supabase not configured - set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY');
  }

  // Get server configuration
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final host = Platform.environment['HOST'] ?? '0.0.0.0';

  print('');
  print('╔════════════════════════════════════════╗');
  print('║         HCKEgg API Server              ║');
  print('║         Clean Architecture             ║');
  print('╠════════════════════════════════════════╣');
  print('║  Starting server on $host:$port');
  print('╚════════════════════════════════════════╝');
  print('');

  // Note: Dart Frog handles the server startup
  // This file is for initialization only
}
