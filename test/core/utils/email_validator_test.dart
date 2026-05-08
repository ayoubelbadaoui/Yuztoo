import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/core/utils/email_validator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EmailValidator — covers both the format check used by the onboarding
// "Suivant" gate AND the placeholder detector used by the storefront-edit
// migration prompt.
//
// The regex is intentionally pragmatic (typo-catching, not RFC-5322), so
// these tests document what we *do* and *do not* care about. If you tighten
// the regex, expect to update the "edge cases" group.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('EmailValidator.isValid', () {
    test('accepts standard addresses', () {
      for (final v in [
        'user@example.com',
        'first.last@example.fr',
        'with+plus@gmail.com',
        'with-dash@my-domain.co',
        'a@b.co',
        'numbers123@digits456.io',
        'mixed_Case@Example.COM',
      ]) {
        expect(EmailValidator.isValid(v), isTrue, reason: 'should accept $v');
      }
    });

    test('rejects empty / null / whitespace', () {
      expect(EmailValidator.isValid(null), isFalse);
      expect(EmailValidator.isValid(''), isFalse);
      expect(EmailValidator.isValid('   '), isFalse);
      expect(EmailValidator.isValid('\t\n'), isFalse);
    });

    test('rejects missing @', () {
      expect(EmailValidator.isValid('plainstring'), isFalse);
      expect(EmailValidator.isValid('no.at.symbol.com'), isFalse);
    });

    test('rejects missing domain TLD', () {
      // No dot in the domain → not deliverable.
      expect(EmailValidator.isValid('user@localhost'), isFalse);
      expect(EmailValidator.isValid('user@example'), isFalse);
    });

    test('rejects consecutive dots in local part', () {
      expect(EmailValidator.isValid('a..b@example.com'), isFalse);
    });

    test('rejects leading/trailing dots in local part', () {
      expect(EmailValidator.isValid('.user@example.com'), isFalse);
      expect(EmailValidator.isValid('user.@example.com'), isFalse);
    });

    test('rejects spaces inside the address', () {
      expect(EmailValidator.isValid('a b@example.com'), isFalse);
      expect(EmailValidator.isValid('user @example.com'), isFalse);
      expect(EmailValidator.isValid('user@example .com'), isFalse);
    });

    test('rejects values longer than 254 chars (RFC max)', () {
      final tooLong = '${'a' * 250}@x.co';
      expect(tooLong.length, greaterThan(254));
      expect(EmailValidator.isValid(tooLong), isFalse);
    });

    test('trims surrounding whitespace before validating', () {
      expect(EmailValidator.isValid('  user@example.com  '), isTrue);
    });
  });

  group('EmailValidator.isPlaceholderOrEmpty', () {
    test('flags null / empty / whitespace', () {
      expect(EmailValidator.isPlaceholderOrEmpty(null), isTrue);
      expect(EmailValidator.isPlaceholderOrEmpty(''), isTrue);
      expect(EmailValidator.isPlaceholderOrEmpty('   '), isTrue);
    });

    test('flags the legacy demo placeholder regardless of case', () {
      // The bug we shipped wrote `demo@example.com` literal, but defend
      // against case drift if it ever gets logged or mis-cased upstream.
      expect(EmailValidator.isPlaceholderOrEmpty('demo@example.com'), isTrue);
      expect(EmailValidator.isPlaceholderOrEmpty('DEMO@example.com'), isTrue);
      expect(
          EmailValidator.isPlaceholderOrEmpty('  demo@example.com '), isTrue);
    });

    test('does NOT flag real-looking addresses', () {
      expect(EmailValidator.isPlaceholderOrEmpty('contact@real.fr'), isFalse);
      expect(
          EmailValidator.isPlaceholderOrEmpty('demo@otherdomain.com'), isFalse);
      expect(EmailValidator.isPlaceholderOrEmpty('a@b.co'), isFalse);
    });

    test('does NOT flag invalid-but-non-placeholder strings', () {
      // The placeholder check is independent from format validation:
      // garbage strings are NOT placeholders. The UI separately runs
      // isValid() to surface a "format invalide" hint.
      expect(EmailValidator.isPlaceholderOrEmpty('not-an-email'), isFalse);
    });
  });
}
