import 'package:cloud_firestore/cloud_firestore.dart';

/// Helpers so partial writes to `/users/{uid}` satisfy [firestore.rules].
///
/// Updates require `onboardingShapeValid()` and `rolesShapeValid()`. Documents
/// created before those fields existed (or with invalid shapes) cause every
/// partial update — including `cities` or `city` — to be rejected.
///
/// Legacy top-level keys `roles.client` / `roles.merchant` / `roles.provider`
/// also cause [noLegacyDottedRoleKeys] to fail unless removed.
void mergeUserPatchForFirestoreRules(
  Map<String, dynamic> existing,
  Map<String, dynamic> patch,
) {
  for (final k in const ['roles.client', 'roles.merchant', 'roles.provider']) {
    if (existing.containsKey(k)) {
      patch[k] = FieldValue.delete();
    }
  }

  if (!_existingOnboardingPassesRules(existing)) {
    final merchantId = (existing['merchant_id'] as String?)?.trim();
    final isMerchant = merchantId != null && merchantId.isNotEmpty;
    patch['onboarding'] = {
      'merchant': isMerchant ? 'completed' : 'not_started',
      'client': 'completed',
    };
  }

  if (!_existingRolesPassRules(existing)) {
    final merchantId = (existing['merchant_id'] as String?)?.trim();
    final isMerchant = merchantId != null && merchantId.isNotEmpty;
    patch['roles'] = <String, bool>{
      'client': !isMerchant,
      'merchant': isMerchant,
      'provider': isMerchant,
    };
  }
}

bool _existingOnboardingPassesRules(Map<String, dynamic> existing) {
  if (!existing.containsKey('onboarding')) return false;
  final o = existing['onboarding'];
  if (o is! Map) return false;
  final m = Map<String, dynamic>.from(o);
  if (!m.keys.every((k) => k == 'merchant' || k == 'client')) return false;
  if (m.containsKey('merchant')) {
    final v = m['merchant'];
    if (v is! String || (v != 'not_started' && v != 'completed')) {
      return false;
    }
  }
  if (m.containsKey('client')) {
    final v = m['client'];
    if (v is! String || (v != 'not_started' && v != 'completed')) {
      return false;
    }
  }
  return true;
}

bool _existingRolesPassRules(Map<String, dynamic> existing) {
  if (!existing.containsKey('roles')) return false;
  final r = existing['roles'];
  if (r is! Map) return false;
  final m = Map<String, dynamic>.from(r);
  if (!m.keys.every((k) => k == 'client' || k == 'merchant' || k == 'provider')) {
    return false;
  }
  if (m['client'] is! bool || m['merchant'] is! bool || m['provider'] is! bool) {
    return false;
  }
  return true;
}
