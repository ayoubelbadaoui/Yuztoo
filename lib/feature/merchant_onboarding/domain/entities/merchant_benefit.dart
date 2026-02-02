/// Merchant benefit entity (pure Dart, no Flutter dependencies in domain)
class MerchantBenefit {
  const MerchantBenefit({
    required this.title,
    required this.description,
  });

  final String title;
  final String description; // Can contain \n for line breaks

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MerchantBenefit &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          description == other.description;

  @override
  int get hashCode => title.hashCode ^ description.hashCode;
}

