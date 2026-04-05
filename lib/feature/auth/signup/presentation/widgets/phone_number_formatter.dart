import 'package:flutter/services.dart';
import '../constants/signup_constants.dart';

part 'phone_number_formatter.part.dart';

/// Custom TextInputFormatter that formats phone numbers automatically based on country code
/// Prevents typing beyond the maximum allowed digits for each country
class PhoneNumberFormatter extends TextInputFormatter {
  PhoneNumberFormatter({
    required this.countryCode,
  });

  final String countryCode;

  /// Get maximum allowed digits for the country code
  int _getMaxDigits() {
    final expectedLength = SignupConstants.countryPhoneLengths[countryCode];
    if (expectedLength != null) {
      return expectedLength + 2;
    }
    return 12;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');

    final maxDigits = _getMaxDigits();

    if (newDigits.length > maxDigits) {
      return oldValue;
    }

    if (newDigits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _formatPhoneForInput(countryCode, newDigits);

    final oldCursorOffset = oldValue.selection.extentOffset;
    final oldTextBeforeCursor =
        oldValue.text.substring(0, oldCursorOffset.clamp(0, oldValue.text.length));
    final oldDigitsBeforeCursor =
        oldTextBeforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;

    final digitDiff = newDigits.length - oldDigits.length;

    late final int targetDigitCount;
    if (digitDiff > 0) {
      targetDigitCount = oldDigitsBeforeCursor + digitDiff;
    } else if (digitDiff < 0) {
      targetDigitCount = oldDigitsBeforeCursor.clamp(0, newDigits.length);
    } else {
      targetDigitCount = oldDigitsBeforeCursor.clamp(0, newDigits.length);
    }

    var newCursorPosition = formatted.length;
    var digitsCount = 0;

    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        digitsCount++;
        if (digitDiff > 0) {
          if (digitsCount >= targetDigitCount) {
            newCursorPosition = i + 1;
            break;
          }
        } else {
          if (digitsCount >= targetDigitCount) {
            newCursorPosition = i + 1;
            break;
          }
        }
      }
    }

    if (newCursorPosition > formatted.length || newCursorPosition < 0) {
      newCursorPosition = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }
}
