import '../errors/result.dart';

/// Base class for all use cases
///
/// Type [T] is the return type
/// Type [Params] is the parameters type (use [NoParams] if none needed)
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Use this when the use case doesn't need any parameters
class NoParams {
  const NoParams();
}

/// Base class for stream-based use cases (real-time data)
abstract class StreamUseCase<T, Params> {
  Stream<Result<T>> call(Params params);
}
