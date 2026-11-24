/// Offline-capable launch basins for Découvrir (see
/// `docs/product/DISCOVERY_BASINS.md`).
///
/// * Territoire de Belfort (90) → whole département (handled by
///   [CityAgglomerationExpander.wholeDepartments] + bundled dept list).
/// * Pays d'Héricourt / Pays de Montbéliard Agglomération → EPCI peer lists
///   so geo.api.gouv.fr downtime never collapses Découvrir to exact-match.
library;

import 'city_match.dart';

/// Official EPCI code → commune display names (geo.api.gouv.fr, 2026-11-24).
const Map<String, List<String>> bundledEpciCommunes =
    <String, List<String>>{
  // CC du Pays d'Héricourt
  '247000722': <String>[
    'Aibre',
    'Belverne',
    'Brevilliers',
    'Chagey',
    'Champey',
    'Chavanne',
    'Chenebier',
    'Châlonvillars',
    'Coisevaux',
    'Courmont',
    'Couthenans',
    'Héricourt',
    'Laire',
    'Le Vernoy',
    'Luze',
    'Mandrevillars',
    'Saulnot',
    'Trémoins',
    'Verlans',
    'Villers-sur-Saulnot',
    'Vyans-le-Val',
    'Échenans-sous-Mont-Vaudois',
    'Étobon',
  ],
  // Pays de Montbéliard Agglomération
  '200065647': <String>[
    'Abbévillers',
    'Allenjoie',
    'Allondans',
    'Arbouans',
    'Audincourt',
    'Autechaux-Roide',
    'Badevel',
    'Bart',
    'Bavans',
    'Berche',
    'Bethoncourt',
    'Beutal',
    'Blamont',
    'Bondeval',
    'Bourguignon',
    'Bretigney',
    'Brognard',
    'Colombier-Fontaine',
    'Courcelles-lès-Montbéliard',
    'Dambelin',
    'Dambenois',
    'Dampierre-les-Bois',
    'Dampierre-sur-le-Doubs',
    'Dampjoux',
    'Dannemarie',
    'Dasle',
    'Dung',
    'Exincourt',
    'Fesches-le-Châtel',
    'Feule',
    'Glay',
    'Goux-lès-Dambelin',
    'Grand-Charmont',
    'Hérimoncourt',
    'Issans',
    'Longevelle-sur-Doubs',
    'Lougres',
    'Mandeure',
    'Mathay',
    'Meslières',
    'Montbéliard',
    'Montenois',
    'Neuchâtel-Urtière',
    'Noirefontaine',
    'Nommay',
    'Pierrefontaine-lès-Blamont',
    'Pont-de-Roide-Vermondans',
    'Présentevillers',
    'Raynans',
    'Roches-lès-Blamont',
    'Rémondans-Vaivre',
    'Saint-Julien-lès-Montbéliard',
    'Saint-Maurice-Colombier',
    'Sainte-Marie',
    'Sainte-Suzanne',
    'Seloncourt',
    'Semondans',
    'Sochaux',
    'Solemont',
    'Taillecourt',
    'Thulay',
    'Valentigney',
    'Vandoncourt',
    'Vieux-Charmont',
    'Villars-lès-Blamont',
    'Villars-sous-Dampjoux',
    'Villars-sous-Écot',
    'Voujeaucourt',
    'Échenans',
    'Écot',
    'Écurcey',
    'Étouvans',
    'Étupes',
  ],
};

/// Commune key ([CityMatch.key]) → EPCI code for launch-area hubs.
/// Built from [bundledEpciCommunes] so offline resolve can attach `epciCode`.
final Map<String, String> bundledCommuneEpciCode = () {
  final out = <String, String>{};
  for (final entry in bundledEpciCommunes.entries) {
    for (final name in entry.value) {
      out[CityMatch.key(name)] = entry.key;
    }
  }
  return Map<String, String>.unmodifiable(out);
}();

/// Bundled peer names for [epciCode], or empty if unknown.
List<String> bundledCommunesForEpci(String epciCode) {
  final code = epciCode.trim();
  if (code.isEmpty) return const <String>[];
  return List<String>.unmodifiable(
    bundledEpciCommunes[code] ?? const <String>[],
  );
}
