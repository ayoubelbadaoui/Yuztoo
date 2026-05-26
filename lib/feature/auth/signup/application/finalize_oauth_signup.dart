import '../../core/domain/auth_failure.dart';
import '../../core/domain/entities/auth_user.dart';
import '../../core/application/oauth_identity_helpers.dart';
import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../domain/signup_roles_map.dart';
import '../../../../types.dart';
import 'create_user_document.dart';
import 'verify_email_available_for_signup.dart';
import 'verify_phone_available_for_signup.dart';

/// Combines the (after-OAuth, before-onboarding) checks + Firestore write
/// the user used to do via the AlertDialog in `signup_screen.part.dart`.
///
/// Steps:
///   1. Re-check email availability — `email_index/{email}` is the source
///      of truth (Firebase Auth removed `fetchSignInMethodsForEmail` in
///      v6 to prevent enumeration).
///   2. Verify phone availability — `phone_index/{phone}`.
///   3. Write `/users/{uid}` with the role + identity (display name,
///      photo) provided by the OAuth provider, optionally overridden
///      with a user-typed first / last name when [firstNameOverride] /
///      [lastNameOverride] are non-null (Apple no-name case).
///
/// Never calls signOut. The caller decides whether a failure should keep
/// the OAuth Firebase session alive (so the user can retry) or sign out.
class FinalizeOAuthSignup {
  const FinalizeOAuthSignup({
    required VerifyEmailAvailableForSignup verifyEmail,
    required VerifyPhoneAvailableForSignup verifyPhone,
    required CreateUserDocument createUserDocument,
  })  : _verifyEmail = verifyEmail,
        _verifyPhone = verifyPhone,
        _createUserDocument = createUserDocument;

  final VerifyEmailAvailableForSignup _verifyEmail;
  final VerifyPhoneAvailableForSignup _verifyPhone;
  final CreateUserDocument _createUserDocument;

  Future<Result<Unit>> call({
    required AuthUser authUser,
    required UserRole role,
    required String phoneNumber,
    String? firstNameOverride,
    String? lastNameOverride,
  }) async {
    final email = authUser.email?.trim() ?? '';
    if (email.isEmpty) {
      return const Left<AppFailure, Unit>(
        AuthUnexpectedFailure(
          message:
              'Aucune adresse e-mail n’est associée à ce compte. Utilisez l’inscription par e-mail.',
        ),
      );
    }

    final emailCheck = await _verifyEmail.call(email: email);
    if (emailCheck.isLeft) {
      return Left<AppFailure, Unit>(emailCheck.leftOrNull!);
    }

    final phoneCheck = await _verifyPhone.call(phoneNumber: phoneNumber);
    if (phoneCheck.isLeft) {
      return Left<AppFailure, Unit>(phoneCheck.leftOrNull!);
    }

    final providerIdentity = oauthIdentityForCreateUserDocument(authUser);
    final firstName = _firstNonBlank(firstNameOverride, providerIdentity.firstName);
    final lastName = _firstNonBlank(lastNameOverride, providerIdentity.lastName);
    final composedDisplayName = _composeDisplayName(
      firstName: firstName,
      lastName: lastName,
      fallback: providerIdentity.displayName,
    );

    final createResult = await _createUserDocument.call(
      uid: authUser.id,
      email: email,
      phone: phoneNumber,
      roles: signupRolesMap(role),
      firstName: firstName,
      lastName: lastName,
      displayName: composedDisplayName,
      photoUrl: providerIdentity.photoUrl,
    );
    if (createResult.isLeft) {
      return Left<AppFailure, Unit>(createResult.leftOrNull!);
    }

    return const Right<AppFailure, Unit>(unit);
  }

  static String? _firstNonBlank(String? a, String? b) {
    final ta = a?.trim() ?? '';
    if (ta.isNotEmpty) return ta;
    final tb = b?.trim() ?? '';
    if (tb.isNotEmpty) return tb;
    return null;
  }

  static String? _composeDisplayName({
    String? firstName,
    String? lastName,
    String? fallback,
  }) {
    final f = firstName?.trim() ?? '';
    final l = lastName?.trim() ?? '';
    if (f.isNotEmpty && l.isNotEmpty) return '$f $l';
    if (f.isNotEmpty) return f;
    if (l.isNotEmpty) return l;
    final fb = fallback?.trim() ?? '';
    return fb.isEmpty ? null : fb;
  }
}
