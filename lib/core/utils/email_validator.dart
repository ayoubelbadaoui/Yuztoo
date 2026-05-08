/// Lightweight email validation used for merchant contact-email collection
/// and migration prompts. Intentionally pragmatic — the goal is to catch
/// typos and obvious garbage, not to RFC-5322 the user. Final validation
/// happens server-side (Firestore rules + auth).
class EmailValidator {
  /// Sentinel value that older builds wrote into `merchants/{id}.email` when
  /// no email was collected at signup. The migration banner keys off this
  /// to detect unfinished onboarding emails. Treat as a private constant —
  /// callers must use [isPlaceholderOrEmpty] rather than comparing strings.
  static const String _legacyPlaceholder = 'demo@example.com';

  /// Pragmatic regex: `local@domain.tld` with at least one dot in the
  /// domain, no spaces, no consecutive dots, ASCII only. Permissive about
  /// local-part characters because professionals use plus addressing,
  /// dots, dashes, etc. Disallows trailing/leading dots in the local part
  /// (a common typo source).
  static final RegExp _re = RegExp(
    r'^(?!\.)(?!.*\.\.)[A-Za-z0-9._%+\-]+(?<!\.)@'
    r'[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?)+$',
  );

  /// `true` when [value] looks like a deliverable email address.
  /// Trims and lower-cases internally — callers don't need to normalise.
  static bool isValid(String? value) {
    if (value == null) return false;
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return false;
    if (v.length > 254) return false;
    return _re.hasMatch(v);
  }

  /// `true` when [value] is empty, whitespace-only, or the legacy
  /// `demo@example.com` placeholder. Used by the storefront edit screen
  /// to surface a one-time migration banner asking the merchant to set a
  /// real contact email.
  static bool isPlaceholderOrEmpty(String? value) {
    if (value == null) return true;
    final v = value.trim().toLowerCase();
    return v.isEmpty || v == _legacyPlaceholder;
  }
}
