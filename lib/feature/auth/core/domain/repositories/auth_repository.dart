import '../../../../../core/domain/core/result.dart';
import '../entities/auth_user.dart';
import '../value_objects/email_address.dart';
import '../value_objects/password.dart';

abstract class AuthRepository {
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  });

  Future<Result<AuthUser>> signupWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  });

  Future<Result<String>> sendPhoneVerification({
    required String phoneNumber,
  });

  Future<Result<Unit>> verifyAndLinkPhone({
    required String verificationId,
    required String smsCode,
  });

  Future<Result<Unit>> signOut();

  /// Updates the signed-in user's display name and/or profile photo URL.
  Future<Result<Unit>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  Future<Result<Unit>> sendPasswordResetEmail({
    required EmailAddress email,
  });

  Future<Result<AuthUser>> verifyPhoneAndCreateUser({
    required String verificationId,
    required String smsCode,
    required EmailAddress email,
    required Password password,
  });

  Future<Result<Unit>> deleteCurrentUser();

  Future<Result<AuthUser>> signInWithGoogle();

  Future<Result<AuthUser>> signInWithApple();

  /// Link the currently signed-in account with a Google credential.
  /// Returns the updated [AuthUser] on success.
  /// If Google is already linked, returns the existing user without error.
  Future<Result<AuthUser>> linkWithGoogle();

  /// Link the currently signed-in account with an Apple credential.
  /// Returns the updated [AuthUser] on success.
  /// If Apple is already linked, returns the existing user without error.
  /// On iOS this triggers the native Sign-In-with-Apple sheet; on other
  /// platforms callers should not expose the affordance.
  Future<Result<AuthUser>> linkWithApple();

  /// Returns the list of provider IDs linked to the current Firebase user.
  /// Example values: 'google.com', 'apple.com', 'password', 'phone'.
  List<String> getLinkedProviders();

  Stream<Result<AuthUser?>> watchAuthState();
}
