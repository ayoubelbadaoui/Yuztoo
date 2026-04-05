import '../domain/entities/auth_user.dart';
import '../domain/entities/user_profile_basics.dart';
import '../../../storefront/domain/entities/storefront.dart';

/// Display name: Firestore / Auth display name, else email local part, else fallback.
String resolveDisplayName(
  AuthUser user,
  UserProfileBasics? basics,
) {
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
  final fromUser = (basics?.city ?? '').trim();
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
