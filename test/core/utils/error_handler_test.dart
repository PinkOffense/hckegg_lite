import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    group('getUserFriendlyMessage - English', () {
      const locale = 'en';

      test('returns network error message for socket issues', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'SocketError: Connection refused',
          locale,
        );
        expect(message, contains('internet'));
      });

      test('returns network error message for connection errors', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Connection failed',
          locale,
        );
        expect(message, contains('internet'));
      });

      test('returns network error message for timeout errors', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Request timeout',
          locale,
        );
        expect(message, contains('internet'));
      });

      test('returns auth error for invalid login', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Invalid login credentials',
          locale,
        );
        expect(message, contains('Invalid email or password'));
      });

      test('returns auth error for invalid password', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Invalid password provided',
          locale,
        );
        expect(message, contains('Invalid email or password'));
      });

      test('returns auth error for user not found', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'User not found',
          locale,
        );
        expect(message, contains('Invalid email or password'));
      });

      test('returns email confirmation message', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Email not confirmed',
          locale,
        );
        expect(message, contains('confirm your email'));
      });

      test('returns already registered message', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'User already registered',
          locale,
        );
        expect(message, contains('already registered'));
      });

      test('returns rate limit message', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Too many requests',
          locale,
        );
        expect(message, contains('Too many attempts'));
      });

      test('returns permission error message', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Permission denied',
          locale,
        );
        expect(message, contains('permission'));
      });

      test('returns permission error for forbidden', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          '403 Forbidden',
          locale,
        );
        expect(message, contains('permission'));
      });

      test('returns server error message for 500 errors', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          '500 Internal Server Error',
          locale,
        );
        expect(message, contains('Server error'));
      });

      test('returns generic error for unknown errors', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Some random error',
          locale,
        );
        expect(message, contains('Something went wrong'));
      });

      test('sanitizes sensitive database info', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'SQL syntax error near SELECT',
          locale,
        );
        expect(message, contains('error occurred'));
      });

      test('sanitizes sensitive stack trace info', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Error at line 42 in file.dart:123',
          locale,
        );
        expect(message, contains('error occurred'));
      });
    });

    group('getUserFriendlyMessage - Portuguese', () {
      const locale = 'pt';

      test('returns network error message in Portuguese', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'SocketError: Connection refused',
          locale,
        );
        expect(message, contains('ligação'));
      });

      test('returns auth error in Portuguese', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Invalid login credentials',
          locale,
        );
        expect(message, contains('incorretos'));
      });

      test('returns rate limit message in Portuguese', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Rate limit exceeded',
          locale,
        );
        expect(message, contains('Demasiadas'));
      });

      test('returns server error in Portuguese', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Internal server error',
          locale,
        );
        expect(message, contains('servidor'));
      });

      test('returns generic error in Portuguese', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          'Unknown error',
          locale,
        );
        expect(message, contains('correu mal'));
      });
    });

    group('sanitizeErrorMessage', () {
      test('returns message if safe', () {
        final result = ErrorHandler.sanitizeErrorMessage('Simple error');
        expect(result, 'Simple error');
      });

      test('sanitizes SQL keywords', () {
        final result = ErrorHandler.sanitizeErrorMessage('SQL syntax error');
        expect(result, 'An error occurred');
      });

      test('sanitizes long messages', () {
        final longMessage = 'A' * 250;
        final result = ErrorHandler.sanitizeErrorMessage(longMessage);
        expect(result, 'An error occurred');
      });
    });
  });
}
