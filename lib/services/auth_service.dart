// lib/services/auth_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient client;

  AuthService(this.client);

  User? get currentUser => client.auth.currentUser;

  /// Stream de estado de autenticação (API v2)
  Stream<AuthState> get authState => client.auth.onAuthStateChange;

  /// Login com email/password
  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Criar conta com email/password
  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Login com Google
  Future<AuthResponse> signInWithGoogle() async {
    if (kIsWeb) {
      // Para web, usar OAuth redirect
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.hckegg://login-callback/',
      );
      // OAuth redirect não retorna AuthResponse diretamente
      // O utilizador será redirecionado e o estado de auth será atualizado via stream
      throw AuthException('Redirecting to Google sign-in...');
    } else {
      // Para mobile, usar Google Sign-In nativo
      const webClientId = String.fromEnvironment(
        'GOOGLE_WEB_CLIENT_ID',
        defaultValue: '',
      );
      const iosClientId = String.fromEnvironment(
        'GOOGLE_IOS_CLIENT_ID',
        defaultValue: '',
      );

      final googleSignIn = GoogleSignIn(
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw AuthException('Failed to get ID token from Google');
      }

      return await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    }
  }

  Future<void> signOut() async {
    // Sign out do Google também (se estiver logado)
    if (!kIsWeb) {
      try {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (_) {
        // Ignorar erros de Google sign-out
      }
    }
    await client.auth.signOut();
  }

  /// Verificar se o utilizador atual usou email/password (não Google)
  bool get isEmailPasswordUser {
    final user = currentUser;
    if (user == null) return false;

    // Check if user has email provider (not Google)
    final identities = user.identities;
    if (identities == null || identities.isEmpty) return false;

    // User is email/password if they have 'email' provider
    return identities.any((identity) => identity.provider == 'email');
  }

  /// Mudar a password do utilizador atual
  /// Só funciona para utilizadores que criaram conta com email/password
  Future<void> changePassword(String newPassword) async {
    if (!isEmailPasswordUser) {
      throw AuthException('Password change is only available for email/password accounts');
    }

    if (newPassword.length < 6) {
      throw AuthException('Password must be at least 6 characters');
    }

    await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
