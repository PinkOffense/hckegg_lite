// lib/app/auth_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/login_page.dart';
import '../pages/dashboard_page.dart';
import '../state/providers/providers.dart';
import '../features/eggs/presentation/providers/egg_provider.dart';
import '../features/analytics/presentation/providers/analytics_provider.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

/// Authentication gate that handles routing between login and dashboard.
///
/// Listens to Supabase auth state changes and:
/// - Loads user data on login with proper loading screen
/// - Clears data flags on logout (actual clearing done by LogoutManager)
/// - Automatically navigates between LoginPage and DashboardPage
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _sub;
  bool _signedIn = false;
  bool _ready = false;
  bool _dataLoading = false;
  bool _dataLoaded = false;
  String? _loadingMessage;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() {
    final client = Supabase.instance.client;

    // Check current auth state
    _signedIn = client.auth.currentUser != null;
    _ready = true;

    // Load data if already authenticated (deferred to after frame to ensure providers are ready)
    if (_signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData();
      });
    }

    // Listen for auth state changes
    _sub = client.auth.onAuthStateChange.listen(_handleAuthStateChange);
  }

  void _handleAuthStateChange(AuthState data) {
    final wasSignedIn = _signedIn;
    final isSignedIn = data.session != null;
    final event = data.event;

    // Token refresh is handled automatically - no UI change needed
    if (event == AuthChangeEvent.tokenRefreshed) {
      return;
    }

    // Update signed in state
    if (mounted) {
      setState(() {
        _signedIn = isSignedIn;
      });
    }

    // Handle login: load user data (deferred to ensure providers are ready)
    if (!wasSignedIn && isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData();
      });
    }

    // Handle logout: reset data loaded flag
    // Note: Actual provider clearing is done by LogoutManager before sign out
    if (wasSignedIn && !isSignedIn) {
      setState(() {
        _dataLoaded = false;
        _dataLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (_dataLoading || _dataLoaded || !mounted) return;

    setState(() {
      _dataLoading = true;
      _loadingMessage = null;
    });

    try {
      // Load critical data with visual feedback
      _updateLoadingMessage('Loading your data...');

      // Load primary data that's needed for dashboard
      await Future.wait([
        context.read<EggProvider>().loadRecords(),
        context.read<AnalyticsProvider>().loadDashboardAnalytics(),
        context.read<SaleProvider>().loadSales(),
      ]);

      // Mark as loaded before loading secondary data
      if (mounted) {
        setState(() {
          _dataLoaded = true;
          _dataLoading = false;
        });
      }

      // Load secondary data in background (non-blocking)
      _loadSecondaryDataInBackground();
    } catch (e) {
      // Even on error, show the dashboard (it will handle error states)
      if (mounted) {
        setState(() {
          _dataLoaded = true;
          _dataLoading = false;
        });
      }
    }
  }

  void _updateLoadingMessage(String message) {
    if (mounted) {
      setState(() {
        _loadingMessage = message;
      });
    }
  }

  void _loadSecondaryDataInBackground() {
    // These are needed for other pages - load in background
    if (mounted) {
      context.read<ExpenseProvider>().loadExpenses();
      context.read<ReservationProvider>().loadReservations();
      context.read<VetRecordProvider>().loadVetRecords();
      context.read<FeedStockProvider>().loadFeedStocks();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Not signed in - show login
    if (!_signedIn) {
      return const LoginPage();
    }

    // Signed in but still loading primary data - show loading screen
    if (_dataLoading && !_dataLoaded) {
      return _LoadingScreen(message: _loadingMessage);
    }

    // Data loaded (or loading failed) - show dashboard
    return const DashboardPage();
  }
}

/// Loading screen shown while initial data loads
class _LoadingScreen extends StatelessWidget {
  final String? message;

  const _LoadingScreen({this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().code;
    final t = (String k) => Translations.of(locale, k);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon/logo area
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.egg,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // App title
              Text(
                t('app_title'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Loading message
              Text(
                message ?? (locale == 'pt' ? 'A carregar...' : 'Loading...'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),

              // Hint about first load
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  locale == 'pt'
                      ? 'O primeiro carregamento pode demorar alguns segundos'
                      : 'First load may take a few seconds',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
