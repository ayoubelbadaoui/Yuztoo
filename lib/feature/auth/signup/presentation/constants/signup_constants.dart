import 'package:flutter/material.dart';

/// Constants used in the signup screen
class SignupConstants {
  // Colors - Exact Yuztoo theme
  static const Color bgDark1 = Color(0xFF0F1A29);
  static const Color bgDark2 = Color(0xFF111A2A);
  static const Color primaryGold = Color(0xFFD4A017);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF2A3F5F);
  static const Color cardBg = Color(0xFF1A2A3A);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF27AE60);

  // Country codes list
  static const List<Map<String, String>> countryCodes = [
    {'code': '+33', 'name': 'France', 'flag': '🇫🇷'},
    {'code': '+1', 'name': 'États-Unis', 'flag': '🇺🇸'},
    {'code': '+44', 'name': 'Royaume-Uni', 'flag': '🇬🇧'},
    {'code': '+34', 'name': 'Espagne', 'flag': '🇪🇸'},
    {'code': '+49', 'name': 'Allemagne', 'flag': '🇩🇪'},
    {'code': '+39', 'name': 'Italie', 'flag': '🇮🇹'},
    {'code': '+31', 'name': 'Pays-Bas', 'flag': '🇳🇱'},
    {'code': '+32', 'name': 'Belgique', 'flag': '🇧🇪'},
    {'code': '+41', 'name': 'Suisse', 'flag': '🇨🇭'},
    {'code': '+43', 'name': 'Autriche', 'flag': '🇦🇹'},
    {'code': '+351', 'name': 'Portugal', 'flag': '🇵🇹'},
    {'code': '+30', 'name': 'Grèce', 'flag': '🇬🇷'},
    {'code': '+46', 'name': 'Suède', 'flag': '🇸🇪'},
    {'code': '+47', 'name': 'Norvège', 'flag': '🇳🇴'},
    {'code': '+45', 'name': 'Danemark', 'flag': '🇩🇰'},
    {'code': '+358', 'name': 'Finlande', 'flag': '🇫🇮'},
    {'code': '+48', 'name': 'Pologne', 'flag': '🇵🇱'},
    {'code': '+420', 'name': 'République tchèque', 'flag': '🇨🇿'},
    {'code': '+36', 'name': 'Hongrie', 'flag': '🇭🇺'},
    {'code': '+40', 'name': 'Roumanie', 'flag': '🇷🇴'},
    {'code': '+212', 'name': 'Maroc', 'flag': '🇲🇦'},
    {'code': '+216', 'name': 'Tunisie', 'flag': '🇹🇳'},
    {'code': '+213', 'name': 'Algérie', 'flag': '🇩🇿'},
    {'code': '+20', 'name': 'Égypte', 'flag': '🇪🇬'},
    {'code': '+27', 'name': 'Afrique du Sud', 'flag': '🇿🇦'},
    {'code': '+81', 'name': 'Japon', 'flag': '🇯🇵'},
    {'code': '+82', 'name': 'Corée du Sud', 'flag': '🇰🇷'},
    {'code': '+86', 'name': 'Chine', 'flag': '🇨🇳'},
    {'code': '+91', 'name': 'Inde', 'flag': '🇮🇳'},
    {'code': '+61', 'name': 'Australie', 'flag': '🇦🇺'},
    {'code': '+64', 'name': 'Nouvelle-Zélande', 'flag': '🇳🇿'},
    {'code': '+55', 'name': 'Brésil', 'flag': '🇧🇷'},
    {'code': '+52', 'name': 'Mexique', 'flag': '🇲🇽'},
    {'code': '+54', 'name': 'Argentine', 'flag': '🇦🇷'},
    {'code': '+56', 'name': 'Chili', 'flag': '🇨🇱'},
  ];

  // Phone number length requirements by country code (national number length, excluding country code)
  static const Map<String, int> countryPhoneLengths = {
    '+33': 9,   // France: 9 digits
    '+1': 10,   // US/Canada: 10 digits
    '+44': 10,  // UK: 10 digits
    '+34': 9,   // Spain: 9 digits
    '+49': 10,  // Germany: 10-11 digits (using 10 as minimum)
    '+39': 9,   // Italy: 9-10 digits (using 9 as minimum)
    '+31': 9,   // Netherlands: 9 digits
    '+32': 9,   // Belgium: 9 digits
    '+41': 9,   // Switzerland: 9 digits
    '+43': 10,  // Austria: 10-13 digits (using 10 as minimum)
    '+351': 9,  // Portugal: 9 digits
    '+30': 10,  // Greece: 10 digits
    '+46': 9,   // Sweden: 9 digits
    '+47': 8,   // Norway: 8 digits
    '+45': 8,   // Denmark: 8 digits
    '+358': 9,  // Finland: 9-10 digits (using 9 as minimum)
    '+48': 9,   // Poland: 9 digits
    '+420': 9,  // Czech Republic: 9 digits
    '+36': 9,   // Hungary: 9 digits
    '+40': 9,   // Romania: 9-10 digits (using 9 as minimum)
    '+212': 9,  // Morocco: 9 digits
    '+216': 8,  // Tunisia: 8 digits
    '+213': 9,  // Algeria: 9 digits
    '+20': 10,  // Egypt: 10 digits
    '+27': 9,   // South Africa: 9 digits
    '+81': 10,  // Japan: 10 digits
    '+82': 9,   // South Korea: 9-10 digits (using 9 as minimum)
    '+86': 11,  // China: 11 digits
    '+91': 10,  // India: 10 digits
    '+61': 9,   // Australia: 9 digits
    '+64': 8,   // New Zealand: 8-9 digits (using 8 as minimum)
    '+55': 10,  // Brazil: 10-11 digits (using 10 as minimum)
    '+52': 10,  // Mexico: 10 digits
    '+54': 10,  // Argentina: 10 digits
    '+56': 9,   // Chile: 9 digits
  };

  // Phone number format hints by country code
  static const Map<String, String> countryPhoneHints = {
    '+33': '612345678',
    '+1': '5551234567',
    '+44': '7912345678',
    '+34': '612345678',
    '+49': '15123456789',
    '+39': '3123456789',
    '+31': '612345678',
    '+32': '470123456',
    '+41': '791234567',
    '+43': '6641234567',
    '+351': '912345678',
    '+30': '6912345678',
    '+46': '701234567',
    '+47': '91234567',
    '+45': '20123456',
    '+358': '501234567',
    '+48': '512345678',
    '+420': '601123456',
    '+36': '201234567',
    '+40': '712345678',
    '+212': '612345678',
    '+216': '20123456',
    '+213': '551234567',
    '+20': '1001234567',
    '+27': '821234567',
    '+81': '9012345678',
    '+82': '1012345678',
    '+86': '13812345678',
    '+91': '9876543210',
    '+61': '412345678',
    '+64': '211234567',
    '+55': '11987654321',
    '+52': '5512345678',
    '+54': '9112345678',
    '+56': '912345678',
  };
}

