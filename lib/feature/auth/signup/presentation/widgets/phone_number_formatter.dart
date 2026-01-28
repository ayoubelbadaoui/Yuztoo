import 'package:flutter/services.dart';
import '../constants/signup_constants.dart';

/// Custom TextInputFormatter that formats phone numbers automatically based on country code
/// Prevents typing beyond the maximum allowed digits for each country
class PhoneNumberFormatter extends TextInputFormatter {
  final String countryCode;

  PhoneNumberFormatter({
    required this.countryCode,
  });

  /// Get maximum allowed digits for the country code
  int _getMaxDigits() {
    final expectedLength = SignupConstants.countryPhoneLengths[countryCode];
    if (expectedLength != null) {
      // Allow max 2 digits more than expected (flexibility)
      return expectedLength + 2;
    }
    // Fallback: E.164 max is 15 digits total (country code + national number)
    // For safety, limit to 12 digits for national number
    return 12;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract only digits from both values
    final newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Get maximum allowed digits for this country
    final maxDigits = _getMaxDigits();
    
    // If user tries to type beyond max, prevent it by keeping old value
    if (newDigits.length > maxDigits) {
      // Return old value to prevent typing beyond limit
      return oldValue;
    }
    
    // If no digits, return empty
    if (newDigits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Format according to country code
    final formatted = _formatPhoneForInput(countryCode, newDigits);
    
    // Calculate cursor position based on digit count before cursor
    final oldCursorOffset = oldValue.selection.extentOffset;
    final oldTextBeforeCursor = oldValue.text.substring(0, oldCursorOffset.clamp(0, oldValue.text.length));
    final oldDigitsBeforeCursor = oldTextBeforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;
    
    // Determine operation type
    final digitDiff = newDigits.length - oldDigits.length;
    
    // Calculate target digit count for cursor position
    int targetDigitCount;
    if (digitDiff > 0) {
      // Inserting: cursor should be after the newly inserted digit(s)
      targetDigitCount = oldDigitsBeforeCursor + digitDiff;
    } else if (digitDiff < 0) {
      // Deleting: cursor should be at the position of remaining digits
      targetDigitCount = oldDigitsBeforeCursor.clamp(0, newDigits.length);
    } else {
      // Same length (replacement): maintain relative position
      targetDigitCount = oldDigitsBeforeCursor.clamp(0, newDigits.length);
    }
    
    // Find cursor position in formatted string
    int newCursorPosition = formatted.length;
    int digitsCount = 0;
    
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        digitsCount++;
        // When inserting, place cursor after the target digit
        // When deleting/replacing, place cursor at or after the target digit
        if (digitDiff > 0) {
          // Inserting: cursor after target
          if (digitsCount >= targetDigitCount) {
            newCursorPosition = i + 1;
            break;
          }
        } else {
          // Deleting or replacing: cursor at target
          if (digitsCount >= targetDigitCount) {
            newCursorPosition = i + 1;
            break;
          }
        }
      }
    }
    
    // If we didn't find the position (edge case), place at end
    if (newCursorPosition > formatted.length || newCursorPosition < 0) {
      newCursorPosition = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  /// Format phone number for display in the input field
  String _formatPhoneForInput(String countryCode, String digits) {
    switch (countryCode) {
      case '+33': // France: X XX XX XX XX
        if (digits.length <= 1) return digits;
        if (digits.length <= 3) return '${digits.substring(0, 1)} ${digits.substring(1)}';
        if (digits.length <= 5) return '${digits.substring(0, 1)} ${digits.substring(1, 3)} ${digits.substring(3)}';
        if (digits.length <= 7) return '${digits.substring(0, 1)} ${digits.substring(1, 3)} ${digits.substring(3, 5)} ${digits.substring(5)}';
        if (digits.length <= 9) return '${digits.substring(0, 1)} ${digits.substring(1, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
        return '${digits.substring(0, 1)} ${digits.substring(1, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
      
      case '+1': // US/Canada: (XXX) XXX-XXXX
        if (digits.length <= 3) return digits;
        if (digits.length <= 6) return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
        if (digits.length <= 10) return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
        return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
      
      case '+44': // UK: XXXX XXXXXX
        if (digits.length <= 4) return digits;
        if (digits.length <= 10) return '${digits.substring(0, 4)} ${digits.substring(4)}';
        return '${digits.substring(0, 4)} ${digits.substring(4, 10)}';
      
      case '+34': // Spain: XXX XXX XXX
        if (digits.length <= 3) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 3)} ${digits.substring(3)}';
        if (digits.length <= 9) return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';
      
      case '+49': // Germany: XXXX XXXXXXX
        if (digits.length <= 4) return digits;
        if (digits.length <= 11) return '${digits.substring(0, 4)} ${digits.substring(4)}';
        return '${digits.substring(0, 4)} ${digits.substring(4, 11)}';
      
      case '+39': // Italy: XXX XXX XXXX
        if (digits.length <= 3) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 3)} ${digits.substring(3)}';
        if (digits.length <= 10) return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 10)}';
      
      case '+31': // Netherlands: X XXXX XXXX
        if (digits.length <= 1) return digits;
        if (digits.length <= 5) return '${digits.substring(0, 1)} ${digits.substring(1)}';
        if (digits.length <= 9) return '${digits.substring(0, 1)} ${digits.substring(1, 5)} ${digits.substring(5)}';
        return '${digits.substring(0, 1)} ${digits.substring(1, 5)} ${digits.substring(5, 9)}';
      
      case '+32': // Belgium: XXXX XX XX XX
        if (digits.length <= 4) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 4)} ${digits.substring(4)}';
        if (digits.length <= 8) return '${digits.substring(0, 4)} ${digits.substring(4, 6)} ${digits.substring(6)}';
        if (digits.length <= 10) return '${digits.substring(0, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
        return '${digits.substring(0, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)}';
      
      case '+41': // Switzerland: XX XXX XX XX
        if (digits.length <= 2) return digits;
        if (digits.length <= 5) return '${digits.substring(0, 2)} ${digits.substring(2)}';
        if (digits.length <= 7) return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
        if (digits.length <= 9) return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
      
      case '+43': // Austria: XXXX XXXXXX
        if (digits.length <= 4) return digits;
        if (digits.length <= 10) return '${digits.substring(0, 4)} ${digits.substring(4)}';
        return '${digits.substring(0, 4)} ${digits.substring(4, 10)}';
      
      case '+351': // Portugal: XXX XXX XXX
        if (digits.length <= 3) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 3)} ${digits.substring(3)}';
        if (digits.length <= 9) return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';
      
      case '+30': // Greece: XXX XXX XXXX
        if (digits.length <= 3) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 3)} ${digits.substring(3)}';
        if (digits.length <= 10) return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 10)}';
      
      case '+46': // Sweden: XX-XXX XX XX
        if (digits.length <= 2) return digits;
        if (digits.length <= 5) return '${digits.substring(0, 2)}-${digits.substring(2)}';
        if (digits.length <= 7) return '${digits.substring(0, 2)}-${digits.substring(2, 5)} ${digits.substring(5)}';
        if (digits.length <= 9) return '${digits.substring(0, 2)}-${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
        return '${digits.substring(0, 2)}-${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
      
      case '+47': // Norway: XXX XX XXX
        if (digits.length <= 3) return digits;
        if (digits.length <= 5) return '${digits.substring(0, 3)} ${digits.substring(3)}';
        if (digits.length <= 8) return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5)}';
        return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 8)}';
      
      case '+45': // Denmark: XX XX XX XX
        if (digits.length <= 2) return digits;
        if (digits.length <= 4) return '${digits.substring(0, 2)} ${digits.substring(2)}';
        if (digits.length <= 6) return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4)}';
        if (digits.length <= 8) return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6)}';
        return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)}';
      
      case '+358': // Finland: XX XXX XXXX
        if (digits.length <= 2) return digits;
        if (digits.length <= 5) return '${digits.substring(0, 2)} ${digits.substring(2)}';
        if (digits.length <= 9) return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}';
      
      case '+48': // Poland: XXX XXX XXX
        if (digits.length <= 3) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 3)} ${digits.substring(3)}';
        if (digits.length <= 9) return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';
      
      case '+420': // Czech: XXX XXX XXX
        if (digits.length <= 3) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 3)} ${digits.substring(3)}';
        if (digits.length <= 9) return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';
      
      case '+36': // Hungary: XX XXX XXXX
        if (digits.length <= 2) return digits;
        if (digits.length <= 5) return '${digits.substring(0, 2)} ${digits.substring(2)}';
        if (digits.length <= 9) return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}';
      
      case '+40': // Romania: XXX XXX XXX
        if (digits.length <= 3) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 3)} ${digits.substring(3)}';
        if (digits.length <= 9) return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';
      
      case '+212': // Morocco: XXXX-XXXXX
        if (digits.length <= 4) return digits;
        if (digits.length <= 9) return '${digits.substring(0, 4)}-${digits.substring(4)}';
        return '${digits.substring(0, 4)}-${digits.substring(4, 9)}';
      
      case '+216': // Tunisia: XX XXX XXX
        if (digits.length <= 2) return digits;
        if (digits.length <= 5) return '${digits.substring(0, 2)} ${digits.substring(2)}';
        if (digits.length <= 8) return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 8)}';
      
      case '+213': // Algeria: XXX XX XX XX
        if (digits.length <= 3) return digits;
        if (digits.length <= 5) return '${digits.substring(0, 3)} ${digits.substring(3)}';
        if (digits.length <= 7) return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5)}';
        if (digits.length <= 9) return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
        return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
      
      case '+20': // Egypt: XXXX XXX XXXX
        if (digits.length <= 4) return digits;
        if (digits.length <= 7) return '${digits.substring(0, 4)} ${digits.substring(4)}';
        if (digits.length <= 10) return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
        return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 10)}';
      
      case '+27': // South Africa: XX XXX XXXX
        if (digits.length <= 2) return digits;
        if (digits.length <= 5) return '${digits.substring(0, 2)} ${digits.substring(2)}';
        if (digits.length <= 9) return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}';
      
      case '+81': // Japan: XX-XXXX-XXXX
        if (digits.length <= 2) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 2)}-${digits.substring(2)}';
        if (digits.length <= 10) return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
        return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6, 10)}';
      
      case '+82': // South Korea: XX-XXXX-XXXX
        if (digits.length <= 2) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 2)}-${digits.substring(2)}';
        if (digits.length <= 10) return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
        return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6, 10)}';
      
      case '+86': // China: XXXX XXXX XXX
        if (digits.length <= 4) return digits;
        if (digits.length <= 8) return '${digits.substring(0, 4)} ${digits.substring(4)}';
        if (digits.length <= 11) return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8)}';
        return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8, 11)}';
      
      case '+91': // India: XXXX XXXX XX
        if (digits.length <= 4) return digits;
        if (digits.length <= 8) return '${digits.substring(0, 4)} ${digits.substring(4)}';
        if (digits.length <= 10) return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8)}';
        return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8, 10)}';
      
      case '+61': // Australia: XXXX XXX XXX
        if (digits.length <= 4) return digits;
        if (digits.length <= 7) return '${digits.substring(0, 4)} ${digits.substring(4)}';
        if (digits.length <= 10) return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
        return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 10)}';
      
      case '+64': // New Zealand: XXXX XXXX
        if (digits.length <= 4) return digits;
        if (digits.length <= 8) return '${digits.substring(0, 4)} ${digits.substring(4)}';
        return '${digits.substring(0, 4)} ${digits.substring(4, 8)}';
      
      case '+55': // Brazil: (XX) XXXX-XXXX
        if (digits.length <= 2) return digits;
        if (digits.length <= 6) return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
        if (digits.length <= 10) return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
        return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6, 10)}';
      
      case '+52': // Mexico: XX XXXX XXXX
        if (digits.length <= 2) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 2)} ${digits.substring(2)}';
        if (digits.length <= 10) return '${digits.substring(0, 2)} ${digits.substring(2, 6)} ${digits.substring(6)}';
        return '${digits.substring(0, 2)} ${digits.substring(2, 6)} ${digits.substring(6, 10)}';
      
      case '+54': // Argentina: XX XXXX-XXXX
        if (digits.length <= 2) return digits;
        if (digits.length <= 6) return '${digits.substring(0, 2)} ${digits.substring(2)}';
        if (digits.length <= 10) return '${digits.substring(0, 2)} ${digits.substring(2, 6)}-${digits.substring(6)}';
        return '${digits.substring(0, 2)} ${digits.substring(2, 6)}-${digits.substring(6, 10)}';
      
      case '+56': // Chile: X XXXX XXXX
        if (digits.length <= 1) return digits;
        if (digits.length <= 5) return '${digits.substring(0, 1)} ${digits.substring(1)}';
        if (digits.length <= 9) return '${digits.substring(0, 1)} ${digits.substring(1, 5)} ${digits.substring(5)}';
        return '${digits.substring(0, 1)} ${digits.substring(1, 5)} ${digits.substring(5, 9)}';
      
      default:
        // Default format: group by 2 digits
        if (digits.length <= 2) return digits;
        String formatted = '';
        for (int i = 0; i < digits.length; i++) {
          if (i > 0 && i % 2 == 0) formatted += ' ';
          formatted += digits[i];
        }
        return formatted;
    }
  }
}

