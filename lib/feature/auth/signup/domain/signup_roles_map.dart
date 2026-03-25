import '../../../../types.dart';

/// Firestore `roles` map written at signup (OTP → createUserDocument).
///
/// - **Client**: only `client` — no merchant, no provider.
/// - **Merchant**: `merchant` + `provider` + `client` — commerçants sont aussi
///   considérés comme prestataires et peuvent utiliser l’app client (carnet, etc.).
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
        'client': true,
        'merchant': true,
        'provider': true,
      };
  }
}
