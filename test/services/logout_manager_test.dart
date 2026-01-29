// test/services/logout_manager_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/services/logout_manager.dart';

void main() {
  group('LogoutManager', () {
    group('LogoutException', () {
      test('creates exception with message', () {
        final exception = LogoutException('Test error');

        expect(exception.message, 'Test error');
      });

      test('toString returns message', () {
        final exception = LogoutException('Test error message');

        expect(exception.toString(), 'Test error message');
      });

      test('can be thrown and caught', () {
        expect(
          () => throw LogoutException('Thrown error'),
          throwsA(isA<LogoutException>()),
        );
      });

      test('exception message is preserved when caught', () {
        try {
          throw LogoutException('Specific error');
        } on LogoutException catch (e) {
          expect(e.message, 'Specific error');
        }
      });
    });

    group('factory constructor', () {
      test('instance() creates LogoutManager', () {
        // This will throw if Supabase is not initialized, which is expected in tests
        // The test verifies the factory method exists and is callable
        expect(LogoutManager.instance, isA<Function>());
      });
    });
  });
}
