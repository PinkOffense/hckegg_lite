// lib/app/auth_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/login_page.dart';
import '../pages/dashboard_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _sub;
  bool signedIn = false;
  bool ready = false;

  @override
  void initState() {
    super.initState();

    final client = Supabase.instance.client;

    signedIn = client.auth.currentUser != null;
    ready = true;

    _sub = client.auth.onAuthStateChange.listen((data) {
      setState(() {
        signedIn = data.session != null;
      });
    });
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
