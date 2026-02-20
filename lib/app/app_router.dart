// lib/app/app_router.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../pages/login_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/egg_list_page.dart';
import '../pages/sales_page.dart';
import '../pages/payments_page.dart';
import '../pages/reservations_page.dart';
import '../pages/expenses_page.dart';
import '../pages/settings_page.dart';
import '../pages/hen_health_page.dart';
import '../pages/vet_calendar_page.dart';
import '../pages/feed_stock_page.dart';
import 'auth_gate.dart';

/// Route path constants
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String eggs = '/eggs';
  static const String sales = '/sales';
  static const String payments = '/payments';
  static const String reservations = '/reservations';
  static const String expenses = '/expenses';
  static const String settings = '/settings';
  static const String health = '/health';
  static const String vetCalendar = '/vet-calendar';
  static const String feedStock = '/feed-stock';
}

/// Notifier that triggers GoRouter refresh on auth state changes
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthChangeNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event != AuthChangeEvent.tokenRefreshed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final _authNotifier = _AuthChangeNotifier();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _authNotifier,
    redirect: _authRedirect,
    errorBuilder: _errorPage,
    routes: [
      // Login route (unauthenticated)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),

      // All authenticated routes wrapped in DataLoaderShell
      ShellRoute(
        builder: (context, state, child) => DataLoaderShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.eggs,
            builder: (context, state) => const EggListPage(),
          ),
          GoRoute(
            path: AppRoutes.sales,
            builder: (context, state) => const SalesPage(),
          ),
          GoRoute(
            path: AppRoutes.payments,
            builder: (context, state) => const PaymentsPage(),
          ),
          GoRoute(
            path: AppRoutes.reservations,
            builder: (context, state) => const ReservationsPage(),
          ),
          GoRoute(
            path: AppRoutes.expenses,
            builder: (context, state) => const ExpensesPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.health,
            builder: (context, state) => const HenHealthPage(),
          ),
          GoRoute(
            path: AppRoutes.vetCalendar,
            builder: (context, state) => const VetCalendarPage(),
          ),
          GoRoute(
            path: AppRoutes.feedStock,
            builder: (context, state) => const FeedStockPage(),
          ),
        ],
      ),
    ],
  );

  /// Redirect unauthenticated users to login, authenticated users away from login
  static String? _authRedirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    final isLoginRoute = state.matchedLocation == AppRoutes.login;

    if (!isAuthenticated && !isLoginRoute) return AppRoutes.login;
    if (isAuthenticated && isLoginRoute) return AppRoutes.home;
    return null;
  }

  /// Error page for unknown routes
  static Widget _errorPage(BuildContext context, GoRouterState state) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final t = (String k) => Translations.of(locale, k);

    return Scaffold(
      appBar: AppBar(title: Text(t('error_title'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '${t('route_not_found')}: ${state.uri.path}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.home),
              label: Text(t('go_to_home')),
            ),
          ],
        ),
      ),
    );
  }
}
