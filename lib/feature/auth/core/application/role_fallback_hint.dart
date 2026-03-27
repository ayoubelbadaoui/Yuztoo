import '../../../../types.dart';

/// Resolves a role hint from embedded profile data on [AuthUser].
///
/// [primaryRole] is signup intent (`users/{uid}.primary_role`) and **wins** over
/// [roles] flags (e.g. temporary client UI) and stale prefs.
///
/// Returns null when ambiguous so callers can fall back to [RoleCacheService].
UserRole? roleHintFromAuthUserData({
  String? primaryRole,
  required Map<String, bool>? roles,
  required String roleString,
}) {
  final p = primaryRole?.toLowerCase();
  if (p == 'merchant') return UserRole.merchant;
  if (p == 'client') return UserRole.client;

  final r = roles;
  if (r != null) {
    if (r['merchant'] == true) return UserRole.merchant;
    if (r['client'] == true) return UserRole.client;
    return null;
  }
  if (roleString.toLowerCase() == 'merchant') return UserRole.merchant;
  return null;
}
