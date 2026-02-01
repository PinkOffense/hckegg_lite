import '../errors/result.dart';

/// Base use case interface
/// [Type] is the return type
/// [Params] is the parameters type
abstract class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

/// Use case with no parameters
abstract class UseCaseNoParams<Type> {
  Future<Result<Type>> call();
}

/// Parameters placeholder for no params
class NoParams {
  const NoParams();
}
