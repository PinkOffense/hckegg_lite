import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'lib/core/core.dart';

/// Custom entrypoint for Dart Frog server
/// This function is called by dart_frog to start the server
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
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
    Logger.warning(
      'Supabase not configured - set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY',
    );
  }

  // Force binding to 0.0.0.0 (IPv4 all interfaces) for Render compatibility
  final bindAddress = InternetAddress.anyIPv4;

  Logger.info('HCKEgg API Server starting on ${bindAddress.address}:$port');

  // Start the server using dart_frog's serve function
  return serve(handler, bindAddress, port);
}
