// lib/app/auth_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/login_page.dart';
import '../pages/dashboard_page.dart';
import '../state/providers/providers.dart';

/// Authentication gate that handles routing between login and dashboard.
///
/// Listens to Supabase auth state changes and:
/// - Loads user data on login
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
  bool _dataLoaded = false;

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

    // Load data if already authenticated
    if (_signedIn) {
      _loadData();
    }

    // Listen for auth state changes
    _sub = client.auth.onAuthStateChange.listen(_handleAuthStateChange);
  }

  void _handleAuthStateChange(AuthState data) {
    final wasSignedIn = _signedIn;
    final isSignedIn = data.session != null;

    // Update signed in state
    if (mounted) {
      setState(() {
        _signedIn = isSignedIn;
      });
    }

    // Handle login: load user data
    if (!wasSignedIn && isSignedIn) {
      _loadData();
    }

    // Handle logout: reset data loaded flag
    // Note: Actual provider clearing is done by LogoutManager before sign out
    if (wasSignedIn && !isSignedIn) {
      _dataLoaded = false;
    }
  }

  Future<void> _loadData() async {
    if (_dataLoaded || !mounted) return;

    try {
      // Load data from all domain-specific providers in parallel
      await Future.wait([
        context.read<EggRecordProvider>().loadRecords(),
        context.read<ExpenseProvider>().loadExpenses(),
        context.read<VetRecordProvider>().loadVetRecords(),
        context.read<SaleProvider>().loadSales(),
        context.read<ReservationProvider>().loadReservations(),
        context.read<FeedStockProvider>().loadFeedStocks(),
      ]);

      _dataLoaded = true;
    } catch (e) {
      // Data loading failed, but continue to dashboard
      // Individual providers will handle their own error states
      _dataLoaded = true;
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

    return _signedIn ? const DashboardPage() : const LoginPage();
  }
}
