import 'failures.dart';

/// A Result type that represents either a success or a failure
/// Similar to Either<Failure, T> but more idiomatic for Dart
sealed class Result<T> {
  const Result();

  /// Factory constructor for success
  static Result<T> success<T>(T data) => Success(data);

  /// Factory constructor for failure
  static Result<T> fail<T>(Failure failure) => Fail(failure);

  /// Returns true if this is a success
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure
  bool get isFailure => this is Fail<T>;

  /// Gets the value if success, throws if failure
  T get value {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    throw StateError('Cannot get value from a Failure');
  }

  /// Gets the failure if failure, throws if success
  Failure get failure {
    if (this is Fail<T>) {
      return (this as Fail<T>).error;
    }
    throw StateError('Cannot get failure from a Success');
  }

  /// Gets the value or null
  T? get valueOrNull {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    return null;
  }

  /// Transforms the result using the provided functions
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else {
      return onFailure((this as Fail<T>).error);
    }
  }

  /// Maps the success value to a new type
  Result<R> map<R>(R Function(T data) mapper) {
    if (this is Success<T>) {
      return Success(mapper((this as Success<T>).data));
    } else {
      return Fail((this as Fail<T>).error);
    }
  }
}

/// Represents a successful result
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed result
class Fail<T> extends Result<T> {
  final Failure error;

  const Fail(this.error);

  @override
  String toString() => 'Fail($error)';
}
