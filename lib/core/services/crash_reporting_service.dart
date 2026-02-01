import 'dart:async';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

/// Crash reporting service for capturing and reporting errors.
/// Uses Firebase Analytics for error tracking since Crashlytics
/// doesn't support web platform.
class CrashReportingService {
  static CrashReportingService? _instance;
  final AnalyticsService _analytics;

  CrashReportingService._internal(this._analytics);

  /// Get singleton instance
  static CrashReportingService get instance {
    _instance ??= CrashReportingService._internal(AnalyticsService.instance);
    return _instance!;
  }

  /// Initialize crash reporting
  static Future<void> initialize() async {
    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      instance.recordFlutterError(details);
    };

    // Set up async error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      instance.recordError(error, stack);
      return true;
    };
  }

  /// Record a Flutter framework error
  void recordFlutterError(FlutterErrorDetails details) {
    final exception = details.exception;
    final stack = details.stack;

    debugPrint('Flutter Error: $exception');
    if (stack != null) {
      debugPrint('Stack trace:\n$stack');
    }

    _analytics.logError(
      errorType: 'flutter_error',
      errorMessage: exception.toString(),
      stackTrace: stack?.toString(),
    );
  }

  /// Record a general error
  void recordError(Object error, StackTrace? stackTrace) {
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace:\n$stackTrace');
    }

    _analytics.logError(
      errorType: 'runtime_error',
      errorMessage: error.toString(),
      stackTrace: stackTrace?.toString(),
    );
  }

  /// Record a non-fatal error with custom message
  void recordNonFatalError({
    required String message,
    required String source,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('Non-fatal error in $source: $message');
    if (error != null) {
      debugPrint('Underlying error: $error');
    }

    _analytics.logError(
      errorType: 'non_fatal_$source',
      errorMessage: message,
      stackTrace: stackTrace?.toString(),
    );
  }

  /// Set user identifier for crash reports
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(userId);
  }

  /// Set custom key-value pair for crash context
  Future<void> setCustomKey(String key, String value) async {
    await _analytics.setUserProperty(name: key, value: value);
  }

  /// Log a message for crash context
  void log(String message) {
    debugPrint('[CrashReporting] $message');
  }
}

/// Run a zone with error handling
Future<T> runWithCrashReporting<T>(Future<T> Function() body) async {
  return runZonedGuarded(
    () async => await body(),
    (error, stack) {
      CrashReportingService.instance.recordError(error, stack);
    },
  ) as Future<T>;
}

/// Extension for easy error recording
extension CrashReportingExtension on Object {
  CrashReportingService get crashReporting => CrashReportingService.instance;
}
