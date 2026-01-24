import '../../../../core/domain/core/result.dart';
import '../entities/auth_user.dart';
import '../value_objects/email_address.dart';
import '../value_objects/password.dart';

abstract class AuthRepository {
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  });

  Future<Result<Unit>> signOut();

  Stream<Result<AuthUser?>> watchAuthState();

  /// Create a new user account with email and password
  Future<Result<AuthUser>> createUserWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  });

  /// Send phone verification code and return verification ID
  Future<Result<String>> sendPhoneVerification({
    required String phoneNumber,
  });

  /// Link phone credential to the current authenticated user
  Future<Result<Unit>> linkPhoneCredential({
    required String verificationId,
    required String smsCode,
  });
}
