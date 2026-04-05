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

  Stream<Result<AuthUser?>> watchAuthState();
}
