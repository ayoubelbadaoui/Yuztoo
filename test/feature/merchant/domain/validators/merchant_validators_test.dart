import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/validators/merchant_validators.dart';

void main() {
  group('validateAndTrimString', () {
    test('should return null for valid required string', () {
      final result = validateAndTrimString('Test', 'Field', isRequired: true);
      expect(result, isNull);
    });

    test('should return null for valid optional string', () {
      final result = validateAndTrimString('Test', 'Field', isRequired: false);
      expect(result, isNull);
    });

    test('should return error for null required string', () {
      final result = validateAndTrimString(null, 'Field', isRequired: true);
      expect(result, contains('Field is required'));
    });

    test('should return null for null optional string', () {
      final result = validateAndTrimString(null, 'Field', isRequired: false);
      expect(result, isNull);
    });

    test('should return error for empty required string', () {
      final result = validateAndTrimString('', 'Field', isRequired: true);
      expect(result, contains('Field is required'));
    });

    test('should return null for empty optional string', () {
      final result = validateAndTrimString('', 'Field', isRequired: false);
      expect(result, isNull);
    });

    test('should return error for whitespace-only required string', () {
      final result = validateAndTrimString('   ', 'Field', isRequired: true);
      expect(result, contains('Field is required'));
    });

    test('should return null for whitespace-only optional string when not allowed', () {
      // When optional and whitespace-only, it's treated as empty (valid)
      final result = validateAndTrimString('   ', 'Field',
          isRequired: false, allowWhitespaceOnly: false);
      expect(result, isNull);
    });

    test('should return null for whitespace-only when allowed', () {
      final result = validateAndTrimString('   ', 'Field',
          isRequired: false, allowWhitespaceOnly: true);
      expect(result, isNull);
    });

    test('should return error when string exceeds max length', () {
      final result = validateAndTrimString(
        'A' * 201,
        'Field',
        isRequired: true,
        maxLength: 200,
      );
      expect(result, contains('200 characters'));
    });

    test('should return null when string is at max length', () {
      final result = validateAndTrimString(
        'A' * 200,
        'Field',
        isRequired: true,
        maxLength: 200,
      );
      expect(result, isNull);
    });

    test('should trim whitespace from string', () {
      final result = validateAndTrimString('  Test  ', 'Field', isRequired: true);
      expect(result, isNull); // Should be valid after trimming
    });
  });

  group('validateEmail', () {
    test('should return null for valid email', () {
      expect(validateEmail('test@example.com'), isNull);
      expect(validateEmail('user.name@example.co.uk'), isNull);
      expect(validateEmail('user+tag@example.com'), isNull);
    });

    test('should return error for null email', () {
      final result = validateEmail(null);
      expect(result, contains('Email is required'));
    });

    test('should return error for empty email', () {
      final result = validateEmail('');
      expect(result, contains('Email is required'));
    });

    test('should return error for whitespace-only email', () {
      final result = validateEmail('   ');
      expect(result, contains('Email is required'));
    });

    test('should return error for invalid email format', () {
      expect(validateEmail('invalid'), contains('Invalid email format'));
      expect(validateEmail('invalid@'), contains('Invalid email format'));
      expect(validateEmail('@example.com'), contains('Invalid email format'));
      expect(validateEmail('user@domain'), contains('Invalid email format'));
    });

    test('should return error when email exceeds max length', () {
      final longEmail = 'a' * 250 + '@example.com';
      final result = validateEmail(longEmail);
      expect(result, contains('254 characters'));
    });

    test('should trim whitespace from email', () {
      final result = validateEmail('  test@example.com  ');
      expect(result, isNull); // Should be valid after trimming
    });
  });

  group('validatePhone', () {
    test('should return null for valid phone with country code', () {
      expect(validatePhone('+33612345678'), isNull);
      expect(validatePhone('+33123456789'), isNull);
      expect(validatePhone('+1234567890'), isNull);
    });

    test('should return null for valid local phone', () {
      expect(validatePhone('0612345678'), isNull);
      expect(validatePhone('1234567890'), isNull);
    });

    test('should return null for phone with formatting', () {
      expect(validatePhone('+33 6 12 34 56 78'), isNull);
      expect(validatePhone('(06) 12-34-56-78'), isNull);
    });

    test('should return error for null phone', () {
      final result = validatePhone(null);
      expect(result, contains('Phone number is required'));
    });

    test('should return error for empty phone', () {
      final result = validatePhone('');
      expect(result, contains('Phone number is required'));
    });

    test('should return error for whitespace-only phone', () {
      final result = validatePhone('   ');
      expect(result, contains('Phone number is required'));
    });

    test('should return error for phone with letters', () {
      final result = validatePhone('+33ABC123456');
      expect(result, contains('digits'));
    });

    test('should return error for phone too short', () {
      final result = validatePhone('+33123');
      expect(result, contains('7-15 digits'));
    });

    test('should return error for phone too long', () {
      // Phone exceeds max length (20 chars), so it fails length check first
      final result = validatePhone('+33' + '1' * 20);
      expect(result, contains('20 characters'));
    });

    test('should return error when phone exceeds max length', () {
      final longPhone = '+' + '1' * 25;
      final result = validatePhone(longPhone);
      expect(result, contains('20 characters'));
    });

    test('should trim whitespace from phone', () {
      final result = validatePhone('  +33612345678  ');
      expect(result, isNull); // Should be valid after trimming
    });
  });

  group('sanitizeString', () {
    test('should escape HTML special characters', () {
      expect(sanitizeString('<script>'), '&lt;script&gt;');
      expect(sanitizeString('&amp;'), '&amp;amp;');
      expect(sanitizeString('"quote"'), '&quot;quote&quot;');
      expect(sanitizeString("'apostrophe'"), '&#x27;apostrophe&#x27;');
    });

    test('should remove control characters', () {
      expect(sanitizeString('test\x00test'), 'testtest');
      expect(sanitizeString('test\x08test'), 'testtest');
    });

    test('should remove zero-width characters', () {
      expect(sanitizeString('test\u200Btest'), 'testtest');
      expect(sanitizeString('test\u200Ctest'), 'testtest');
    });

    test('should preserve normal characters', () {
      expect(sanitizeString('Hello World'), 'Hello World');
      expect(sanitizeString('123'), '123');
    });

    test('should handle emojis', () {
      final result = sanitizeString('Hello 😀 World');
      expect(result, contains('Hello'));
      expect(result, contains('World'));
    });

    test('should handle Unicode characters', () {
      final result = sanitizeString('Café');
      expect(result, contains('Café'));
    });
  });

  group('sanitizeMultilineString', () {
    test('should preserve newlines', () {
      final input = 'Line 1\nLine 2\nLine 3';
      final result = sanitizeMultilineString(input);
      expect(result, contains('\n'));
    });

    test('should preserve tabs', () {
      final input = 'Line 1\tTabbed';
      final result = sanitizeMultilineString(input);
      expect(result, contains('\t'));
    });

    test('should escape HTML special characters', () {
      expect(sanitizeMultilineString('<script>'), '&lt;script&gt;');
      expect(sanitizeMultilineString('&amp;'), '&amp;amp;');
    });

    test('should remove control characters except newlines and tabs', () {
      expect(sanitizeMultilineString('test\x00test'), 'testtest');
      expect(sanitizeMultilineString('test\n\x00test'), contains('\n'));
    });

    test('should remove zero-width characters', () {
      expect(sanitizeMultilineString('test\u200Btest'), 'testtest');
    });
  });

  group('validateCategories', () {
    test('should return null for null categories', () {
      expect(validateCategories(null), isNull);
    });

    test('should return null for empty categories list', () {
      expect(validateCategories([]), isNull);
    });

    test('should return null for valid categories', () {
      expect(validateCategories(['restaurant', 'food']), isNull);
    });

    test('should return error when categories exceed max count', () {
      final categories = List.generate(21, (i) => 'category$i');
      final result = validateCategories(categories);
      expect(result, contains('20 categories'));
    });

    test('should return error for empty string in categories', () {
      final result = validateCategories(['restaurant', '']);
      expect(result, contains('cannot be empty'));
    });

    test('should return error for whitespace-only category', () {
      final result = validateCategories(['restaurant', '   ']);
      expect(result, contains('cannot be empty'));
    });

    test('should return error for duplicate categories', () {
      final result = validateCategories(['restaurant', 'food', 'restaurant']);
      expect(result, contains('duplicates'));
    });

    test('should return error when category exceeds max length', () {
      final longCategory = 'a' * 51;
      final result = validateCategories([longCategory]);
      expect(result, contains('exceeds maximum length'));
    });

    test('should trim categories before validation', () {
      final result = validateCategories(['  restaurant  ', '  food  ']);
      expect(result, isNull); // Should be valid
    });
  });

  group('estimateDocumentSize', () {
    test('should estimate size for minimal merchant', () {
      final size = estimateDocumentSize(
        name: 'Test',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );
      expect(size, greaterThan(0));
    });

    test('should estimate size for merchant with all fields', () {
      final size = estimateDocumentSize(
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
        address: '123 Test Street',
        categories: ['restaurant', 'food'],
        description: 'A test business',
        hours: {'monday': {'open': '09:00', 'close': '18:00'}},
      );
      expect(size, greaterThan(0));
    });

    test('should increase size estimate with longer strings', () {
      final smallSize = estimateDocumentSize(
        name: 'Test',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );
      final largeSize = estimateDocumentSize(
        name: 'A' * 100,
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );
      expect(largeSize, greaterThan(smallSize));
    });

    test('should include optional fields in size estimate', () {
      final withoutOptional = estimateDocumentSize(
        name: 'Test',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );
      final withOptional = estimateDocumentSize(
        name: 'Test',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
        address: '123 Test Street',
        description: 'A test business',
      );
      expect(withOptional, greaterThan(withoutOptional));
    });
  });
}

