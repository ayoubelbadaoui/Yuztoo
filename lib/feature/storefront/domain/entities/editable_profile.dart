/// Editable storefront profile data
/// Pure Dart - no Flutter dependencies
class EditableProfile {
  const EditableProfile({
    required this.bannerImageUrl,
    required this.profileImageUrl,
    required this.businessName,
    required this.category,
    required this.description,
    required this.phoneNumber,
    required this.websiteUrl,
    required this.physicalAddress,
  });

  final String bannerImageUrl;
  final String profileImageUrl;
  final String businessName;
  final String category;
  final String description;
  final String phoneNumber;
  final String websiteUrl;
  final String physicalAddress;

  EditableProfile copyWith({
    String? bannerImageUrl,
    String? profileImageUrl,
    String? businessName,
    String? category,
    String? description,
    String? phoneNumber,
    String? websiteUrl,
    String? physicalAddress,
  }) {
    return EditableProfile(
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      description: description ?? this.description,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      physicalAddress: physicalAddress ?? this.physicalAddress,
    );
  }
}

