/// Merchant category entity (pure Dart, no Flutter dependencies in domain)
class MerchantCategory {
  const MerchantCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.placeholderColorHex,
  });

  final String id;
  final String title;
  final String description;
  final String placeholderColorHex; // Store as hex string for pure Dart

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MerchantCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

