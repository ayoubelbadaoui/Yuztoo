import '../../../../core/utils/city_input.dart';
import '../domain/entities/auth_user.dart';
import '../domain/entities/user_profile_basics.dart';
import '../../../storefront/domain/entities/storefront.dart';

/// Display name resolution. Firestore is the source of truth for the editable
/// name, so we prefer it over Firebase Auth — otherwise edits made in
/// Informations personnelles wouldn't reflect until the next sign-in
/// (FirebaseAuth.updateDisplayName does not push a new event through the
/// authStateChanges stream, so [AuthUser] snapshots can lag arbitrarily).
///
/// Fallback order:
///   1. `basics.firstName + basics.lastName` (Firestore — source of truth)
///   2. `basics.firstName` or `basics.lastName` alone
///   3. `user.displayName` (Firebase Auth)
///   4. local part of email
///   5. literal 'Utilisateur'
String resolveDisplayName(
  AuthUser user,
  UserProfileBasics? basics,
) {
  final fn = basics?.firstName?.trim() ?? '';
  final ln = basics?.lastName?.trim() ?? '';
  if (fn.isNotEmpty && ln.isNotEmpty) return '$fn $ln';
  if (fn.isNotEmpty) return fn;
  if (ln.isNotEmpty) return ln;

  final fromUser = user.displayName?.trim();
  if (fromUser != null && fromUser.isNotEmpty) return fromUser;

  final fromEmail = (basics?.email ?? user.email)?.trim();
  if (fromEmail != null && fromEmail.isNotEmpty) {
    final at = fromEmail.indexOf('@');
    if (at > 0) return fromEmail.substring(0, at);
    return fromEmail;
  }

  return 'Utilisateur';
}

/// Prefer Firestore email, then Auth email.
String resolveEmail(AuthUser user, UserProfileBasics? basics) {
  final e = basics?.email.trim();
  if (e != null && e.isNotEmpty) return e;
  final a = user.email?.trim();
  if (a != null && a.isNotEmpty) return a;
  return '—';
}

/// City: user doc first, then commerce [storefront] for merchants (same source as vitrine).
String resolveCityForProfile(
  UserProfileBasics? basics, {
  required bool isMerchant,
  Storefront? storefront,
}) {
  final fromUserRaw = (basics?.city ?? '').trim();
  final fromUser =
      CityInput.isPlaceholder(fromUserRaw) ? '' : fromUserRaw;
  if (fromUser.isNotEmpty) return fromUser;
  if (!isMerchant || storefront == null) return '';
  final fromCommerce = storefront.city.trim();
  if (fromCommerce.isEmpty) return '';
  final lower = fromCommerce.toLowerCase();
  if (lower == 'à compléter' || lower == 'votre ville') return '';
  return fromCommerce;
}

/// Prefer Firestore phone, then Auth phone.
String resolvePhone(AuthUser user, UserProfileBasics? basics) {
  final p = basics?.phone.trim();
  if (p != null && p.isNotEmpty) return p;
  final a = user.phoneNumber?.trim();
  if (a != null && a.isNotEmpty) return a;
  return '—';
}

String avatarInitial(String displayName) {
  final t = displayName.trim();
  if (t.isEmpty) return '?';
  return t.substring(0, 1).toUpperCase();
}
