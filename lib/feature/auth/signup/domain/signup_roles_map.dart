import '../../../../types.dart';

/// Firestore `roles` map written at signup (OTP → createUserDocument).
///
/// `client` and `merchant` are **mutually exclusive** (one account, one primary role).
/// `provider` stays aligned with merchant signup (prestataire / business features).
///
/// - **Client**: `client` only.
/// - **Merchant**: `merchant` + `provider` (`roles.client` stays false).
Map<String, bool> signupRolesMap(UserRole signupRole) {
  switch (signupRole) {
    case UserRole.client:
      return <String, bool>{
        'client': true,
        'merchant': false,
        'provider': false,
      };
    case UserRole.merchant:
      return <String, bool>{
        'client': false,
        'merchant': true,
        'provider': true,
      };
  }
}
