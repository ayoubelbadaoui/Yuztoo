import 'package:flutter/services.dart';

part 'phone_number_formatter.part.dart';

/// National-number length (digits, **excluding** the country code) by E.164
/// prefix. Used by [PhoneNumberFormatter] to:
///   - cap typing at `expectedLength + 2` digits (small flexibility for
///     numbers that include a national trunk prefix like `0` or two-digit
///     short codes);
///   - pick the right grouping template per country.
///
/// Kept private to this utility because it's an implementation detail of
/// the formatter — feature-level callers (signup, merchant onboarding,
/// OAuth completion) just pass `countryCode` and let the formatter do the
/// right thing.
const Map<String, int> _kCountryPhoneLengths = {
  '+33': 9, // France
  '+1': 10, // US/Canada
  '+44': 10, // UK
  '+34': 9, // Spain
  '+49': 10, // Germany
  '+39': 9, // Italy
  '+31': 9, // Netherlands
  '+32': 9, // Belgium
  '+41': 9, // Switzerland
  '+43': 10, // Austria
  '+351': 9, // Portugal
  '+30': 10, // Greece
  '+46': 9, // Sweden
  '+47': 8, // Norway
  '+45': 8, // Denmark
  '+358': 9, // Finland
  '+48': 9, // Poland
  '+420': 9, // Czech Republic
  '+36': 9, // Hungary
  '+40': 9, // Romania
  '+212': 9, // Morocco
  '+216': 8, // Tunisia
  '+213': 9, // Algeria
  '+20': 10, // Egypt
  '+27': 9, // South Africa
  '+81': 10, // Japan
  '+82': 9, // South Korea
  '+86': 11, // China
  '+91': 10, // India
  '+61': 9, // Australia
  '+64': 8, // New Zealand
  '+55': 10, // Brazil
  '+52': 10, // Mexico
  '+54': 10, // Argentina
  '+56': 9, // Chile
};

/// Custom [TextInputFormatter] that formats phone numbers as the user types
/// using country-specific grouping (e.g. `06 12 34 56 78` for France) and
/// caps input at the expected national-number length plus a 2-digit slack.
///
/// **Trunk prefix handling.** For countries where domestic users routinely
/// dial a leading `0` (France `+33`, Morocco `+212`), the formatter accepts
/// **either** the 9-digit international form (`612345678`) **or** the
/// 10-digit national form (`0612345678`) and groups it accordingly. The
/// E.164 conversion at submit time (caller-side) is responsible for
/// stripping the leading `0` before persisting.
///
/// Lives in `core/utils` (not in any single feature) because it is shared
/// by signup, OAuth completion, and merchant onboarding's contact step.
class PhoneNumberFormatter extends TextInputFormatter {
  PhoneNumberFormatter({
    required this.countryCode,
  });

  final String countryCode;

  /// Maximum digits the user is allowed to type. Returns
  /// `expectedLength + 2` so users typing `0` + 9-digit French numbers
  /// (10 chars) still fit, with one extra char of slack for outliers.
  int _getMaxDigits() {
    final expectedLength = _kCountryPhoneLengths[countryCode];
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
