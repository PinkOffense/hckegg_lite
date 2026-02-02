/// Base class for all failures in the application
abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => 'Failure: $message${code != null ? ' (code: $code)' : ''}';
}

/// Server-side failure (API errors, network issues)
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Cache/local storage failure
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Validation failure (invalid input)
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code,
    this.fieldErrors,
  });
}

/// Not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.code});
}

/// Permission denied failure
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

/// Network failure (connectivity issues)
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}
