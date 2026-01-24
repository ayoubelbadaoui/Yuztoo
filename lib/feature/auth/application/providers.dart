import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/auth_user.dart';
import '../../../core/domain/core/result.dart';
import 'auth_controller.dart';
import 'state/auth_state.dart';
import 'use_cases/sign_in_with_email_password.dart';
import 'use_cases/sign_out.dart';
import 'use_cases/watch_auth_state.dart';
import 'use_cases/sign_up_with_email_password.dart';
import 'use_cases/send_phone_verification.dart';
import 'use_cases/link_phone_credential.dart';
import 'use_cases/create_user_document.dart';
import '../infrastructure/auth_repository_provider.dart';
import '../infrastructure/user_repository_provider.dart';

final signInWithEmailPasswordProvider =
    Provider<SignInWithEmailPassword>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithEmailPassword(repository);
});

final signOutProvider = Provider<SignOut>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOut(repository);
});

final watchAuthStateProvider = Provider<WatchAuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return WatchAuthState(repository);
});

final signUpWithEmailPasswordProvider =
    Provider<SignUpWithEmailPassword>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpWithEmailPassword(repository);
});

final sendPhoneVerificationProvider =
    Provider<SendPhoneVerification>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendPhoneVerification(repository);
});

final linkPhoneCredentialProvider = Provider<LinkPhoneCredential>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LinkPhoneCredential(repository);
});

final createUserDocumentProvider = Provider<CreateUserDocument>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return CreateUserDocument(repository);
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    signInWithEmailPassword: ref.watch(signInWithEmailPasswordProvider),
    signOut: ref.watch(signOutProvider),
    watchAuthState: ref.watch(watchAuthStateProvider),
  );
});

/// Exposes auth state as a convenience for UI widgets.
final authStateProvider =
    Provider<AuthState>((ref) => ref.watch(authControllerProvider));

/// Exposes raw auth stream results (useful for listeners).
final authResultStreamProvider = StreamProvider<Result<AuthUser?>>((ref) {
  return ref.watch(watchAuthStateProvider)();
});
