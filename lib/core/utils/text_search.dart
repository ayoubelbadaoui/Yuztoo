/// Diacritics-insensitive, typo-tolerant matching for client-side search
/// (Découvrir, invitation de partenaires). Pure Dart — no Flutter imports —
/// so it stays unit-testable and reusable from any layer.
///
/// Design goals (feedback: « il faut que nous puissions avoir une recherche
/// approximative ») :
///   * « cafe » trouve « Café » (folding des accents) ;
///   * « boul » trouve « La Boulangerie » (préfixe de token) ;
///   * « bolangerie » trouve « Boulangerie » (1 faute tolérée dès 4 lettres,
///     2 fautes dès 7 lettres) ;
///   * les correspondances exactes/préfixes sont classées avant les
///     correspondances approximatives.
library;

/// Lowercases, folds common Latin diacritics and ligatures, and collapses
/// any non-alphanumeric run into a single space.
String normalizeForSearch(String input) {
  const fold = <String, String>{
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a',
    'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ñ': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
    'œ': 'oe', 'æ': 'ae',
  };
  final sb = StringBuffer();
  var lastWasSpace = true;
  for (final char in input.toLowerCase().split('')) {
    final folded = fold[char] ?? char;
    final isAlnum = RegExp(r'^[a-z0-9]+$').hasMatch(folded);
    if (isAlnum) {
      sb.write(folded);
      lastWasSpace = false;
    } else if (!lastWasSpace) {
      sb.write(' ');
      lastWasSpace = true;
    }
  }
  return sb.toString().trim();
}

/// Bounded Levenshtein distance: returns `maxDistance + 1` as soon as the
/// distance provably exceeds [maxDistance], so long candidates bail early.
int boundedLevenshtein(String a, String b, int maxDistance) {
  if ((a.length - b.length).abs() > maxDistance) return maxDistance + 1;
  if (a == b) return 0;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i + 1;
    var rowMin = current[0];
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      current[j + 1] = [
        current[j] + 1,
        previous[j + 1] + 1,
        previous[j] + cost,
      ].reduce((x, y) => x < y ? x : y);
      if (current[j + 1] < rowMin) rowMin = current[j + 1];
    }
    if (rowMin > maxDistance) return maxDistance + 1;
    previous = current;
  }
  return previous[b.length];
}

/// Typo budget per query token: strict under 4 letters (too noisy), 1 typo
/// from 4 letters, 2 typos from 7 letters.
int _allowedTypos(String token) {
  if (token.length >= 7) return 2;
  if (token.length >= 4) return 1;
  return 0;
}

/// Relevance of [candidate] for [query]. `0` = no match; higher = better.
///
/// Tiers (descending): normalized prefix > normalized substring > all query
/// tokens match a candidate token (prefix or within typo budget).
double fuzzyMatchScore({required String query, required String candidate}) {
  final q = normalizeForSearch(query);
  final c = normalizeForSearch(candidate);
  if (q.isEmpty || c.isEmpty) return 0;

  if (c.startsWith(q)) return 4;
  if (c.contains(q)) return 3;

  final qTokens = q.split(' ');
  final cTokens = c.split(' ');
  var total = 0.0;
  for (final qt in qTokens) {
    var best = 0.0;
    for (final ct in cTokens) {
      if (ct.startsWith(qt)) {
        best = 2;
        break;
      }
      final budget = _allowedTypos(qt);
      if (budget > 0) {
        // Compare against the candidate token trimmed to a comparable
        // length, so a short typo'd prefix still matches a longer word
        // (« bolang » → « boulangerie »).
        final ctSlice = ct.length > qt.length + budget
            ? ct.substring(0, qt.length + budget)
            : ct;
        final d = boundedLevenshtein(qt, ctSlice, budget);
        if (d <= budget) {
          final s = 1.0 - (d / (budget + 1));
          if (s > best) best = s;
        }
      }
    }
    if (best == 0) return 0; // every query token must match something
    total += best;
  }
  return total / qTokens.length; // (0, 2] — below substring tiers
}
