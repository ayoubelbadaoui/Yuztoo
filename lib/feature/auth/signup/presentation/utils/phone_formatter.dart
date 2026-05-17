import '../constants/signup_constants.dart';

/// Phone number formatting utilities
class PhoneFormatter {
  /// Format phone number to E.164 format
  static String formatPhoneNumber(String countryCode, String rawInput) {
    final trimmed = rawInput.trim();
    final countryDigits = countryCode.replaceAll(RegExp(r'\D'), '');
    var digits = trimmed.replaceAll(RegExp(r'\D'), '');

    // If user already typed an international number (starts with +)
    if (trimmed.startsWith('+')) {
      // Normalize to +<digits> without leading zeros after +
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
      return '+$digits';
    }

    // If user typed an international number with 00 prefix
    if (digits.startsWith('00')) {
      digits = digits.substring(2).replaceFirst(RegExp(r'^0+'), '');
      return '+$digits';
    }

    // If user typed full number including country code (without +), don't double it
    if (countryDigits.isNotEmpty && digits.startsWith(countryDigits)) {
      return '+$digits';
    }

    // Otherwise, treat as national number and strip trunk prefix
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    return '$countryCode$digits';
  }

  /// Format phone number for display (e.g., +33 6 12 34 56 78).
  ///
  /// Never throws — partial or unknown E.164 values fall back to the raw input.
  static String formatPhoneForDisplay(String phoneNumber) {
    try {
      return _formatPhoneForDisplaySafe(phoneNumber);
    } catch (_) {
      return phoneNumber;
    }
  }

  static String _formatPhoneForDisplaySafe(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 2) {
      return phoneNumber;
    }

    final extracted = extractPhoneData(cleaned);
    if (extracted == null) {
      return phoneNumber;
    }

    final countryCode = extracted['countryCode']!;
    var number = extracted['localNumber'] ?? '';
    if (number.isEmpty) {
      return countryCode;
    }

    // Morocco: first digit alone, then pairs (e.g. +212 6 50 01 46 83).
    if (countryCode == '+212') {
      final first = number[0];
      final rest = number.substring(1);
      final buffer = StringBuffer('$countryCode $first');
      for (var i = 0; i < rest.length; i += 2) {
        buffer.write(' ');
        if (i + 1 < rest.length) {
          buffer.write(rest.substring(i, i + 2));
        } else {
          buffer.write(rest[i]);
        }
      }
      return buffer.toString();
    }

    final groups = <String>[];
    for (var i = 0; i < number.length; i += 2) {
      final end = (i + 2).clamp(0, number.length);
      if (i < end) {
        groups.add(number.substring(i, end));
      }
    }
    return '$countryCode ${groups.join(' ')}'.trim();
  }

  /// Validate E.164 phone number format
  static bool isValidE164(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    // E.164 allows up to 15 digits (country code + national number)
    return digits.length >= 8 && digits.length <= 15;
  }

  /// Extract country code and local number from E.164 formatted phone number
  /// Returns map with 'countryCode' and 'localNumber', or null if extraction fails
  static Map<String, String>? extractPhoneData(String e164Number) {
    if (e164Number.isEmpty || !e164Number.startsWith('+')) {
      return null;
    }
    
    // Try to match against known country codes (longest first to avoid partial matches)
    final sortedCodes = SignupConstants.countryCodes.map((c) => c['code']!).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (final code in sortedCodes) {
      if (e164Number.startsWith(code)) {
        final localNumber = e164Number.substring(code.length);
        return {
          'countryCode': code,
          'localNumber': localNumber,
        };
      }
    }
    
    // Fallback: try to extract first 1-3 digits as country code
    if (e164Number.length > 3) {
      // Try 3 digits first (for codes like +351, +212, etc.)
      if (e164Number.length > 5) {
        final possibleCode = e164Number.substring(0, 4);
        if (SignupConstants.countryCodes.any((c) => c['code'] == possibleCode)) {
          return {
            'countryCode': possibleCode,
            'localNumber': e164Number.substring(4),
          };
        }
      }
      // Try 2 digits (for codes like +33, +44, etc.)
      if (e164Number.length > 4) {
        final possibleCode = e164Number.substring(0, 3);
        if (SignupConstants.countryCodes.any((c) => c['code'] == possibleCode)) {
          return {
            'countryCode': possibleCode,
            'localNumber': e164Number.substring(3),
          };
        }
      }
      // Try 1 digit (for codes like +1)
      if (e164Number.length > 3) {
        final possibleCode = e164Number.substring(0, 2);
        if (SignupConstants.countryCodes.any((c) => c['code'] == possibleCode)) {
          return {
            'countryCode': possibleCode,
            'localNumber': e164Number.substring(2),
          };
        }
      }
    }
    
    // Default to France if extraction fails
    return {
      'countryCode': '+33',
      'localNumber': e164Number.substring(1), // Remove the +
    };
  }
}

