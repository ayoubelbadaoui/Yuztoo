import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/auth/signup/presentation/constants/signup_constants.dart';
import 'package:flutter_yuztoo/feature/auth/signup/presentation/widgets/phone_number_formatter.dart';

void main() {
  group('PhoneNumberFormatter', () {
    for (final country in SignupConstants.countryCodes) {
      final code = country['code']!;

      test('formats progressively for $code without throwing', () {
        final formatter = PhoneNumberFormatter(countryCode: code);
        var value = const TextEditingValue(text: '');

        for (var d = 0; d <= 12; d++) {
          final nextDigit = (d % 10).toString();
          final oldValue = value;
          final newValue = TextEditingValue(
            text: oldValue.text + nextDigit,
            selection: TextSelection.collapsed(
              offset: (oldValue.text + nextDigit).length,
            ),
          );
          expect(
            () => formatter.formatEditUpdate(oldValue, newValue),
            returnsNormally,
            reason: 'digit $d for $code',
          );
          value = formatter.formatEditUpdate(oldValue, newValue);
        }
      });
    }

    // ── Leading-0 acceptance regression ─────────────────────────────────────
    // The previous +33 formatter capped at 9 digits, which silently dropped
    // the 10th digit when users typed the French national form starting with
    // "0" (e.g. 06 12 34 56 78). The fix accepts both forms.
    test('+33 accepts 10-digit input with leading 0 (national form)', () {
      final formatter = PhoneNumberFormatter(countryCode: '+33');
      // Simulate typing "0612345678" character by character.
      var value = const TextEditingValue(text: '');
      const target = '0612345678';
      for (var i = 0; i < target.length; i++) {
        final nextChar = target[i];
        final next = TextEditingValue(
          text: value.text + nextChar,
          selection: TextSelection.collapsed(offset: value.text.length + 1),
        );
        value = formatter.formatEditUpdate(value, next);
      }
      // Every typed digit must survive in the displayed text.
      expect(
        value.text.replaceAll(RegExp(r'[^\d]'), ''),
        '0612345678',
        reason:
            'all 10 typed digits must be present after formatting — the '
            'previous 9-digit cap silently dropped the trailing 8',
      );
    });

    test('+33 still works for 9-digit international form (no leading 0)', () {
      final formatter = PhoneNumberFormatter(countryCode: '+33');
      var value = const TextEditingValue(text: '');
      const target = '612345678';
      for (var i = 0; i < target.length; i++) {
        final nextChar = target[i];
        final next = TextEditingValue(
          text: value.text + nextChar,
          selection: TextSelection.collapsed(offset: value.text.length + 1),
        );
        value = formatter.formatEditUpdate(value, next);
      }
      expect(
        value.text.replaceAll(RegExp(r'[^\d]'), ''),
        '612345678',
      );
    });

    test('+212 accepts 10-digit input with leading 0', () {
      final formatter = PhoneNumberFormatter(countryCode: '+212');
      var value = const TextEditingValue(text: '');
      const target = '0612345678';
      for (var i = 0; i < target.length; i++) {
        final nextChar = target[i];
        final next = TextEditingValue(
          text: value.text + nextChar,
          selection: TextSelection.collapsed(offset: value.text.length + 1),
        );
        value = formatter.formatEditUpdate(value, next);
      }
      expect(
        value.text.replaceAll(RegExp(r'[^\d]'), ''),
        '0612345678',
      );
    });
  });
}
