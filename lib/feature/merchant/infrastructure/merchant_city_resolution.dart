import '../../../core/utils/city_input.dart';

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
  if (CityInput.isPlaceholder(incomingMerchantCity) && signup.isNotEmpty) {
    return signup;
  }
  return incomingMerchantCity.trim();
}
