// lib/services/notification_service.dart

import 'package:flutter/material.dart';

/// Service for displaying consistent user notifications
///
/// Centralizes SnackBar creation to ensure consistent styling
/// and behavior across the application.
class NotificationService {
  /// Show a success notification
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    IconData icon = Icons.check_circle_outline,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green.shade600,
      icon: icon,
      duration: duration,
    );
  }

  /// Show an error notification
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    IconData icon = Icons.error_outline,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red.shade600,
      icon: icon,
      duration: duration,
    );
  }

  /// Show a warning notification
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    IconData icon = Icons.warning_amber_outlined,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange.shade600,
      icon: icon,
      duration: duration,
    );
  }

  /// Show an info notification
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    IconData icon = Icons.info_outline,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.blue.shade600,
      icon: icon,
      duration: duration,
    );
  }

  /// Internal method to create and show SnackBar
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Utility class for formatting error messages
class ErrorFormatter {
  /// Format an error for display to the user
  ///
  /// Truncates long messages and removes technical details
  static String format(dynamic error, {int maxLength = 100}) {
    final message = error.toString();

    // Remove common prefixes
    final cleanMessage = message
        .replaceAll('Exception: ', '')
        .replaceAll('Error: ', '')
        .replaceAll('PostgrestException: ', '')
        .replaceAll('AuthException: ', '');

    if (cleanMessage.length <= maxLength) {
      return cleanMessage;
    }

    return '${cleanMessage.substring(0, maxLength)}...';
  }

  /// Get a user-friendly error message based on error type
  static String getUserFriendlyMessage(
    dynamic error, {
    required String locale,
    String? fallbackMessage,
  }) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('not authenticated') || errorStr.contains('jwt')) {
      return locale == 'pt'
          ? 'Sessão expirada. Por favor, faça login novamente.'
          : 'Session expired. Please log in again.';
    }

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return locale == 'pt'
          ? 'Erro de ligação. Verifique a sua internet.'
          : 'Connection error. Check your internet.';
    }

    if (errorStr.contains('permission') || errorStr.contains('forbidden')) {
      return locale == 'pt'
          ? 'Não tem permissão para esta ação.'
          : 'You don\'t have permission for this action.';
    }

    return fallbackMessage ??
        (locale == 'pt'
            ? 'Ocorreu um erro. Tente novamente.'
            : 'An error occurred. Please try again.');
  }
}
