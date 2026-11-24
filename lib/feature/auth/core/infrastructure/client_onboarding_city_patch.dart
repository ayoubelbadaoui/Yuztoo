import '../../../../core/domain/entities/french_commune.dart';
import '../../../../core/utils/city_input.dart';
import '../../../../core/utils/city_match.dart';

/// Firestore fields to write for the city chosen in client onboarding.
///
/// Découvrir reads the `cities` list first and only falls back to `city`
/// when that list is empty. A merchant creating their client account already
/// has `cities` (their shop city, written at shop creation), so writing only
/// `city` made Découvrir ignore the city they just picked. When a list
/// exists, the chosen city goes first and the others are kept (deduped,
/// accent / case-insensitive); `cities_metadata` is merged the same way.
Map<String, dynamic> clientOnboardingCityPatch({
  required Map<String, dynamic>? existingUserData,
  required String? city,
  FrenchCommune? commune,
}) {
  final chosen = CityInput.forFirestore(city ?? '');
  if (chosen == null) return const <String, dynamic>{};
  final key = CityMatch.key(chosen);

  final patch = <String, dynamic>{'city': chosen};
  if (commune != null) patch['city_metadata'] = commune.toFirestore();

  final rawList = existingUserData?['cities'];
  if (rawList is! List || rawList.isEmpty) return patch;

  final others = <String>[];
  final seen = <String>{key};
  for (final e in rawList) {
    final s = e?.toString().trim() ?? '';
    if (s.isEmpty || CityInput.isPlaceholder(s)) continue;
    if (seen.add(CityMatch.key(s))) others.add(s);
  }
  patch['cities'] = <String>[chosen, ...others];

  final rawMeta = existingUserData?['cities_metadata'];
  final meta = <String, dynamic>{
    if (rawMeta is Map)
      for (final e in rawMeta.entries)
        if (e.key is String && CityMatch.key(e.key as String) != key)
          e.key as String: e.value,
  };
  if (commune != null) meta[chosen] = commune.toFirestore();
  if (rawMeta is Map || commune != null) patch['cities_metadata'] = meta;
  return patch;
}
