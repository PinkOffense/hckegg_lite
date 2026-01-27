// lib/core/exceptions.dart

/// Base exception for all app-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception for database/storage operations
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});

  factory DatabaseException.fromError(dynamic error) {
    if (error is DatabaseException) return error;

    final message = error?.toString() ?? 'Unknown database error';

    // Handle Supabase PostgrestException
    if (error.runtimeType.toString().contains('PostgrestException')) {
      return DatabaseException(
        'Database error: $message',
        code: 'POSTGREST_ERROR',
        originalError: error,
      );
    }

    return DatabaseException(message, originalError: error);
  }

  @override
  String toString() => 'DatabaseException: $message';
}

/// Exception for network operations
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    this.statusCode,
  });

  factory NetworkException.timeout() => const NetworkException(
        'Connection timed out. Please check your internet connection.',
        code: 'TIMEOUT',
      );

  factory NetworkException.noConnection() => const NetworkException(
        'No internet connection available.',
        code: 'NO_CONNECTION',
      );

  factory NetworkException.serverError([int? statusCode]) => NetworkException(
        'Server error occurred. Please try again later.',
        code: 'SERVER_ERROR',
        statusCode: statusCode,
      );

  @override
  String toString() =>
      'NetworkException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}

/// Exception for authentication operations
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});

  factory AuthException.invalidCredentials() => const AuthException(
        'Invalid email or password.',
        code: 'INVALID_CREDENTIALS',
      );

  factory AuthException.userNotFound() => const AuthException(
        'User not found.',
        code: 'USER_NOT_FOUND',
      );

  factory AuthException.sessionExpired() => const AuthException(
        'Your session has expired. Please login again.',
        code: 'SESSION_EXPIRED',
      );

  factory AuthException.unauthorized() => const AuthException(
        'You are not authorized to perform this action.',
        code: 'UNAUTHORIZED',
      );

  @override
  String toString() => 'AuthException: $message';
}

/// Exception for data validation/parsing errors
class ValidationException extends AppException {
  final String? field;

  const ValidationException(
    super.message, {
    super.code,
    super.originalError,
    this.field,
  });

  factory ValidationException.required(String fieldName) => ValidationException(
        '$fieldName is required.',
        code: 'REQUIRED',
        field: fieldName,
      );

  factory ValidationException.invalidFormat(String fieldName, [String? expected]) =>
      ValidationException(
        '$fieldName has invalid format${expected != null ? '. Expected: $expected' : ''}.',
        code: 'INVALID_FORMAT',
        field: fieldName,
      );

  factory ValidationException.outOfRange(
    String fieldName, {
    num? min,
    num? max,
  }) {
    String range = '';
    if (min != null && max != null) {
      range = ' (must be between $min and $max)';
    } else if (min != null) {
      range = ' (must be at least $min)';
    } else if (max != null) {
      range = ' (must be at most $max)';
    }
    return ValidationException(
      '$fieldName is out of range$range.',
      code: 'OUT_OF_RANGE',
      field: fieldName,
    );
  }

  factory ValidationException.parseError(String fieldName, dynamic value) =>
      ValidationException(
        'Failed to parse $fieldName: ${value?.toString() ?? 'null'}',
        code: 'PARSE_ERROR',
        field: fieldName,
      );

  @override
  String toString() =>
      'ValidationException: $message${field != null ? ' (field: $field)' : ''}';
}

/// Exception for business logic errors
class BusinessException extends AppException {
  const BusinessException(super.message, {super.code, super.originalError});

  factory BusinessException.notFound(String entity) => BusinessException(
        '$entity not found.',
        code: 'NOT_FOUND',
      );

  factory BusinessException.alreadyExists(String entity) => BusinessException(
        '$entity already exists.',
        code: 'ALREADY_EXISTS',
      );

  factory BusinessException.insufficientStock(String item) => BusinessException(
        'Insufficient stock for $item.',
        code: 'INSUFFICIENT_STOCK',
      );

  @override
  String toString() => 'BusinessException: $message';
}
