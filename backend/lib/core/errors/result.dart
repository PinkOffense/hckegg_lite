import 'failures.dart';

/// Result type for handling success/failure states
/// Similar to Either in functional programming
sealed class Result<T> {
  const Result();

  /// Create a success result
  factory Result.success(T value) = Success<T>;

  /// Create a failure result
  factory Result.failure(Failure failure) = Fail<T>;

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Fail<T>;

  /// Get value or null
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Fail() => null,
      };

  /// Get failure or null
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        Fail(:final failure) => failure,
      };

  /// Fold pattern - handle both cases
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Fail(:final failure) => onFailure(failure),
    };
  }

  /// Map success value
  Result<R> map<R>(R Function(T value) mapper) {
    return switch (this) {
      Success(:final value) => Result.success(mapper(value)),
      Fail(:final failure) => Result.failure(failure),
    };
  }

  /// FlatMap for chaining results
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return switch (this) {
      Success(:final value) => mapper(value),
      Fail(:final failure) => Result.failure(failure),
    };
  }
}

/// Success result
final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

/// Failure result
final class Fail<T> extends Result<T> {
  const Fail(this.failure);
  final Failure failure;
}
