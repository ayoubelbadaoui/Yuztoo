import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/infrastructure/auth_repository_provider.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../core/infrastructure/user_repository_provider.dart';
import 'signup_with_email_password.dart';
import 'send_phone_verification.dart';
import 'verify_phone_available_for_signup.dart';
import 'verify_email_available_for_signup.dart';
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

final verifyPhoneAvailableForSignupProvider =
    Provider<VerifyPhoneAvailableForSignup>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return VerifyPhoneAvailableForSignup(userRepository);
});

final verifyEmailAvailableForSignupProvider =
    Provider<VerifyEmailAvailableForSignup>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return VerifyEmailAvailableForSignup(userRepository);
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

/// GDPR right-to-erasure entry point. Production calls the `purgeAccount`
/// Cloud Function which:
///   1. Cascades Firestore data (loyalty footprint at every followed
///      merchant, push tokens, notifications, blocked merchants, AND the
///      merchant document itself for dual-profile users).
///   2. Frees email_index / phone_index entries so the same identifier
///      can be reused at re-signup.
///   3. Deletes the Firebase Auth user.
///
/// The legacy auth-only delete (`AuthRepository.deleteCurrentUser`) is
/// kept as a fallback for environments where Cloud Functions aren't
/// reachable (CI, the Firebase emulator without functions emulator, etc).
/// In production we ALWAYS prefer the Cloud Function because the auth-only
/// path leaves a Firestore footprint that violates GDPR Art. 17.
class DeleteCurrentUser {
  const DeleteCurrentUser(this._repository);

  final AuthRepository _repository;

  Future<void> call() async {
    try {
      // Region must match the Cloud Function's deployment region. The
      // current `functions/src/index.ts` pins europe-west1; if that ever
      // moves, this constructor argument needs to follow.
      final functions =
          FirebaseFunctions.instanceFor(region: 'europe-west1');
      await functions.httpsCallable('purgeAccount').call();
    } on FirebaseFunctionsException catch (e) {
      // unauthenticated → caller had no live Auth token; no point trying
      // the local fallback either, surface as-is.
      if (e.code == 'unauthenticated') rethrow;
      // Any other Cloud Function error means the cascade may have
      // partially run. We still call the local fallback so the user
      // ends up signed out and the account is at minimum auth-less. The
      // CF can be re-invoked manually by support if needed.
      await _repository.deleteCurrentUser();
    } catch (_) {
      // Network down, region misconfigured, etc. — same fallback.
      await _repository.deleteCurrentUser();
    }
  }
}

