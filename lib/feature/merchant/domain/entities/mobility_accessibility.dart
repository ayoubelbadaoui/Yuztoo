/// Declared physical accessibility of a merchant premises (PMR).
enum MobilityAccessibility {
  /// Autonomous wheelchair access declared by the merchant.
  wheelchairAccessible,

  /// Access possible with help or adaptation.
  assisted,

  /// Merchant has not declared accessibility yet.
  unspecified;

  static const MobilityAccessibility defaultValue = unspecified;

  String get firestoreValue => switch (this) {
        MobilityAccessibility.wheelchairAccessible => 'wheelchair',
        MobilityAccessibility.assisted => 'assisted',
        MobilityAccessibility.unspecified => 'unspecified',
      };

  static MobilityAccessibility fromFirestore(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'wheelchair':
      case 'wheelchair_accessible':
        return MobilityAccessibility.wheelchairAccessible;
      case 'assisted':
        return MobilityAccessibility.assisted;
      case 'unspecified':
      case null:
      case '':
        return MobilityAccessibility.unspecified;
      default:
        return MobilityAccessibility.unspecified;
    }
  }

  String get title => switch (this) {
        MobilityAccessibility.wheelchairAccessible =>
          'Accessible en fauteuil roulant',
        MobilityAccessibility.assisted => 'Accessible avec assistance',
        MobilityAccessibility.unspecified => 'Accessibilité non renseignée',
      };

  String get subtitle => switch (this) {
        MobilityAccessibility.wheelchairAccessible =>
          'Accès autonome déclaré par le commerçant.',
        MobilityAccessibility.assisted =>
          'Une aide ou un aménagement est nécessaire.',
        MobilityAccessibility.unspecified => 'Informations à confirmer.',
      };

  /// Compact label for the vitrine pill.
  String get shortLabel => switch (this) {
        MobilityAccessibility.wheelchairAccessible => 'Accessible PMR',
        MobilityAccessibility.assisted => 'Accessible avec aide',
        MobilityAccessibility.unspecified => 'Accessibilité non renseignée',
      };
}
