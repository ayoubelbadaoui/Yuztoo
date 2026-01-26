import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/infrastructure/auth_repository_provider.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../core/infrastructure/user_repository_provider.dart';
import 'signup_with_email_password.dart';
import 'send_phone_verification.dart';
import 'verify_and_link_phone.dart';
import 'verify_phone_and_create_user.dart';
import 'create_user_document.dart';

final signupWithEmailPasswordProvider =
    Provider<SignupWithEmailPassword>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignupWithEmailPassword(repository);
});

final sendPhoneVerificationProvider =
    Provider<SendPhoneVerification>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendPhoneVerification(repository);
});

final verifyAndLinkPhoneProvider = Provider<VerifyAndLinkPhone>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyAndLinkPhone(repository);
});

final verifyPhoneAndCreateUserProvider = Provider<VerifyPhoneAndCreateUser>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyPhoneAndCreateUser(repository);
});

final createUserDocumentProvider = Provider<CreateUserDocument>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return CreateUserDocument(repository);
});

final deleteCurrentUserProvider = Provider<DeleteCurrentUser>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return DeleteCurrentUser(repository);
});

class DeleteCurrentUser {
  const DeleteCurrentUser(this._repository);

  final AuthRepository _repository;

  Future<void> call() async {
    await _repository.deleteCurrentUser();
  }
}

