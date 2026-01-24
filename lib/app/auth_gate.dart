// lib/app/auth_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/login_page.dart';
import '../pages/dashboard_page.dart';
import '../state/app_state.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _sub;
  bool signedIn = false;
  bool ready = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();

    final client = Supabase.instance.client;

    signedIn = client.auth.currentUser != null;
    ready = true;

    // Carregar dados se já estiver autenticado
    if (signedIn) {
      _loadData();
    }

    _sub = client.auth.onAuthStateChange.listen((data) {
      final wasSignedIn = signedIn;
      final isSignedIn = data.session != null;

      setState(() {
        signedIn = isSignedIn;
      });

      // Carregar dados quando faz login
      if (!wasSignedIn && isSignedIn) {
        _loadData();
      }

      // Limpar dados quando faz logout
      if (wasSignedIn && !isSignedIn) {
        _dataLoaded = false;
      }
    });
  }

  Future<void> _loadData() async {
    if (_dataLoaded) return;

    final appState = Provider.of<AppState>(context, listen: false);
    await appState.loadAllData();
    _dataLoaded = true;
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!signedIn) return const LoginPage();

    return const DashboardPage();
  }
}
