/// Merchant subcategory entity (pure Dart, no Flutter dependencies in domain)
class MerchantSubcategory {
  const MerchantSubcategory({
    required this.id,
    required this.title,
    required this.placeholderColorHex,
  });

  final String id;
  final String title; // Can contain \n for line breaks
  final String placeholderColorHex; // Store as hex string for pure Dart

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MerchantSubcategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

