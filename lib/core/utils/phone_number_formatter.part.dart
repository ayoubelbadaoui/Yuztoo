part of 'phone_number_formatter.dart';

/// Format phone number for display in the input field (country-specific grouping).
String _formatPhoneForInput(String countryCode, String digits) {
  switch (countryCode) {
    case '+33': // France: X XX XX XX XX (E.164 form) or 0X XX XX XX XX (national)
      // French numbers are routinely typed with the national trunk prefix
      // "0" by users (e.g. 06 12 34 56 78). The previous 9-digit template
      // silently dropped the 10th digit, leaving the user unable to enter
      // a number they were typing exactly as written on a business card.
      // PhoneFormatter.formatPhoneNumber strips the leading 0 when building
      // E.164 at submit time, so accepting both forms here is purely a
      // display courtesy: 9-digit input keeps the existing "X XX XX XX XX"
      // grouping; 10-digit input with leading 0 uses "0X XX XX XX XX".
      if (digits.startsWith('0')) {
        if (digits.length <= 2) return digits;
        if (digits.length <= 4) {
          return '${digits.substring(0, 2)} ${digits.substring(2)}';
        }
        if (digits.length <= 6) {
          return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4)}';
        }
        if (digits.length <= 8) {
          return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6)}';
        }
        if (digits.length <= 10) {
          return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
        }
        return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)}';
      }
      if (digits.length <= 1) return digits;
      if (digits.length <= 3) {
        return '${digits.substring(0, 1)} ${digits.substring(1)}';
      }
      if (digits.length <= 5) {
        return '${digits.substring(0, 1)} ${digits.substring(1, 3)} ${digits.substring(3)}';
      }
      if (digits.length <= 7) {
        return '${digits.substring(0, 1)} ${digits.substring(1, 3)} ${digits.substring(3, 5)} ${digits.substring(5)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 1)} ${digits.substring(1, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
      }
      return '${digits.substring(0, 1)} ${digits.substring(1, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';

    case '+1': // US/Canada: (XXX) XXX-XXXX
      if (digits.length <= 3) return digits;
      if (digits.length <= 6) {
        return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
      }
      if (digits.length <= 10) {
        return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
      }
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';

    case '+44': // UK: XXXX XXXXXX
      if (digits.length <= 4) return digits;
      if (digits.length <= 10) {
        return '${digits.substring(0, 4)} ${digits.substring(4)}';
      }
      return '${digits.substring(0, 4)} ${digits.substring(4, 10)}';

    case '+34': // Spain: XXX XXX XXX
      if (digits.length <= 3) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';

    case '+49': // Germany: XXXX XXXXXXX
      if (digits.length <= 4) return digits;
      if (digits.length <= 11) {
        return '${digits.substring(0, 4)} ${digits.substring(4)}';
      }
      return '${digits.substring(0, 4)} ${digits.substring(4, 11)}';

    case '+39': // Italy: XXX XXX XXXX
      if (digits.length <= 3) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      }
      if (digits.length <= 10) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 10)}';

    case '+31': // Netherlands: X XXXX XXXX
      if (digits.length <= 1) return digits;
      if (digits.length <= 5) {
        return '${digits.substring(0, 1)} ${digits.substring(1)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 1)} ${digits.substring(1, 5)} ${digits.substring(5)}';
      }
      return '${digits.substring(0, 1)} ${digits.substring(1, 5)} ${digits.substring(5, 9)}';

    case '+32': // Belgium: XXXX XX XX XX
      if (digits.length <= 4) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 4)} ${digits.substring(4)}';
      }
      if (digits.length <= 8) {
        return '${digits.substring(0, 4)} ${digits.substring(4, 6)} ${digits.substring(6)}';
      }
      if (digits.length <= 10) {
        return '${digits.substring(0, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
      }
      return '${digits.substring(0, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)}';

    case '+41': // Switzerland: XX XXX XX XX
      if (digits.length <= 2) return digits;
      if (digits.length <= 5) {
        return '${digits.substring(0, 2)} ${digits.substring(2)}';
      }
      if (digits.length <= 7) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
      }
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';

    case '+43': // Austria: XXXX XXXXXX
      if (digits.length <= 4) return digits;
      if (digits.length <= 10) {
        return '${digits.substring(0, 4)} ${digits.substring(4)}';
      }
      return '${digits.substring(0, 4)} ${digits.substring(4, 10)}';

    case '+351': // Portugal: XXX XXX XXX
      if (digits.length <= 3) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';

    case '+30': // Greece: XXX XXX XXXX
      if (digits.length <= 3) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      }
      if (digits.length <= 10) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 10)}';

    case '+46': // Sweden: XX-XXX XX XX
      if (digits.length <= 2) return digits;
      if (digits.length <= 5) {
        return '${digits.substring(0, 2)}-${digits.substring(2)}';
      }
      if (digits.length <= 7) {
        return '${digits.substring(0, 2)}-${digits.substring(2, 5)} ${digits.substring(5)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 2)}-${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
      }
      return '${digits.substring(0, 2)}-${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';

    case '+47': // Norway: XXX XX XXX
      if (digits.length <= 3) return digits;
      if (digits.length <= 5) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      }
      if (digits.length <= 8) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5)}';
      }
      return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 8)}';

    case '+45': // Denmark: XX XX XX XX
      if (digits.length <= 2) return digits;
      if (digits.length <= 4) {
        return '${digits.substring(0, 2)} ${digits.substring(2)}';
      }
      if (digits.length <= 6) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4)}';
      }
      if (digits.length <= 8) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6)}';
      }
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)}';

    case '+358': // Finland: XX XXX XXXX
      if (digits.length <= 2) return digits;
      if (digits.length <= 5) {
        return '${digits.substring(0, 2)} ${digits.substring(2)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
      }
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}';

    case '+48': // Poland: XXX XXX XXX
      if (digits.length <= 3) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';

    case '+420': // Czech: XXX XXX XXX
      if (digits.length <= 3) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';

    case '+36': // Hungary: XX XXX XXXX
      if (digits.length <= 2) return digits;
      if (digits.length <= 5) {
        return '${digits.substring(0, 2)} ${digits.substring(2)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
      }
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}';

    case '+40': // Romania: XXX XXX XXX
      if (digits.length <= 3) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';

    case '+212': // Morocco: XXXX-XXXXX (E.164) or 0XXX-XXXXX (national, 10 digits)
      // Same rationale as +33: accept a leading "0" so users can type the
      // number as they would dial domestically. The submit-time formatter
      // strips it for E.164.
      if (digits.startsWith('0')) {
        if (digits.length <= 4) return digits;
        if (digits.length <= 10) {
          return '${digits.substring(0, 4)}-${digits.substring(4)}';
        }
        return '${digits.substring(0, 4)}-${digits.substring(4, 10)}';
      }
      if (digits.length <= 4) return digits;
      if (digits.length <= 9) {
        return '${digits.substring(0, 4)}-${digits.substring(4)}';
      }
      return '${digits.substring(0, 4)}-${digits.substring(4, 9)}';

    case '+216': // Tunisia: XX XXX XXX
      if (digits.length <= 2) return digits;
      if (digits.length <= 5) {
        return '${digits.substring(0, 2)} ${digits.substring(2)}';
      }
      if (digits.length <= 8) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
      }
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 8)}';

    case '+213': // Algeria: XXX XX XX XX
      if (digits.length <= 3) return digits;
      if (digits.length <= 5) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      }
      if (digits.length <= 7) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
      }
      return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';

    case '+20': // Egypt: XXXX XXX XXXX
      if (digits.length <= 4) return digits;
      if (digits.length <= 7) {
        return '${digits.substring(0, 4)} ${digits.substring(4)}';
      }
      if (digits.length <= 10) {
        return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
      }
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 10)}';

    case '+27': // South Africa: XX XXX XXXX
      if (digits.length <= 2) return digits;
      if (digits.length <= 5) {
        return '${digits.substring(0, 2)} ${digits.substring(2)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
      }
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}';

    case '+81': // Japan: XX-XXXX-XXXX
      if (digits.length <= 2) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 2)}-${digits.substring(2)}';
      }
      if (digits.length <= 10) {
        return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
      }
      return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6, 10)}';

    case '+82': // South Korea: XX-XXXX-XXXX
      if (digits.length <= 2) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 2)}-${digits.substring(2)}';
      }
      if (digits.length <= 10) {
        return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
      }
      return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6, 10)}';

    case '+86': // China: XXXX XXXX XXX
      if (digits.length <= 4) return digits;
      if (digits.length <= 8) {
        return '${digits.substring(0, 4)} ${digits.substring(4)}';
      }
      if (digits.length <= 11) {
        return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8)}';
      }
      return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8, 11)}';

    case '+91': // India: XXXX XXXX XX
      if (digits.length <= 4) return digits;
      if (digits.length <= 8) {
        return '${digits.substring(0, 4)} ${digits.substring(4)}';
      }
      if (digits.length <= 10) {
        return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8)}';
      }
      return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8, 10)}';

    case '+61': // Australia: XXXX XXX XXX
      if (digits.length <= 4) return digits;
      if (digits.length <= 7) {
        return '${digits.substring(0, 4)} ${digits.substring(4)}';
      }
      if (digits.length <= 10) {
        return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
      }
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 10)}';

    case '+64': // New Zealand: XXXX XXXX
      if (digits.length <= 4) return digits;
      if (digits.length <= 8) {
        return '${digits.substring(0, 4)} ${digits.substring(4)}';
      }
      return '${digits.substring(0, 4)} ${digits.substring(4, 8)}';

    case '+55': // Brazil: (XX) XXXX-XXXX
      if (digits.length <= 2) return digits;
      if (digits.length <= 6) {
        return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
      }
      if (digits.length <= 10) {
        return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
      }
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6, 10)}';

    case '+52': // Mexico: XX XXXX XXXX
      if (digits.length <= 2) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 2)} ${digits.substring(2)}';
      }
      if (digits.length <= 10) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 6)} ${digits.substring(6)}';
      }
      return '${digits.substring(0, 2)} ${digits.substring(2, 6)} ${digits.substring(6, 10)}';

    case '+54': // Argentina: XX XXXX-XXXX
      if (digits.length <= 2) return digits;
      if (digits.length <= 6) {
        return '${digits.substring(0, 2)} ${digits.substring(2)}';
      }
      if (digits.length <= 10) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 6)}-${digits.substring(6)}';
      }
      return '${digits.substring(0, 2)} ${digits.substring(2, 6)}-${digits.substring(6, 10)}';

    case '+56': // Chile: X XXXX XXXX
      if (digits.length <= 1) return digits;
      if (digits.length <= 5) {
        return '${digits.substring(0, 1)} ${digits.substring(1)}';
      }
      if (digits.length <= 9) {
        return '${digits.substring(0, 1)} ${digits.substring(1, 5)} ${digits.substring(5)}';
      }
      return '${digits.substring(0, 1)} ${digits.substring(1, 5)} ${digits.substring(5, 9)}';

    default:
      if (digits.length <= 2) return digits;
      var formatted = '';
      for (var i = 0; i < digits.length; i++) {
        if (i > 0 && i % 2 == 0) formatted += ' ';
        formatted += digits[i];
      }
      return formatted;
  }
}
