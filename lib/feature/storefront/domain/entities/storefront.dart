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
}

