// lib/app/app_bootstrap.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/di/service_locator.dart';
import '../core/utils/connectivity_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ErrorWidget compacto (não explode a UI)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 140),
      color: Colors.red.shade200,
      child: Text(
        details.exceptionAsString(),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
    );
  };

  // Lê as keys via --dart-define (seguro)
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      // Auto refresh token before it expires
      autoRefreshToken: true,
    ),
  );

  // Initialize clean architecture service locator
  ServiceLocator.instance.initialize();

  // Start connectivity monitoring
  ConnectivityService().startMonitoring();
}
