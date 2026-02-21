// lib/app/auth_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/providers/providers.dart';
import '../features/eggs/presentation/providers/egg_provider.dart';
import '../features/analytics/presentation/providers/analytics_provider.dart';
import '../features/farms/presentation/providers/farm_provider.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

/// Shell widget that wraps authenticated routes.
/// Handles initial data loading with a loading screen, skip button, and timeout.
/// Used by GoRouter's ShellRoute to wrap all authenticated pages.
class DataLoaderShell extends StatefulWidget {
  final Widget child;
  const DataLoaderShell({super.key, required this.child});

  @override
  State<DataLoaderShell> createState() => _DataLoaderShellState();
}

class _DataLoaderShellState extends State<DataLoaderShell> {
  bool _dataLoading = false;
  bool _dataLoaded = false;
  bool _showSkip = false;
  Timer? _skipTimer;
  String? _loadingMessage;
  String? _lastUserId;
  StreamSubscription<AuthState>? _authSubscription;

  static const _loadTimeout = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();

    // Listen for auth state changes to reset data when user changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final currentUserId = event.session?.user.id;

      // If user changed (login/logout), reset data loading
      if (_lastUserId != null && _lastUserId != currentUserId) {
        setState(() {
          _dataLoaded = false;
          _dataLoading = false;
        });
        if (currentUserId != null && mounted) {
          _loadData();
        }
      }
      _lastUserId = currentUserId;
    });

    // Initial user ID
    _lastUserId = Supabase.instance.client.auth.currentUser?.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_dataLoading || _dataLoaded || !mounted) return;

    setState(() {
      _dataLoading = true;
      _showSkip = false;
      _loadingMessage = null;
    });

    // Show skip button after 4 seconds so user isn't stuck
    _skipTimer?.cancel();
    _skipTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _dataLoading) {
        setState(() => _showSkip = true);
      }
    });

    try {
      setState(() => _loadingMessage = 'Loading your data...');

      // Initialize FarmProvider first (needed for multi-user data)
      await context.read<FarmProvider>().initialize();

      // Load primary data with timeout to prevent infinite loading
      await Future.wait([
        context.read<EggProvider>().loadRecords(),
        context.read<AnalyticsProvider>().loadDashboardAnalytics(),
        context.read<SaleProvider>().loadSales(),
      ]).timeout(_loadTimeout);

      _proceed();
    } catch (e) {
      // Timeout or error: show content anyway (pages handle error/empty states)
      _proceed();
    }
  }

  void _proceed() {
    _skipTimer?.cancel();
    if (mounted && !_dataLoaded) {
      setState(() {
        _dataLoaded = true;
        _dataLoading = false;
        _showSkip = false;
      });
      _loadSecondaryData();
    }
  }

  void _loadSecondaryData() {
    if (!mounted) return;
    // Load secondary providers individually so one failure doesn't block others
    _loadWithRetry(() => context.read<ExpenseProvider>().loadExpenses());
    _loadWithRetry(() => context.read<ReservationProvider>().loadReservations());
    _loadWithRetry(() => context.read<VetRecordProvider>().loadVetRecords());
    _loadWithRetry(() => context.read<FeedStockProvider>().loadFeedStocks());
  }

  /// Load with a single retry after 2 seconds on failure
  Future<void> _loadWithRetry(Future<void> Function() loader) async {
    try {
      await loader();
    } catch (_) {
      // Retry once after a short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        try { await loader(); } catch (_) { /* Non-blocking */ }
      }
    }
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dataLoading && !_dataLoaded) {
      return _LoadingScreen(
        message: _loadingMessage,
        showSkip: _showSkip,
        onSkip: _proceed,
      );
    }
    return widget.child;
  }
}

/// Loading screen shown while initial data loads
class _LoadingScreen extends StatelessWidget {
  final String? message;
  final bool showSkip;
  final VoidCallback? onSkip;

  const _LoadingScreen({
    this.message,
    this.showSkip = false,
    this.onSkip,
  });

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
              Text(
                t('app_title'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message ?? (locale == 'pt' ? 'A carregar...' : 'Loading...'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 32),
              AnimatedOpacity(
                opacity: showSkip ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: TextButton(
                  onPressed: showSkip ? onSkip : null,
                  child: Text(
                    locale == 'pt' ? 'Continuar mesmo assim' : 'Continue anyway',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
