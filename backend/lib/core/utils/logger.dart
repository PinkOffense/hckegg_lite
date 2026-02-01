import 'dart:io';

/// Log levels
enum LogLevel { debug, info, warning, error }

/// Simple structured logger for the backend
class Logger {
  static LogLevel _minLevel = LogLevel.info;
  static bool _includeTimestamp = true;

  /// Configure the logger
  static void configure({
    LogLevel? minLevel,
    bool? includeTimestamp,
  }) {
    if (minLevel != null) _minLevel = minLevel;
    if (includeTimestamp != null) _includeTimestamp = includeTimestamp;
  }

  /// Set minimum log level from environment
  static void configureFromEnvironment() {
    final level = Platform.environment['LOG_LEVEL']?.toLowerCase();
    switch (level) {
      case 'debug':
        _minLevel = LogLevel.debug;
        break;
      case 'info':
        _minLevel = LogLevel.info;
        break;
      case 'warning':
        _minLevel = LogLevel.warning;
        break;
      case 'error':
        _minLevel = LogLevel.error;
        break;
    }
  }

  static void _log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    if (level.index < _minLevel.index) return;

    final buffer = StringBuffer();

    if (_includeTimestamp) {
      buffer.write('[${DateTime.now().toIso8601String()}] ');
    }

    buffer.write('[${level.name.toUpperCase()}] ');
    buffer.write(message);

    if (error != null) {
      buffer.write(' | Error: $error');
    }

    final output = buffer.toString();

    if (level == LogLevel.error) {
      stderr.writeln(output);
      if (stackTrace != null) {
        stderr.writeln(stackTrace);
      }
    } else {
      stdout.writeln(output);
    }
  }

  /// Log debug message
  static void debug(String message) => _log(LogLevel.debug, message);

  /// Log info message
  static void info(String message) => _log(LogLevel.info, message);

  /// Log warning message
  static void warning(String message, [Object? error]) =>
      _log(LogLevel.warning, message, error);

  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, message, error, stackTrace);

  /// Log HTTP request
  static void request(String method, String path, {int? statusCode, int? durationMs}) {
    final status = statusCode != null ? ' -> $statusCode' : '';
    final duration = durationMs != null ? ' (${durationMs}ms)' : '';
    info('$method $path$status$duration');
  }

  /// Log authentication event
  static void auth(String event, {String? userId, bool success = true}) {
    final status = success ? 'SUCCESS' : 'FAILED';
    final user = userId != null ? ' [user: $userId]' : '';
    info('AUTH $event $status$user');
  }

  /// Log database operation
  static void db(String operation, String table, {int? rowsAffected, int? durationMs}) {
    final rows = rowsAffected != null ? ' ($rowsAffected rows)' : '';
    final duration = durationMs != null ? ' (${durationMs}ms)' : '';
    debug('DB $operation on $table$rows$duration');
  }
}
