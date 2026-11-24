/// Tolerant city-name matching for Découvrir.
///
/// Merchant and client city labels are free text on legacy documents
/// (`Belfort/ andelnans`, `Chatenois les Forges`, `ST-DIZIER-L'EVEQUE`…),
/// while département peers come from geo.api.gouv.fr with official spelling
/// (`Châtenois-les-Forges`, `Saint-Dizier-l'Évêque`). Comparing raw lowercase
/// strings silently hid those stores, so every comparison goes through [key].
class CityMatch {
  const CityMatch._();

  static const Map<String, String> _accents = <String, String>{
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'œ': 'oe',
    'æ': 'ae',
  };

  static final RegExp _separators = RegExp(r"[-'’‘`_.]+");
  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _listSeparators = RegExp(r'[/,;&+|]');

  /// Comparison key: lowercase, no accents, hyphens / apostrophes as spaces,
  /// `st` / `ste` expanded to `saint` / `sainte`.
  static String key(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return '';
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_accents[ch] ?? ch);
    }
    final words = buffer
        .toString()
        .replaceAll(_separators, ' ')
        .trim()
        .split(_spaces)
        .where((w) => w.isNotEmpty)
        .map((w) => switch (w) {
              'st' => 'saint',
              'ste' => 'sainte',
              _ => w,
            });
    return words.join(' ');
  }

  /// Keys a stored city label can match: the whole label plus each part of a
  /// multi-city label (`Belfort/ andelnans` → belfort, andelnans).
  static Set<String> candidateKeys(String raw) {
    final out = <String>{};
    final whole = key(raw);
    if (whole.isNotEmpty) out.add(whole);
    if (_listSeparators.hasMatch(raw)) {
      for (final part in raw.split(_listSeparators)) {
        final k = key(part);
        if (k.isNotEmpty) out.add(k);
      }
    }
    return out;
  }
}

/// `city_keys` stored on a merchant document: the keys of its city label plus
/// the official commune name, sorted. Must match `merchantCityKeys` in
/// functions/src/merchant_city_keys_core.ts (the sync trigger), or a shop's
/// stored keys and a client's local-area keys stop meeting.
List<String> merchantCityKeys(String city, {String? communeName}) {
  final keys = <String>{
    ...CityMatch.candidateKeys(city),
    if (communeName != null) ...CityMatch.candidateKeys(communeName),
  };
  return keys.toList()..sort();
}
