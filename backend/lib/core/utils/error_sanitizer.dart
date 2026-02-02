// backend/lib/core/utils/error_sanitizer.dart

/// Utility class for sanitizing error messages before sending to clients
/// Prevents exposure of sensitive information like:
/// - Database details
/// - Stack traces
/// - Internal paths
/// - SQL queries
class ErrorSanitizer {
  /// Patterns that indicate sensitive information
  static final List<RegExp> _sensitivePatterns = [
    // SQL/Database related
    RegExp(r'sql', caseSensitive: false),
    RegExp(r'postgres', caseSensitive: false),
    RegExp(r'supabase', caseSensitive: false),
    RegExp(r'database', caseSensitive: false),
    RegExp(r'query', caseSensitive: false),
    RegExp(r'table\s', caseSensitive: false),
    RegExp(r'column\s', caseSensitive: false),
    RegExp(r'constraint', caseSensitive: false),
    RegExp(r'foreign\s*key', caseSensitive: false),
    RegExp(r'primary\s*key', caseSensitive: false),

    // Programming related
    RegExp(r'exception', caseSensitive: false),
    RegExp(r'stack\s*trace', caseSensitive: false),
    RegExp(r'null\s*pointer', caseSensitive: false),
    RegExp(r'undefined', caseSensitive: false),
    RegExp(r'\.dart:', caseSensitive: false),
    RegExp(r'\.js:', caseSensitive: false),
    RegExp(r'at\s+line\s+\d+', caseSensitive: false),
    RegExp(r'at\s+\w+\.\w+\s*\(', caseSensitive: false),

    // File paths
    RegExp(r'/[a-z]+/[a-z]+/', caseSensitive: false),
    RegExp(r'\\[a-z]+\\[a-z]+\\', caseSensitive: false),
    RegExp(r'file://', caseSensitive: false),

    // Internal errors
    RegExp(r'internal\s*error', caseSensitive: false),
    RegExp(r'internal\s*server', caseSensitive: false),
    RegExp(r'unhandled', caseSensitive: false),

    // Connection strings
    RegExp(r'connection\s*string', caseSensitive: false),
    RegExp(r'api[_-]?key', caseSensitive: false),
    RegExp(r'secret', caseSensitive: false),
    RegExp(r'password', caseSensitive: false),
    RegExp(r'token', caseSensitive: false),
  ];

  /// Maximum allowed message length
  static const int _maxMessageLength = 200;

  /// Default fallback messages
  static const Map<int, String> _defaultMessages = {
    400: 'Invalid request. Please check your input.',
    401: 'Authentication required. Please log in.',
    403: 'You do not have permission to perform this action.',
    404: 'The requested resource was not found.',
    409: 'A conflict occurred. The resource may already exist.',
    422: 'Validation error. Please check your input.',
    429: 'Too many requests. Please try again later.',
    500: 'An unexpected error occurred. Please try again later.',
    502: 'Service temporarily unavailable. Please try again later.',
    503: 'Service temporarily unavailable. Please try again later.',
  };

  /// Sanitize an error message
  /// Returns a safe message that doesn't expose sensitive information
  static String sanitize(String? message, {int? statusCode}) {
    final fallback = _defaultMessages[statusCode] ??
        _defaultMessages[500]!;

    if (message == null || message.isEmpty) {
      return fallback;
    }

    // Check for sensitive patterns
    for (final pattern in _sensitivePatterns) {
      if (pattern.hasMatch(message)) {
        return fallback;
      }
    }

    // Check message length
    if (message.length > _maxMessageLength) {
      return fallback;
    }

    // Remove any potential HTML/script injection
    final cleaned = message
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&[a-z]+;', caseSensitive: false), '')
        .trim();

    if (cleaned.isEmpty) {
      return fallback;
    }

    return cleaned;
  }

  /// Get a safe error response body
  static Map<String, dynamic> getSafeErrorBody({
    required String rawMessage,
    required int statusCode,
    String? errorCode,
  }) {
    return {
      'error': sanitize(rawMessage, statusCode: statusCode),
      if (errorCode != null) 'code': errorCode,
    };
  }

  /// Check if a message contains sensitive information
  static bool containsSensitiveInfo(String message) {
    for (final pattern in _sensitivePatterns) {
      if (pattern.hasMatch(message)) {
        return true;
      }
    }
    return false;
  }
}
