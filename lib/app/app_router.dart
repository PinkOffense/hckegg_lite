// lib/app/app_router.dart
import 'package:flutter/material.dart';
import '../pages/dashboard_page.dart';
import '../pages/egg_list_page.dart';
import '../pages/egg_detail_page.dart';
import '../pages/sync_page.dart';
import '../pages/settings_page.dart';

class AppRouter {
  static const String home = '/';
  static const String eggs = '/eggs';
  static const String eggDetail = '/detail';
  static const String sync = '/sync';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
          settings: settings,
        );

      case eggs:
        return MaterialPageRoute(
          builder: (_) => const EggListPage(),
          settings: settings,
        );

      case eggDetail:
        final args = settings.arguments;
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => EggDetailPage(eggId: args),
            settings: settings,
          );
        }
        // Fallback if no argument provided
        return _errorRoute(settings);

      case sync:
        return MaterialPageRoute(
          builder: (_) => const SyncPage(),
          settings: settings,
        );

      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
          settings: settings,
        );

      default:
        return _errorRoute(settings);
    }
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Route not found: ${settings.name}',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(_).pushReplacementNamed('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }
}
