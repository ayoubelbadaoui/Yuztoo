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

  Future<Result<Unit>> deleteCurrentUser();

  Future<Result<Unit>> signOut();

  Stream<Result<AuthUser?>> watchAuthState();
}
