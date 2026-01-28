import '../constants/signup_constants.dart';

/// Signup form validators
class SignupValidators {
  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse e-mail est requise.';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (value.length < 8) {
      return 'Au minimum 8 caractères.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Doit contenir une majuscule.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Doit contenir une minuscule.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Doit contenir un chiffre.';
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirmez votre mot de passe.';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  /// Validate city
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'La ville est requise.';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(
    String? value,
    String countryCode,
  ) {
    // Extract only digits from the formatted value
    final currentValue = (value ?? '').replaceAll(RegExp(r'[^\d]'), '');
    if (currentValue.isEmpty) {
      return 'Le numéro est requis.';
    }
    
    // Additional regex check to ensure only numbers
    if (!RegExp(r'^[0-9]+$').hasMatch(currentValue)) {
      return 'Seuls les chiffres sont autorisés.';
    }
    
    // Country-specific length validation (using digits only)
    final expectedLength = SignupConstants.countryPhoneLengths[countryCode];
    if (expectedLength != null) {
      if (currentValue.length < expectedLength) {
        return 'Le numéro doit contenir $expectedLength chiffres.';
      }
      // Maximum allowed: expectedLength + 2 (flexibility)
      final maxLength = expectedLength + 2;
      if (currentValue.length > maxLength) {
        return 'Le numéro ne peut pas dépasser $maxLength chiffres pour ce pays.';
      }
    } else {
      // Fallback for countries not in the map
      if (currentValue.length < 8) {
        return 'Numéro invalide (minimum 8 chiffres).';
      }
      if (currentValue.length > 12) {
        return 'Le numéro ne peut pas dépasser 12 chiffres.';
      }
    }
    return null;
  }
}

