import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'lib/core/core.dart';

/// Main entry point for the HCKEgg API server
Future<void> main() async {
  // Configure logger
  Logger.configureFromEnvironment();

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
    Logger.info('Supabase initialized');
  } else {
    Logger.warning('Supabase not configured - set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY');
  }

  // Get server configuration
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final host = Platform.environment['HOST'] ?? '0.0.0.0';

  Logger.info('HCKEgg API Server starting on $host:$port');

  // Note: Dart Frog handles the server startup
  // This file is for initialization only
}
