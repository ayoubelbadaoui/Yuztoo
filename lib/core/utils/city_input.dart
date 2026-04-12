/// City form + Firestore: never treat UI placeholders as real locations.
class CityInput {
  CityInput._();

  /// True when empty or known placeholder copy (any casing).
  static bool isPlaceholder(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return true;
    final lower = t.toLowerCase();
    return lower == 'votre ville' || lower == 'à compléter';
  }

  /// Value safe to write to Firestore, or `null` to omit / clear placeholder data.
  static String? forFirestore(String raw) {
    if (isPlaceholder(raw)) return null;
    return raw.trim();
  }

  /// Text for the edit field: real city or the default hint (never "À compléter").
  static String forEditField(String? fromFirestore, {String hint = 'Votre ville'}) {
    if (fromFirestore == null) return hint;
    final t = fromFirestore.trim();
    if (t.isEmpty || isPlaceholder(t)) return hint;
    return t;
  }
}
