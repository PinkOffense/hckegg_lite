// lib/services/logout_manager.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/providers/providers.dart';
import '../features/eggs/presentation/providers/egg_provider.dart';

/// Centralized logout manager that handles the complete sign-out process.
///
/// This ensures consistent logout behavior across the app by:
/// - Clearing all provider data
/// - Signing out from Google (if applicable)
/// - Signing out from Supabase
/// - Proper error handling and fallbacks
class LogoutManager {
  final SupabaseClient _client;

  LogoutManager(this._client);

  /// Factory constructor using the global Supabase instance
  factory LogoutManager.instance() => LogoutManager(Supabase.instance.client);

  /// Clears all provider data from the given context.
  ///
  /// This should be called before signing out to prevent data leakage
  /// between different user sessions.
  void clearAllProviders(BuildContext context) {
    try {
      context.read<EggProvider>().clearData();
    } catch (_) {
      // Provider might not exist in context
    }
    try {
      context.read<ExpenseProvider>().clearData();
    } catch (_) {}
    try {
      context.read<VetRecordProvider>().clearData();
    } catch (_) {}
    try {
      context.read<SaleProvider>().clearData();
    } catch (_) {}
    try {
      context.read<ReservationProvider>().clearData();
    } catch (_) {}
    try {
      context.read<FeedStockProvider>().clearData();
    } catch (_) {}
  }

  /// Signs out from Google if on mobile/desktop platforms.
  ///
  /// This is necessary because Google Sign-In maintains its own session
  /// separate from Supabase auth.
  Future<void> _signOutFromGoogle() async {
    if (kIsWeb) return;

    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {
      // Google sign-out failed, but we continue with Supabase sign-out
    }
  }

  /// Signs out from Supabase authentication.
  ///
  /// Uses local scope for faster sign-out (only this device).
  /// Falls back to global scope if local fails.
  Future<void> _signOutFromSupabase() async {
    // Use local scope for faster sign-out (doesn't need server round-trip)
    await _client.auth.signOut(scope: SignOutScope.local);
  }

  /// Performs the complete sign-out process.
  ///
  /// Steps:
  /// 1. Clear all provider data (prevents data leakage)
  /// 2. Sign out from Google (if applicable)
  /// 3. Sign out from Supabase
  ///
  /// The auth state listener will automatically handle navigation
  /// to the login page.
  ///
  /// Throws [LogoutException] if sign-out fails after all retry attempts.
  Future<void> signOut(BuildContext context) async {
    // Step 1: Clear all provider data first
    clearAllProviders(context);

    // Step 2: Sign out from Google (non-blocking)
    await _signOutFromGoogle();

    // Step 3: Sign out from Supabase
    try {
      await _signOutFromSupabase();
    } catch (e) {
      // If local scope fails, try without scope as fallback
      try {
        await _client.auth.signOut();
      } catch (fallbackError) {
        throw LogoutException('Failed to sign out: $fallbackError');
      }
    }
  }

  /// Performs sign-out without requiring BuildContext for provider cleanup.
  ///
  /// Use this when you've already captured provider references or when
  /// calling from a location where context might be invalid.
  Future<void> signOutWithoutContext() async {
    await _signOutFromGoogle();
    try {
      await _signOutFromSupabase();
    } catch (e) {
      try {
        await _client.auth.signOut();
      } catch (fallbackError) {
        throw LogoutException('Failed to sign out: $fallbackError');
      }
    }
  }
}

/// Exception thrown when logout fails
class LogoutException implements Exception {
  final String message;
  LogoutException(this.message);

  @override
  String toString() => message;
}
