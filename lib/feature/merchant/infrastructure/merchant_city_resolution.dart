import '../../../core/utils/city_input.dart';

/// Normalizes a city label for Firestore (`merchants.city`, `users.city`).
String? persistableMerchantCity(String? raw) => CityInput.forFirestore(raw ?? '');

/// Merges [persistedCity] into the owner's `users.cities` list (and legacy `city`).
List<String> mergedOwnerConnectedCities({
  required Map<String, dynamic>? existingUserData,
  required String persistedCity,
}) {
  final cities = <String>{};
  final rawList = existingUserData?['cities'];
  if (rawList is List) {
    for (final e in rawList) {
      final s = e?.toString().trim();
      if (s != null && s.isNotEmpty && !CityInput.isPlaceholder(s)) {
        cities.add(s);
      }
    }
  }
  final legacy = (existingUserData?['city'] as String?)?.trim();
  if (legacy != null &&
      legacy.isNotEmpty &&
      !CityInput.isPlaceholder(legacy)) {
    cities.add(legacy);
  }
  cities.add(persistedCity);
  return cities.toList();
}

/// Resolves [Merchant.city] when creating `merchants/{id}` after onboarding.
///
/// If onboarding passes an empty or placeholder value but signup stored a real
/// city on `users/{uid}.city`, that signup city is used so the merchant profile
/// matches inscription.
String resolveMerchantCityForCreation({
  required String incomingMerchantCity,
  required String signupCityFromUserDoc,
}) {
  final signup = signupCityFromUserDoc.trim();
  final incoming = incomingMerchantCity.trim();

  if (incoming.isNotEmpty && !CityInput.isPlaceholder(incoming)) {
    return incoming;
  }
  if (signup.isNotEmpty && !CityInput.isPlaceholder(signup)) {
    return signup;
  }
  return '';
}
