/// Decides whether `/users/{uid}` carries the schema fields login routing
/// needs, from the raw Firestore map.
///
/// Deliberately **excluded** from the required set:
///
/// * `phone` — optional since email signup stopped forcing SMS verification
///   (App Store Guideline 5.1.1). `createUserDocument` omits the field
///   entirely for those accounts and `patchUserDocument` never backfills it,
///   so requiring it here locked every phone-less client out of email/password
///   login with "Profil incomplet" and no way to recover.
/// * `city` — set later during onboarding (merchants) or by the
///   `LoginFlowCityRequired` picker (clients). Requiring it would short-circuit
///   that picker branch.
bool isUserProfileComplete(Map<String, dynamic> data) {
  bool hasText(Object? value) =>
      value is String && value.trim().isNotEmpty;

  final hasUid = hasText(data['uid']);
  final hasEmail = hasText(data['email']);

  // Roles: canonical `roles` map, or legacy `role` string until patched on login.
  final hasRoles = data['roles'] is Map || hasText(data['role']);

  final onboarding = data['onboarding'];
  final onboardingMerchant = onboarding is Map
      ? (onboarding['merchant'] as String?)?.trim().toLowerCase()
      : null;
  final hasOnboarding =
      onboardingMerchant == 'not_started' || onboardingMerchant == 'completed';

  final hasStatus = hasText(data['status']);
  final hasMerchantIdField = data.containsKey('merchant_id');

  return hasUid &&
      hasEmail &&
      hasRoles &&
      hasOnboarding &&
      hasStatus &&
      hasMerchantIdField;
}
