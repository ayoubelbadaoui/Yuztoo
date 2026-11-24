/// Example strings older builds wrote into merchant profile fields as if they
/// were real data. They must never be shown as values nor saved again.
abstract final class ProfilePlaceholders {
  static const Set<String> legacyValues = {
    'Décrivez votre activité en quelques lignes.',
    '+33 6 12 34 56 78',
    '+33123456789',
    'www.votresite.com',
    'Votre adresse',
    'Nom du commerce',
  };

  /// True when [value] is empty or one of [legacyValues].
  static bool isPlaceholder(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty || legacyValues.contains(trimmed);
  }

  /// The real value, or `''` when [value] is empty / a legacy placeholder.
  static String clean(String? value) =>
      isPlaceholder(value) ? '' : value!.trim();
}
