import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/errors/result.dart';
import 'package:hckegg_lite/core/errors/failures.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('creates success result with value', () {
        const result = Success<int>(42);
        expect(result.data, 42);
        expect(result.isSuccess, true);
        expect(result.isFailure, false);
      });

      test('value getter returns data', () {
        const result = Success<int>(42);
        expect(result.value, 42);
      });

      test('valueOrNull returns data for success', () {
        const result = Success<String>('hello');
        expect(result.valueOrNull, 'hello');
      });

      test('map transforms success value', () {
        const result = Success<int>(10);
        final mapped = result.map((value) => value * 2);

        expect(mapped, isA<Success<int>>());
        expect((mapped as Success<int>).data, 20);
      });

      test('fold returns onSuccess result', () {
        const result = Success<int>(42);
        final folded = result.fold(
          onSuccess: (value) => 'Value: $value',
          onFailure: (failure) => 'Error: ${failure.message}',
        );

        expect(folded, 'Value: 42');
      });

      test('toString returns readable format', () {
        const result = Success<int>(42);
        expect(result.toString(), 'Success(42)');
      });
    });

    group('Fail', () {
      test('creates failure result with failure object', () {
        const failure = ServerFailure(message: 'Server error', code: '500');
        const result = Fail<int>(failure);

        expect(result.error, failure);
        expect(result.isSuccess, false);
        expect(result.isFailure, true);
      });

      test('failure getter returns error', () {
        const failure = ServerFailure(message: 'Error', code: '500');
        const result = Fail<int>(failure);
        expect(result.failure, failure);
      });

      test('valueOrNull returns null for failure', () {
        const failure = ServerFailure(message: 'Error', code: '500');
        const result = Fail<String>(failure);
        expect(result.valueOrNull, isNull);
      });

      test('map preserves failure', () {
        const failure = ServerFailure(message: 'Error', code: '500');
        const result = Fail<int>(failure);
        final mapped = result.map((value) => value * 2);

        expect(mapped, isA<Fail<int>>());
        expect((mapped as Fail<int>).error, failure);
      });

      test('fold returns onFailure result', () {
        const failure = ServerFailure(message: 'Server error', code: '500');
        const result = Fail<int>(failure);
        final folded = result.fold(
          onSuccess: (value) => 'Value: $value',
          onFailure: (f) => 'Error: ${f.message}',
        );

        expect(folded, 'Error: Server error');
      });

      test('toString returns readable format', () {
        const failure = ServerFailure(message: 'Error', code: '500');
        const result = Fail<int>(failure);
        expect(result.toString(), contains('Fail'));
      });
    });

    group('factory constructors', () {
      test('Result.success creates Success', () {
        final result = Result.success<int>(42);
        expect(result, isA<Success<int>>());
        expect(result.value, 42);
      });

      test('Result.fail creates Fail', () {
        const failure = ServerFailure(message: 'Error', code: '500');
        final result = Result.fail<int>(failure);
        expect(result, isA<Fail<int>>());
        expect(result.failure, failure);
      });
    });

    group('error cases', () {
      test('accessing value on failure throws StateError', () {
        const failure = ServerFailure(message: 'Error', code: '500');
        const result = Fail<int>(failure);
        expect(() => result.value, throwsStateError);
      });

      test('accessing failure on success throws StateError', () {
        const result = Success<int>(42);
        expect(() => result.failure, throwsStateError);
      });
    });
  });

  group('Failure types', () {
    test('ServerFailure has correct properties', () {
      const failure = ServerFailure(message: 'Server error', code: '500');
      expect(failure.message, 'Server error');
      expect(failure.code, '500');
    });

    test('AuthFailure has correct properties', () {
      const failure = AuthFailure(message: 'Unauthorized', code: '401');
      expect(failure.message, 'Unauthorized');
      expect(failure.code, '401');
    });

    test('ValidationFailure has correct properties', () {
      const failure = ValidationFailure(
        message: 'Invalid input',
        code: 'VALIDATION',
        fieldErrors: {'email': 'Invalid email'},
      );
      expect(failure.message, 'Invalid input');
      expect(failure.code, 'VALIDATION');
      expect(failure.fieldErrors, {'email': 'Invalid email'});
    });

    test('NotFoundFailure has correct properties', () {
      const failure = NotFoundFailure(message: 'Not found', code: '404');
      expect(failure.message, 'Not found');
      expect(failure.code, '404');
    });

    test('PermissionFailure has correct properties', () {
      const failure = PermissionFailure(message: 'Forbidden', code: '403');
      expect(failure.message, 'Forbidden');
      expect(failure.code, '403');
    });

    test('NetworkFailure has correct properties', () {
      const failure = NetworkFailure(message: 'No connection', code: 'NETWORK');
      expect(failure.message, 'No connection');
      expect(failure.code, 'NETWORK');
    });

    test('CacheFailure has correct properties', () {
      const failure = CacheFailure(message: 'Cache error', code: 'CACHE');
      expect(failure.message, 'Cache error');
      expect(failure.code, 'CACHE');
    });

    test('Failure toString includes message and code', () {
      const failure = ServerFailure(message: 'Error occurred', code: 'ERR001');
      expect(failure.toString(), contains('Error occurred'));
      expect(failure.toString(), contains('ERR001'));
    });

    test('Failure toString handles null code', () {
      const failure = ServerFailure(message: 'Error occurred');
      expect(failure.toString(), contains('Error occurred'));
    });
  });
}
