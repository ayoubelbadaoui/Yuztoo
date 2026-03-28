/// Storefront domain entity
/// Pure Dart - no Flutter dependencies
class Storefront {
  const Storefront({
    required this.id,
    required this.merchantName,
    required this.description,
    required this.city,
    required this.bannerImageUrl,
    required this.profileImageUrl,
    required this.loyaltyEnabled,
    required this.isVerified,
    this.isPublished = false,
    required this.profileCompletionPercentage,
    required this.weeklyViews,
    required this.weeklyViewsChange,
    this.newsContent,
    this.newsImageUrls = const [],
    this.phone,
    this.address,
    this.websiteUrl,
    this.hours,
    this.rappelsAutoClientValidation = true,
    this.rappelsAutoPassageValidation = true,
    this.rappelsMonthlyConnectedClients = 0,
    this.rappelsMonthlyValidatedPassages = 0,
  });

  final String id;
  final String merchantName;
  final String description;
  final String city;
  final String bannerImageUrl;
  final String profileImageUrl;
  final bool loyaltyEnabled;
  final bool isVerified;
  final bool isPublished;
  final int profileCompletionPercentage; // 0-100
  final int weeklyViews;
  final double weeklyViewsChange; // percentage change
  final String? newsContent;
  final List<String> newsImageUrls;
  final String? phone;
  final String? address;
  final String? websiteUrl;

  /// Business hours (Firestore map from BusinessHours.toMap())
  final Map<String, dynamic>? hours;

  /// Rappels: validation client automatique
  final bool rappelsAutoClientValidation;

  /// Rappels: validation passage automatique
  final bool rappelsAutoPassageValidation;

  /// Rappels: clients connectés ce mois (Firestore `rappels_monthly_connected_clients`)
  final int rappelsMonthlyConnectedClients;

  /// Rappels: passages validés ce mois (Firestore `rappels_monthly_validated_passages`)
  final int rappelsMonthlyValidatedPassages;
}
