import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/core/utils/text_search.dart';

void main() {
  group('normalizeForSearch', () {
    test('lowercases and folds French diacritics', () {
      expect(normalizeForSearch('Café'), 'cafe');
      expect(normalizeForSearch('Épicerie Crèmerie'), 'epicerie cremerie');
      expect(normalizeForSearch('Bœuf & Cie'), 'boeuf cie');
      expect(normalizeForSearch('Çà et Là'), 'ca et la');
    });

    test('collapses punctuation and whitespace runs', () {
      expect(normalizeForSearch("  L'Atelier -- du   Pain  "),
          'l atelier du pain');
    });

    test('empty / symbol-only input yields empty string', () {
      expect(normalizeForSearch(''), '');
      expect(normalizeForSearch('!!! ---'), '');
    });
  });

  group('boundedLevenshtein', () {
    test('exact and simple edits', () {
      expect(boundedLevenshtein('cafe', 'cafe', 2), 0);
      expect(boundedLevenshtein('cafe', 'caf', 2), 1);
      expect(boundedLevenshtein('cafe', 'cave', 2), 1);
    });

    test('bails out past maxDistance', () {
      expect(boundedLevenshtein('abc', 'xyzxyz', 1), greaterThan(1));
    });
  });

  group('fuzzyMatchScore', () {
    test('« cafe » matches « Café » (accents)', () {
      expect(fuzzyMatchScore(query: 'cafe', candidate: 'Café'),
          greaterThan(0));
    });

    test('substring still matches: « boulangerie » in « La Boulangerie »',
        () {
      expect(
        fuzzyMatchScore(query: 'boulangerie', candidate: 'La Boulangerie'),
        greaterThan(0),
      );
    });

    test('token prefix matches: « boul » finds « La Boulangerie du Café »',
        () {
      expect(
        fuzzyMatchScore(
            query: 'boul', candidate: 'La Boulangerie du Café'),
        greaterThan(0),
      );
    });

    test('one typo tolerated from 4 letters: « bolangerie »', () {
      expect(
        fuzzyMatchScore(query: 'bolangerie', candidate: 'Boulangerie'),
        greaterThan(0),
      );
    });

    test('short tokens stay strict (no typo budget under 4 letters)', () {
      expect(fuzzyMatchScore(query: 'bar', candidate: 'Bor'), 0);
      // But exact short prefixes still work.
      expect(fuzzyMatchScore(query: 'bar', candidate: 'Barbier'),
          greaterThan(0));
    });

    test('unrelated query does not match', () {
      expect(fuzzyMatchScore(query: 'pizzeria', candidate: 'Boulangerie'), 0);
    });

    test('every query token must match: partial token sets are rejected', () {
      expect(
        fuzzyMatchScore(
            query: 'boulangerie martienne', candidate: 'Boulangerie Dupont'),
        0,
      );
    });

    test('prefix > substring > approximate ranking', () {
      final prefix =
          fuzzyMatchScore(query: 'boulangerie', candidate: 'Boulangerie Centre');
      final substring =
          fuzzyMatchScore(query: 'boulangerie', candidate: 'La Boulangerie');
      final fuzzy =
          fuzzyMatchScore(query: 'bolangerie', candidate: 'Boulangerie');
      expect(prefix, greaterThan(substring));
      expect(substring, greaterThan(fuzzy));
    });
  });
}
