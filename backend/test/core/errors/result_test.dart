import 'package:test/test.dart';
import 'package:hckegg_api/core/core.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success result with value', () {
        final result = Result.success(42);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.valueOrNull, 42);
        expect(result.failureOrNull, isNull);
      });

      test('should fold to success branch', () {
        final result = Result.success('hello');

        final folded = result.fold(
          onSuccess: (value) => 'success: $value',
          onFailure: (failure) => 'failure: ${failure.message}',
        );

        expect(folded, 'success: hello');
      });

      test('should map value correctly', () {
        final result = Result.success(10);
        final mapped = result.map((value) => value * 2);

        expect(mapped.isSuccess, isTrue);
        expect(mapped.valueOrNull, 20);
      });

      test('should flatMap to new result', () {
        final result = Result.success(5);
        final flatMapped = result.flatMap((value) => Result.success(value + 10));

        expect(flatMapped.isSuccess, isTrue);
        expect(flatMapped.valueOrNull, 15);
      });
    });

    group('Failure', () {
      test('should create failure result with failure', () {
        const failure = ServerFailure(message: 'Error');
        final result = Result<int>.failure(failure);

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.valueOrNull, isNull);
        expect(result.failureOrNull, failure);
      });

      test('should fold to failure branch', () {
        const failure = ServerFailure(message: 'Network error');
        final result = Result<String>.failure(failure);

        final folded = result.fold(
          onSuccess: (value) => 'success: $value',
          onFailure: (f) => 'failure: ${f.message}',
        );

        expect(folded, 'failure: Network error');
      });

      test('should propagate failure on map', () {
        const failure = ServerFailure(message: 'Error');
        final result = Result<int>.failure(failure);
        final mapped = result.map((value) => value * 2);

        expect(mapped.isFailure, isTrue);
        expect(mapped.failureOrNull?.message, 'Error');
      });

      test('should propagate failure on flatMap', () {
        const failure = ServerFailure(message: 'Error');
        final result = Result<int>.failure(failure);
        final flatMapped = result.flatMap((value) => Result.success(value + 10));

        expect(flatMapped.isFailure, isTrue);
        expect(flatMapped.failureOrNull?.message, 'Error');
      });
    });
  });

  group('Failure types', () {
    test('ServerFailure should have correct properties', () {
      const failure = ServerFailure(message: 'Server error', code: '500');

      expect(failure.message, 'Server error');
      expect(failure.code, '500');
      expect(failure.props, ['Server error', '500']);
    });

    test('ValidationFailure should have correct properties', () {
      const failure = ValidationFailure(message: 'Invalid input');

      expect(failure.message, 'Invalid input');
      expect(failure.code, isNull);
    });

    test('NotFoundFailure should have correct properties', () {
      const failure = NotFoundFailure(message: 'Resource not found');

      expect(failure.message, 'Resource not found');
    });

    test('AuthFailure should have correct properties', () {
      const failure = AuthFailure(message: 'Unauthorized');

      expect(failure.message, 'Unauthorized');
    });

    test('PermissionFailure should have correct properties', () {
      const failure = PermissionFailure(message: 'Access denied');

      expect(failure.message, 'Access denied');
    });

    test('Failures with same properties should be equal', () {
      const failure1 = ServerFailure(message: 'Error', code: '500');
      const failure2 = ServerFailure(message: 'Error', code: '500');

      expect(failure1, equals(failure2));
    });
  });
}
