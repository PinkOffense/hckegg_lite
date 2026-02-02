// lib/core/utils/error_handler.dart
import 'package:flutter/foundation.dart';

/// Centralized error handler for logging and user-friendly messages
class ErrorHandler {
  /// Patterns that indicate sensitive information that should be hidden
  static final List<RegExp> _sensitivePatterns = [
    RegExp(r'sql', caseSensitive: false),
    RegExp(r'database', caseSensitive: false),
    RegExp(r'postgres', caseSensitive: false),
    RegExp(r'supabase', caseSensitive: false),
    RegExp(r'exception', caseSensitive: false),
    RegExp(r'stack\s*trace', caseSensitive: false),
    RegExp(r'\.dart:', caseSensitive: false),
    RegExp(r'at\s+line\s+\d+', caseSensitive: false),
    RegExp(r'api[_-]?key', caseSensitive: false),
    RegExp(r'secret', caseSensitive: false),
    RegExp(r'password.*=', caseSensitive: false),
    RegExp(r'token.*=', caseSensitive: false),
  ];

  /// Log error for debugging (only in debug mode)
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$context] Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Check if error message contains sensitive information
  static bool _containsSensitiveInfo(String message) {
    for (final pattern in _sensitivePatterns) {
      if (pattern.hasMatch(message)) {
        return true;
      }
    }
    return false;
  }

  /// Convert technical errors to user-friendly messages
  /// This method sanitizes error messages to prevent information leakage
  static String getUserFriendlyMessage(dynamic error, String locale) {
    final errorStr = error.toString().toLowerCase();

    // If the error contains sensitive information, return a generic message
    if (_containsSensitiveInfo(errorStr)) {
      return locale == 'pt'
          ? 'Ocorreu um erro. Tenta novamente.'
          : 'An error occurred. Please try again.';
    }

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
        errorStr.contains('user not found') ||
        errorStr.contains('invalid credential')) {
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
        errorStr.contains('already exists') ||
        errorStr.contains('email already')) {
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
        errorStr.contains('unauthorized') ||
        errorStr.contains('403')) {
      return locale == 'pt'
          ? 'Não tens permissão para esta ação.'
          : 'You do not have permission for this action.';
    }

    // Validation errors
    if (errorStr.contains('validation') ||
        errorStr.contains('invalid input') ||
        errorStr.contains('required field')) {
      return locale == 'pt'
          ? 'Dados inválidos. Verifica os campos.'
          : 'Invalid data. Please check your input.';
    }

    // Not found errors
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return locale == 'pt'
          ? 'Recurso não encontrado.'
          : 'Resource not found.';
    }

    // Server errors
    if (errorStr.contains('500') ||
        errorStr.contains('server') ||
        errorStr.contains('internal') ||
        errorStr.contains('502') ||
        errorStr.contains('503')) {
      return locale == 'pt'
          ? 'Erro no servidor. Tenta novamente mais tarde.'
          : 'Server error. Please try again later.';
    }

    // Default message
    return locale == 'pt'
        ? 'Algo correu mal. Tenta novamente.'
        : 'Something went wrong. Please try again.';
  }

  /// Sanitize an error message to remove sensitive information
  static String sanitizeErrorMessage(String message) {
    if (_containsSensitiveInfo(message)) {
      return 'An error occurred';
    }

    // Limit message length
    if (message.length > 200) {
      return 'An error occurred';
    }

    return message;
  }
}
