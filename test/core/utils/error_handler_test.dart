import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    group('getUserFriendlyMessage - English', () {
      const locale = 'en';

      test('returns network error message for socket exceptions', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('SocketException: Connection refused'),
          locale,
        );
        expect(message, contains('internet'));
      });

      test('returns network error message for connection errors', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Connection failed'),
          locale,
        );
        expect(message, contains('internet'));
      });

      test('returns network error message for timeout errors', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Request timeout'),
          locale,
        );
        expect(message, contains('internet'));
      });

      test('returns auth error for invalid login', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Invalid login credentials'),
          locale,
        );
        expect(message, contains('Invalid email or password'));
      });

      test('returns auth error for invalid password', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Invalid password'),
          locale,
        );
        expect(message, contains('Invalid email or password'));
      });

      test('returns auth error for user not found', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('User not found'),
          locale,
        );
        expect(message, contains('Invalid email or password'));
      });

      test('returns email confirmation message', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Email not confirmed'),
          locale,
        );
        expect(message, contains('confirm your email'));
      });

      test('returns already registered message', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('User already registered'),
          locale,
        );
        expect(message, contains('already registered'));
      });

      test('returns rate limit message', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Too many requests'),
          locale,
        );
        expect(message, contains('Too many attempts'));
      });

      test('returns permission error message', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Permission denied'),
          locale,
        );
        expect(message, contains('permission'));
      });

      test('returns permission error for forbidden', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('403 Forbidden'),
          locale,
        );
        expect(message, contains('permission'));
      });

      test('returns server error message for 500 errors', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('500 Internal Server Error'),
          locale,
        );
        expect(message, contains('Server error'));
      });

      test('returns generic error for unknown errors', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Some random error'),
          locale,
        );
        expect(message, contains('Something went wrong'));
      });
    });

    group('getUserFriendlyMessage - Portuguese', () {
      const locale = 'pt';

      test('returns network error message in Portuguese', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('SocketException: Connection refused'),
          locale,
        );
        expect(message, contains('ligação'));
      });

      test('returns auth error in Portuguese', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Invalid login credentials'),
          locale,
        );
        expect(message, contains('incorretos'));
      });

      test('returns rate limit message in Portuguese', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Rate limit exceeded'),
          locale,
        );
        expect(message, contains('Demasiadas'));
      });

      test('returns server error in Portuguese', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Internal server error'),
          locale,
        );
        expect(message, contains('servidor'));
      });

      test('returns generic error in Portuguese', () {
        final message = ErrorHandler.getUserFriendlyMessage(
          Exception('Unknown error'),
          locale,
        );
        expect(message, contains('correu mal'));
      });
    });
  });
}
