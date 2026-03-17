/// Storefront domain entity
/// Pure Dart - no Flutter dependencies
class Storefront {
  const Storefront({
    required this.id,
    required this.merchantName,
    required this.businessActivity,
    required this.bannerImageUrl,
    required this.profileImageUrl,
    required this.isVerified,
    required this.profileCompletionPercentage,
    required this.weeklyViews,
    required this.weeklyViewsChange,
    this.newsContent,
    this.phone,
    this.address,
    this.websiteUrl,
    this.hours,
    this.rappelsAutoClientValidation = true,
    this.rappelsAutoPassageValidation = true,
  });

  final String id;
  final String merchantName;
  final String businessActivity;
  final String bannerImageUrl;
  final String profileImageUrl;
  final bool isVerified;
  final int profileCompletionPercentage; // 0-100
  final int weeklyViews;
  final double weeklyViewsChange; // percentage change
  final String? newsContent;
  final String? phone;
  final String? address;
  final String? websiteUrl;
  /// Business hours (Firestore map from BusinessHours.toMap())
  final Map<String, dynamic>? hours;
  /// Rappels: validation client automatique
  final bool rappelsAutoClientValidation;
  /// Rappels: validation passage automatique
  final bool rappelsAutoPassageValidation;
}

