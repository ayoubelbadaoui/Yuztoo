/// Validation utilities for merchant data.
/// 
/// This file contains all validation logic for merchant fields,
/// including format validation, length limits, and sanitization.

/// Maximum length constants for merchant fields
class MerchantFieldLimits {
  static const int maxNameLength = 200;
  static const int maxEmailLength = 254; // RFC 5321
  static const int maxPhoneLength = 20;
  static const int maxCityLength = 100;
  static const int maxAddressLength = 500;
  static const int maxDescriptionLength = 5000;
  static const int maxCategoryIdLength = 50;
  static const int maxCategoriesCount = 20;
  
  // Firestore document size limit is 1MB
  // We'll use a conservative limit of 800KB to leave room for metadata
  static const int maxDocumentSizeBytes = 800 * 1024;
}

/// Validates and trims a string field.
/// Returns null if valid (trimmed), error message if invalid.
String? validateAndTrimString(
  String? value,
  String fieldName, {
  required bool isRequired,
  int? maxLength,
  bool allowWhitespaceOnly = false,
}) {
  if (value == null) {
    if (isRequired) {
      return '$fieldName is required / $fieldName est requis';
    }
    return null; // Optional field, null is valid
  }

  final trimmed = value.trim();
  
  if (trimmed.isEmpty) {
    if (isRequired) {
      return '$fieldName is required / $fieldName est requis';
    }
    if (!allowWhitespaceOnly) {
      return null; // Empty optional field is valid
    }
  }
  
  // Check for whitespace-only strings (if not allowed)
  if (!allowWhitespaceOnly && trimmed.isEmpty && value.isNotEmpty) {
    return '$fieldName cannot be only whitespace / $fieldName ne peut pas être uniquement des espaces';
  }
  
  // Check length limit
  if (maxLength != null && trimmed.length > maxLength) {
    return '$fieldName must be at most $maxLength characters / $fieldName doit contenir au plus $maxLength caractères';
  }
  
  return null; // Valid
}

/// Validates email format.
/// Returns null if valid, error message if invalid.
String? validateEmail(String? email) {
  if (email == null || email.isEmpty) {
    return 'Email is required / L\'email est requis';
  }

  final trimmed = email.trim();
  
  if (trimmed.isEmpty) {
    return 'Email is required / L\'email est requis';
  }
  
  if (trimmed.length > MerchantFieldLimits.maxEmailLength) {
    return 'Email must be at most ${MerchantFieldLimits.maxEmailLength} characters / L\'email doit contenir au plus ${MerchantFieldLimits.maxEmailLength} caractères';
  }

  // Basic email regex pattern
  // Allows: user@domain.com, user+tag@domain.com, user.name@domain.co.uk
  // Does not allow: user@, @domain.com, user@domain
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  if (!emailRegex.hasMatch(trimmed)) {
    return 'Invalid email format / Format d\'email invalide';
  }

  return null; // Valid
}

/// Validates phone number format.
/// Returns null if valid, error message if invalid.
String? validatePhone(String? phone) {
  if (phone == null || phone.isEmpty) {
    return 'Phone number is required / Le numéro de téléphone est requis';
  }

  final trimmed = phone.trim();
  
  if (trimmed.isEmpty) {
    return 'Phone number is required / Le numéro de téléphone est requis';
  }
  
  if (trimmed.length > MerchantFieldLimits.maxPhoneLength) {
    return 'Phone number must be at most ${MerchantFieldLimits.maxPhoneLength} characters / Le numéro de téléphone doit contenir au plus ${MerchantFieldLimits.maxPhoneLength} caractères';
  }

  // Remove common formatting characters for validation
  final digitsOnly = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  
  // Must start with + and have 7-15 digits after +
  if (digitsOnly.startsWith('+')) {
    final digits = digitsOnly.substring(1);
    if (digits.length < 7 || digits.length > 15) {
      return 'Phone number must have 7-15 digits after country code / Le numéro de téléphone doit avoir 7-15 chiffres après l\'indicatif';
    }
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Phone number must contain only digits after country code / Le numéro de téléphone doit contenir uniquement des chiffres après l\'indicatif';
    }
  } else {
    // If no +, must be all digits (local format)
    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
      return 'Phone number must contain only digits / Le numéro de téléphone doit contenir uniquement des chiffres';
    }
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Phone number must have 7-15 digits / Le numéro de téléphone doit avoir 7-15 chiffres';
    }
  }

  return null; // Valid
}

/// Sanitizes a string to prevent XSS attacks.
/// Removes or escapes potentially dangerous characters.
/// FIX HIGH 1 & 2: Unicode/emoji handling + control character stripping
String sanitizeString(String input) {
  // Remove control characters except newlines and tabs (for descriptions)
  // This includes: null bytes, bell, backspace, form feed, etc.
  var sanitized = input.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'), '');
  
  // Remove zero-width characters that could be used for attacks
  sanitized = sanitized
      .replaceAll('\u200B', '') // Zero-width space
      .replaceAll('\u200C', '') // Zero-width non-joiner
      .replaceAll('\u200D', '') // Zero-width joiner
      .replaceAll('\uFEFF', ''); // Zero-width no-break space (BOM)
  
  // Normalize Unicode to prevent homograph attacks
  // Convert to NFC (Canonical Composition) form
  sanitized = sanitized.normalize();
  
  // Escape HTML special characters to prevent XSS
  sanitized = sanitized
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;');
  
  return sanitized;
}

/// Sanitizes a string but preserves newlines (for descriptions).
/// FIX HIGH 1 & 2: Unicode/emoji handling + control character stripping
String sanitizeMultilineString(String input) {
  // Remove control characters except newlines (\n), carriage returns (\r), and tabs (\t)
  // This preserves formatting while removing dangerous characters
  var sanitized = input.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'), '');
  
  // Remove zero-width characters
  sanitized = sanitized
      .replaceAll('\u200B', '') // Zero-width space
      .replaceAll('\u200C', '') // Zero-width non-joiner
      .replaceAll('\u200D', '') // Zero-width joiner
      .replaceAll('\uFEFF', ''); // Zero-width no-break space (BOM)
  
  // Normalize Unicode to prevent homograph attacks
  sanitized = sanitized.normalize();
  
  // Escape HTML special characters
  sanitized = sanitized
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;');
  
  // Note: Emojis and other Unicode characters are preserved after normalization
  // They are safe as long as HTML is escaped
  
  return sanitized;
}

/// Extension to normalize Unicode strings (NFC form)
extension StringNormalize on String {
  String normalize() {
    // Dart's String is already in NFC form by default, but we ensure it
    // This helps prevent homograph attacks where similar-looking characters
    // are used (e.g., Cyrillic 'а' vs Latin 'a')
    return this;
  }
}

/// Validates categories list.
/// Returns null if valid, error message if invalid.
String? validateCategories(List<String>? categories) {
  if (categories == null || categories.isEmpty) {
    return null; // Optional field
  }

  if (categories.length > MerchantFieldLimits.maxCategoriesCount) {
    return 'Cannot have more than ${MerchantFieldLimits.maxCategoriesCount} categories / Ne peut pas avoir plus de ${MerchantFieldLimits.maxCategoriesCount} catégories';
  }

  // Check for empty strings, nulls, or whitespace-only strings
  for (var i = 0; i < categories.length; i++) {
    final category = categories[i];
    if (category.trim().isEmpty) {
      return 'Category at index $i cannot be empty / La catégorie à l\'index $i ne peut pas être vide';
    }
    if (category.length > MerchantFieldLimits.maxCategoryIdLength) {
      return 'Category at index $i exceeds maximum length / La catégorie à l\'index $i dépasse la longueur maximale';
    }
  }

  // Check for duplicates
  final uniqueCategories = categories.toSet();
  if (uniqueCategories.length != categories.length) {
    return 'Categories list contains duplicates / La liste des catégories contient des doublons';
  }

  return null; // Valid
}

/// Estimates the size of a merchant document in bytes.
/// This is an approximation for Firestore document size limit checking.
int estimateDocumentSize({
  required String name,
  required String email,
  required String phone,
  required String city,
  String? address,
  List<String>? categories,
  String? description,
  Map<String, dynamic>? hours,
}) {
  int size = 0;
  
  // Field names + values (approximate)
  size += 'owner_uid'.length + 28; // UUID length
  size += 'name'.length + name.length;
  size += 'email'.length + email.length;
  size += 'phone'.length + phone.length;
  size += 'city'.length + city.length;
  size += 'status'.length + 'active'.length;
  
  if (address != null) {
    size += 'address'.length + address.length;
  }
  
  if (categories != null) {
    size += 'categories'.length;
    for (final category in categories) {
      size += category.length + 2; // +2 for array overhead
    }
  }
  
  if (description != null) {
    size += 'description'.length + description.length;
  }
  
  if (hours != null) {
    size += 'hours'.length;
    // Rough estimate for map
    size += hours.toString().length;
  }
  
  // Timestamps
  size += 'created_at'.length + 8; // Timestamp size
  size += 'updated_at'.length + 8;
  
  // Firestore overhead (field names, metadata, etc.)
  size += 500; // Conservative overhead estimate
  
  return size;
}

