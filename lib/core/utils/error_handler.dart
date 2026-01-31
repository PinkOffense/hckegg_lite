// lib/core/utils/error_handler.dart
import 'package:flutter/foundation.dart';

/// Centralized error handler for logging and user-friendly messages
class ErrorHandler {
  /// Log error for debugging (only in debug mode)
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$context] Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Convert technical errors to user-friendly messages
  static String getUserFriendlyMessage(dynamic error, String locale) {
    final errorStr = error.toString().toLowerCase();

    // Network errors
    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection') ||
        errorStr.contains('network') ||
        errorStr.contains('timeout')) {
      return locale == 'pt'
          ? 'Sem ligação à internet. Verifica a tua conexão.'
          : 'No internet connection. Please check your network.';
    }

    // Authentication errors
    if (errorStr.contains('invalid login') ||
        errorStr.contains('invalid password') ||
        errorStr.contains('user not found')) {
      return locale == 'pt'
          ? 'Email ou password incorretos.'
          : 'Invalid email or password.';
    }

    if (errorStr.contains('email not confirmed')) {
      return locale == 'pt'
          ? 'Por favor, confirma o teu email primeiro.'
          : 'Please confirm your email first.';
    }

    if (errorStr.contains('user already registered') ||
        errorStr.contains('already exists')) {
      return locale == 'pt'
          ? 'Este email já está registado.'
          : 'This email is already registered.';
    }

    // Rate limiting
    if (errorStr.contains('too many requests') ||
        errorStr.contains('rate limit')) {
      return locale == 'pt'
          ? 'Demasiadas tentativas. Aguarda um momento.'
          : 'Too many attempts. Please wait a moment.';
    }

    // Permission errors
    if (errorStr.contains('permission') ||
        errorStr.contains('forbidden') ||
        errorStr.contains('unauthorized')) {
      return locale == 'pt'
          ? 'Não tens permissão para esta ação.'
          : 'You do not have permission for this action.';
    }

    // Server errors
    if (errorStr.contains('500') ||
        errorStr.contains('server') ||
        errorStr.contains('internal')) {
      return locale == 'pt'
          ? 'Erro no servidor. Tenta novamente mais tarde.'
          : 'Server error. Please try again later.';
    }

    // Default message
    return locale == 'pt'
        ? 'Algo correu mal. Tenta novamente.'
        : 'Something went wrong. Please try again.';
  }
}
