import 'package:equatable/equatable.dart';

import '../../../../core/utils/city_input.dart';
import 'loyalty_program_config.dart';

/// Domain representation of a merchant business entity.
/// 
/// This entity is separate from user identity and represents a business
/// that can be owned by a user.
class Merchant extends Equatable {
  const Merchant({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    this.address,
    this.categories,
    this.description,
    this.hours,
    this.status = 'inactive',
    this.createdAt,
    this.updatedAt,
    this.displayName,
    this.logoUrl,
    this.websiteUrl,
    this.bannerUrl,
    this.newsImageUrls,
    this.loyaltyEnabled = true,
    this.loyaltyProgram,
    this.messagingEnabled = true,
    this.notificationsAutoEnabled = true,
    this.galerieEnabled = true,
    this.rappelsAutoClientValidation,
    this.rappelsAutoPassageValidation,
    this.rappelsMonthlyConnectedClients = 0,
    this.rappelsMonthlyValidatedPassages = 0,
  });

  /// Unique identifier for the merchant document
  final String id;

  /// User ID of the merchant owner
  final String ownerUid;

  /// Business name
  final String name;

  /// Business email address
  final String email;

  /// Business phone number
  final String phone;

  /// City where the business is located
  final String city;

  /// Business address (optional)
  final String? address;

  /// List of business categories (optional)
  final List<String>? categories;

  /// Business description (optional)
  final String? description;

  /// Business hours (optional, typically a map or structured data)
  final Map<String, dynamic>? hours;

  /// Display name for storefront (optional, defaults to name if not set)
  final String? displayName;

  /// Logo URL from Firebase Storage (optional)
  final String? logoUrl;

  /// Website URL (optional)
  final String? websiteUrl;

  /// Banner image URL from Firebase Storage (optional)
  final String? bannerUrl;

  /// Actualite image URLs for storefront slider (optional)
  final List<String>? newsImageUrls;

  /// Loyalty program toggle (required by merchant data model).
  final bool loyaltyEnabled;

  /// Detailed loyalty settings when present on the merchant document.
  final LoyaltyProgramConfig? loyaltyProgram;

  /// Service toggle: messaging / conciergerie (default true).
  final bool messagingEnabled;

  /// Service toggle: automatic notifications (default true).
  final bool notificationsAutoEnabled;

  /// Service toggle: photo gallery visible on storefront (default true).
  final bool galerieEnabled;

  /// Rappels: auto-validate new clients (default true)
  final bool? rappelsAutoClientValidation;

  /// Rappels: auto-validate passage (default true)
  final bool? rappelsAutoPassageValidation;

  /// Rappels: clients connectés ce mois (agrégat Firestore, défaut 0)
  final int rappelsMonthlyConnectedClients;

  /// Rappels: passages validés ce mois (agrégat Firestore, défaut 0)
  final int rappelsMonthlyValidatedPassages;

  /// Merchant visibility: `active` = en ligne, `inactive` = hors ligne (défaut)
  final String status;

  /// Timestamp when the merchant was created
  final DateTime? createdAt;

  /// Timestamp when the merchant was last updated
  final DateTime? updatedAt;

  /// Résumé fidélité pour vitrine marchand et fiche client. `null` si [loyaltyEnabled] est faux.
  String? get loyaltyClientSummaryForDisplay {
    if (!loyaltyEnabled) return null;
    final config = loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
    return config.clientSummaryText;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        ownerUid,
        name,
        email,
        phone,
        city,
        address,
        categories,
        description,
        hours,
        status,
        createdAt,
        updatedAt,
        displayName,
        logoUrl,
        websiteUrl,
        bannerUrl,
        newsImageUrls,
        loyaltyEnabled,
        loyaltyProgram,
        messagingEnabled,
        notificationsAutoEnabled,
        galerieEnabled,
        rappelsAutoClientValidation,
        rappelsAutoPassageValidation,
        rappelsMonthlyConnectedClients,
        rappelsMonthlyValidatedPassages,
      ];

  /// Creates a copy of the merchant with updated fields
  Merchant copyWith({
    String? id,
    String? ownerUid,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? address,
    List<String>? categories,
    String? description,
    Map<String, dynamic>? hours,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? displayName,
    String? logoUrl,
    String? websiteUrl,
    String? bannerUrl,
    List<String>? newsImageUrls,
    bool? loyaltyEnabled,
    LoyaltyProgramConfig? loyaltyProgram,
    bool? messagingEnabled,
    bool? notificationsAutoEnabled,
    bool? galerieEnabled,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
    int? rappelsMonthlyConnectedClients,
    int? rappelsMonthlyValidatedPassages,
  }) {
    return Merchant(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      categories: categories ?? this.categories,
      description: description ?? this.description,
      hours: hours ?? this.hours,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayName: displayName ?? this.displayName,
      logoUrl: logoUrl ?? this.logoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      newsImageUrls: newsImageUrls ?? this.newsImageUrls,
      loyaltyEnabled: loyaltyEnabled ?? this.loyaltyEnabled,
      loyaltyProgram: loyaltyProgram ?? this.loyaltyProgram,
      messagingEnabled: messagingEnabled ?? this.messagingEnabled,
      notificationsAutoEnabled:
          notificationsAutoEnabled ?? this.notificationsAutoEnabled,
      galerieEnabled: galerieEnabled ?? this.galerieEnabled,
      rappelsAutoClientValidation:
          rappelsAutoClientValidation ?? this.rappelsAutoClientValidation,
      rappelsAutoPassageValidation:
          rappelsAutoPassageValidation ?? this.rappelsAutoPassageValidation,
      rappelsMonthlyConnectedClients:
          rappelsMonthlyConnectedClients ?? this.rappelsMonthlyConnectedClients,
      rappelsMonthlyValidatedPassages:
          rappelsMonthlyValidatedPassages ?? this.rappelsMonthlyValidatedPassages,
    );
  }

  /// Validates that required fields are not empty
  bool isValid() {
    return id.isNotEmpty &&
        ownerUid.isNotEmpty &&
        name.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty &&
        city.isNotEmpty &&
        !CityInput.isPlaceholder(city) &&
        status.isNotEmpty;
  }
}

