import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('isValidEmail', () {
      test('returns true for valid emails', () {
        expect(Validators.isValidEmail('test@example.com'), true);
        expect(Validators.isValidEmail('user.name@domain.org'), true);
        expect(Validators.isValidEmail('user+tag@example.com'), true);
      });

      test('returns false for invalid emails', () {
        expect(Validators.isValidEmail('invalid'), false);
        expect(Validators.isValidEmail('test@'), false);
        expect(Validators.isValidEmail('@example.com'), false);
        expect(Validators.isValidEmail('test@.com'), false);
      });

      test('returns true for null or empty (optional field)', () {
        expect(Validators.isValidEmail(null), true);
        expect(Validators.isValidEmail(''), true);
      });

      test('returns false for email exceeding max length', () {
        final longEmail = '${'a' * 250}@test.com';
        expect(Validators.isValidEmail(longEmail), false);
      });
    });

    group('isValidPhone', () {
      test('returns true for valid phone numbers', () {
        expect(Validators.isValidPhone('123456789'), true);
        expect(Validators.isValidPhone('+351 912 345 678'), true);
        expect(Validators.isValidPhone('(555) 123-4567'), true);
      });

      test('returns false for invalid phone numbers', () {
        expect(Validators.isValidPhone('abc'), false);
        expect(Validators.isValidPhone('12'), false); // too short
      });

      test('returns true for null or empty (optional field)', () {
        expect(Validators.isValidPhone(null), true);
        expect(Validators.isValidPhone(''), true);
      });
    });

    group('isNonNegativeInt', () {
      test('returns true for non-negative integers', () {
        expect(Validators.isNonNegativeInt('0'), true);
        expect(Validators.isNonNegativeInt('1'), true);
        expect(Validators.isNonNegativeInt('100'), true);
      });

      test('returns false for negative integers', () {
        expect(Validators.isNonNegativeInt('-1'), false);
        expect(Validators.isNonNegativeInt('-100'), false);
      });

      test('returns false for non-integers', () {
        expect(Validators.isNonNegativeInt('abc'), false);
        expect(Validators.isNonNegativeInt('1.5'), false);
        expect(Validators.isNonNegativeInt(null), false);
        expect(Validators.isNonNegativeInt(''), false);
      });
    });

    group('isPositiveInt', () {
      test('returns true for positive integers', () {
        expect(Validators.isPositiveInt('1'), true);
        expect(Validators.isPositiveInt('100'), true);
      });

      test('returns false for zero or negative', () {
        expect(Validators.isPositiveInt('0'), false);
        expect(Validators.isPositiveInt('-1'), false);
      });
    });

    group('isPositiveNumber', () {
      test('returns true for positive numbers', () {
        expect(Validators.isPositiveNumber('1'), true);
        expect(Validators.isPositiveNumber('0.5'), true);
        expect(Validators.isPositiveNumber('100.99'), true);
      });

      test('returns false for zero or negative', () {
        expect(Validators.isPositiveNumber('0'), false);
        expect(Validators.isPositiveNumber('-1'), false);
        expect(Validators.isPositiveNumber('-0.5'), false);
      });
    });

    group('maxLength', () {
      test('returns true when within limit', () {
        expect(Validators.maxLength('hello', 10), true);
        expect(Validators.maxLength('hello', 5), true);
        expect(Validators.maxLength(null, 10), true);
      });

      test('returns false when exceeding limit', () {
        expect(Validators.maxLength('hello world', 5), false);
      });
    });

    group('isNotEmpty', () {
      test('returns true for non-empty strings', () {
        expect(Validators.isNotEmpty('hello'), true);
        expect(Validators.isNotEmpty(' hello '), true);
      });

      test('returns false for empty or whitespace-only', () {
        expect(Validators.isNotEmpty(''), false);
        expect(Validators.isNotEmpty('   '), false);
        expect(Validators.isNotEmpty(null), false);
      });
    });
  });

  group('FormValidators', () {
    group('required', () {
      test('returns null for non-empty values', () {
        final validator = FormValidators.required(locale: 'en');
        expect(validator('hello'), null);
        expect(validator('test'), null);
      });

      test('returns error message for empty values', () {
        final validatorEn = FormValidators.required(locale: 'en');
        final validatorPt = FormValidators.required(locale: 'pt');

        expect(validatorEn(''), 'Required field');
        expect(validatorEn(null), 'Required field');
        expect(validatorEn('   '), 'Required field');

        expect(validatorPt(''), 'Campo obrigatório');
      });
    });

    group('positiveInt', () {
      test('returns null for positive integers', () {
        final validator = FormValidators.positiveInt(locale: 'en');
        expect(validator('1'), null);
        expect(validator('100'), null);
      });

      test('returns error for invalid values', () {
        final validator = FormValidators.positiveInt(locale: 'en');
        expect(validator('0'), isNotNull);
        expect(validator('-1'), isNotNull);
        expect(validator('abc'), isNotNull);
        expect(validator(''), isNotNull);
      });

      test('respects required flag', () {
        final optionalValidator = FormValidators.positiveInt(required: false, locale: 'en');
        expect(optionalValidator(''), null);
        expect(optionalValidator(null), null);
      });
    });

    group('positiveNumber', () {
      test('returns null for positive numbers', () {
        final validator = FormValidators.positiveNumber(locale: 'en');
        expect(validator('1'), null);
        expect(validator('0.5'), null);
        expect(validator('99.99'), null);
      });

      test('returns error for invalid values', () {
        final validator = FormValidators.positiveNumber(locale: 'en');
        expect(validator('0'), isNotNull);
        expect(validator('-1'), isNotNull);
        expect(validator('abc'), isNotNull);
      });
    });

    group('email', () {
      test('returns null for valid or empty emails', () {
        final validator = FormValidators.email(locale: 'en');
        expect(validator('test@example.com'), null);
        expect(validator(''), null);
        expect(validator(null), null);
      });

      test('returns error for invalid emails', () {
        final validator = FormValidators.email(locale: 'en');
        expect(validator('invalid'), isNotNull);
      });
    });

    group('phone', () {
      test('returns null for valid or empty phones', () {
        final validator = FormValidators.phone(locale: 'en');
        expect(validator('+351912345678'), null);
        expect(validator(''), null);
        expect(validator(null), null);
      });

      test('returns error for invalid phones', () {
        final validator = FormValidators.phone(locale: 'en');
        expect(validator('ab'), isNotNull);
      });
    });

    group('maxLength', () {
      test('returns null when within limit', () {
        final validator = FormValidators.maxLength(10, locale: 'en');
        expect(validator('hello'), null);
        expect(validator(null), null);
      });

      test('returns error when exceeding limit', () {
        final validator = FormValidators.maxLength(5, locale: 'en');
        expect(validator('hello world'), isNotNull);
      });
    });

    group('combine', () {
      test('runs all validators and returns first error', () {
        final validator = FormValidators.combine([
          FormValidators.required(locale: 'en'),
          FormValidators.maxLength(5, locale: 'en'),
        ]);

        expect(validator('hi'), null);
        expect(validator(''), 'Required field');
        expect(validator('hello world'), isNotNull);
      });
    });

    group('consumedNotExceedCollected', () {
      test('returns null when consumed <= collected', () {
        final validator = FormValidators.consumedNotExceedCollected(
          collectedEggs: 10,
          locale: 'en',
        );
        expect(validator('0'), null);
        expect(validator('5'), null);
        expect(validator('10'), null);
      });

      test('returns error when consumed > collected', () {
        final validator = FormValidators.consumedNotExceedCollected(
          collectedEggs: 10,
          locale: 'en',
        );
        expect(validator('11'), isNotNull);
        expect(validator('15'), isNotNull);
      });

      test('returns error for negative values', () {
        final validator = FormValidators.consumedNotExceedCollected(
          collectedEggs: 10,
          locale: 'en',
        );
        expect(validator('-1'), isNotNull);
      });
    });

    group('intRange', () {
      test('returns null when within range', () {
        final validator = FormValidators.intRange(min: 1, max: 100, locale: 'en');
        expect(validator('1'), null);
        expect(validator('50'), null);
        expect(validator('100'), null);
      });

      test('returns error when outside range', () {
        final validator = FormValidators.intRange(min: 1, max: 100, locale: 'en');
        expect(validator('0'), isNotNull);
        expect(validator('101'), isNotNull);
      });
    });
  });
}
