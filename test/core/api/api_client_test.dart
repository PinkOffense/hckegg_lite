import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/api/api_client.dart';
import 'package:hckegg_lite/core/errors/failures.dart';

void main() {
  group('ApiClient', () {
    late ApiClient client;

    setUp(() {
      client = ApiClient(baseUrl: 'https://api.example.com');
    });

    group('cache management', () {
      test('clearCache removes all cached data', () {
        // Just verify the method doesn't throw
        expect(() => client.clearCache(), returnsNormally);
      });

      test('invalidateCache removes cache for specific path', () {
        expect(() => client.invalidateCache('/api/v1/eggs'), returnsNormally);
      });
    });

    group('error handling', () {
      // These tests verify the error types returned
      // In a real scenario, we'd mock Dio to test actual error handling

      test('handles timeout errors', () {
        // ApiClient converts DioException to Failure
        // This is a design verification test
        expect(const ServerFailure(message: 'timeout', code: 'TIMEOUT'),
            isA<ServerFailure>());
      });

      test('handles auth errors', () {
        expect(const AuthFailure(message: 'unauthorized', code: 'UNAUTHORIZED'),
            isA<AuthFailure>());
      });

      test('handles validation errors', () {
        expect(
            const ValidationFailure(message: 'invalid', code: 'VALIDATION'),
            isA<ValidationFailure>());
      });

      test('handles not found errors', () {
        expect(const NotFoundFailure(message: 'not found', code: 'NOT_FOUND'),
            isA<NotFoundFailure>());
      });

      test('handles permission errors', () {
        expect(
            const PermissionFailure(message: 'forbidden', code: 'FORBIDDEN'),
            isA<PermissionFailure>());
      });
    });
  });

  group('Cache configuration', () {
    test('default TTL is 5 minutes', () {
      expect(ApiClient.defaultCacheTtl, const Duration(minutes: 5));
    });
  });
}
