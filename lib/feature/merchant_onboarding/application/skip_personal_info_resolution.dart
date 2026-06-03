/// Pure decision: should the merchant onboarding wizard skip the personal-info
/// step (owner first name, last name, date of birth) for a given user?
///
/// Used by [MerchantProfileFormScreen] when a dual-profile client upgrades
/// to merchant. The intent of the caller is to skip those steps because
/// the data is already on the client account — but skipping is **only safe**
/// when the client account actually has all three fields populated.
///
/// Treating the caller's intent as authoritative caused a silent regression:
/// a client signed-up via OTP/OAuth who never completed client onboarding had
/// `firstName / lastName / dateOfBirth = null` on `users/{uid}`, yet the
/// wizard skipped the owner-info step anyway and the new merchant doc was
/// created with the personal fields blank.
///
/// Rule: skip iff `requested && allThreePresent`. When *any* of the three
/// fields is missing the wizard shows the owner-info step instead, with
/// whatever fields *are* known prefilled — so the user only enters the
/// missing piece (e.g. a known firstName/lastName but missing DOB → step
/// shows with first/last prefilled, DOB empty).
bool resolveMerchantOnboardingSkipPersonalInfo({
  required bool requested,
  required String? firstName,
  required String? lastName,
  required DateTime? dateOfBirth,
}) {
  if (!requested) return false;
  final hasFirstName = (firstName ?? '').trim().isNotEmpty;
  final hasLastName = (lastName ?? '').trim().isNotEmpty;
  final hasDob = dateOfBirth != null;
  return hasFirstName && hasLastName && hasDob;
}
