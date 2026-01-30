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

  /// Format phone number for display (e.g., +33 6 12 34 56 78)
  static String formatPhoneForDisplay(String phoneNumber) {
    // Remove all non-digits except +
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (!cleaned.startsWith('+')) {
      return phoneNumber; // Return as-is if not in international format
    }

    // Extract country code and number
    final parts = cleaned.substring(1).split('');
    if (parts.isEmpty) return phoneNumber;

    // Common country code lengths
    String countryCode = '';
    String number = '';
    
    // Try to detect country code (1-3 digits)
    if (parts.length >= 3 && parts[0] == '3' && parts[1] == '3') {
      // France +33
      countryCode = '+33';
      number = parts.skip(2).join('');
    } else if (parts.length >= 2 && parts[0] == '1') {
      // US/Canada +1
      countryCode = '+1';
      number = parts.skip(1).join('');
    } else if (parts.length >= 2 && parts[0] == '4' && parts[1] == '4') {
      // UK +44
      countryCode = '+44';
      number = parts.skip(2).join('');
    } else if (parts.length >= 2 && parts[0] == '3' && parts[1] == '4') {
      // Spain +34
      countryCode = '+34';
      number = parts.skip(2).join('');
    } else if (parts.length >= 2 && parts[0] == '4' && parts[1] == '9') {
      // Germany +49
      countryCode = '+49';
      number = parts.skip(2).join('');
    } else if (parts.length >= 3 && parts[0] == '3' && parts[1] == '5' && parts[2] == '1') {
      // Portugal +351
      countryCode = '+351';
      number = parts.skip(3).join('');
    } else if (parts.length >= 3 && parts[0] == '3' && parts[1] == '5' && parts[2] == '8') {
      // Finland +358
      countryCode = '+358';
      number = parts.skip(3).join('');
    } else if (parts.length >= 3 && parts[0] == '4' && parts[1] == '2' && parts[2] == '0') {
      // Czech +420
      countryCode = '+420';
      number = parts.skip(3).join('');
    } else if (parts.length >= 3 && parts[0] == '2' && parts[1] == '1' && parts[2] == '2') {
      // Morocco +212
      countryCode = '+212';
      number = parts.skip(3).join('');
    } else if (parts.length >= 3 && parts[0] == '2' && parts[1] == '1' && parts[2] == '3') {
      // Algeria +213
      countryCode = '+213';
      number = parts.skip(3).join('');
    } else if (parts.length >= 2 && parts[0] == '2' && parts[1] == '1' && parts[2] == '6') {
      // Tunisia +216
      countryCode = '+216';
      number = parts.skip(3).join('');
    } else {
      // Default: assume first 1-3 digits are country code
      if (parts.length >= 3) {
        countryCode = '+${parts[0]}${parts[1]}${parts[2]}';
        number = parts.skip(3).join('');
      } else if (parts.length >= 2) {
        countryCode = '+${parts[0]}${parts[1]}';
        number = parts.skip(2).join('');
      } else {
        countryCode = '+${parts[0]}';
        number = parts.skip(1).join('');
      }
    }

    // Format the number part with spaces (group by 2 digits)
    String formattedNumber = '';
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && i % 2 == 0) {
        formattedNumber += ' ';
      }
      formattedNumber += number[i];
    }

    return '$countryCode $formattedNumber'.trim();
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

