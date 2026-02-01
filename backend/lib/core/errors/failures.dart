import 'package:equatable/equatable.dart';

/// Base failure class for all failures in the application
abstract class Failure extends Equatable {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Server-side failure (database, network, etc.)
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Validation failure (invalid input)
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.code});
}

/// Permission denied failure
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}
