import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/auth/core/domain/auth_failure.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/repositories/auth_repository.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/value_objects/email_address.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/value_objects/password.dart';
import 'package:flutter_yuztoo/feature/auth/core/infrastructure/auth_repository_provider.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/repositories/user_repository.dart';
import 'package:flutter_yuztoo/feature/auth/core/infrastructure/user_repository_provider.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/user_profile_basics.dart';
import 'package:flutter_yuztoo/feature/auth/login/presentation/login_screen.dart';
import 'package:flutter_yuztoo/types.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';

/// Minimal fake: only social + [watchAuthState] are used when opening [LoginScreen].
class _CountingSocialAuthRepository implements AuthRepository {
  int googleCalls = 0;
  int appleCalls = 0;

  @override
  Future<Result<AuthUser>> signInWithGoogle() async {
    googleCalls++;
    return const Left<AuthFailure, AuthUser>(InvalidCredentialsFailure());
  }

  @override
  Future<Result<AuthUser>> signInWithApple() async {
    appleCalls++;
    return const Left<AuthFailure, AuthUser>(InvalidCredentialsFailure());
  }

  @override
  Stream<Result<AuthUser?>> watchAuthState() =>
      Stream.value(const Right<AuthFailure, AuthUser?>(null));

  @override
  Future<Result<AuthUser?>> reloadCurrentUserProfile() async =>
      const Right<AuthFailure, AuthUser?>(null);

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<AuthUser>> signupWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<String>> sendPhoneVerification({
    required String phoneNumber,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> verifyAndLinkPhone({
    required String verificationId,
    required String smsCode,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> signOut() =>
      Future.value(const Right<AuthFailure, Unit>(unit));

  @override
  Future<Result<Unit>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> sendPasswordResetEmail({
    required EmailAddress email,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<AuthUser>> verifyPhoneAndCreateUser({
    required String verificationId,
    required String smsCode,
    required EmailAddress email,
    required Password password,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<AuthUser>> linkWithGoogle() => throw UnimplementedError();

  @override
  Future<Result<AuthUser>> linkWithApple() => throw UnimplementedError();

  @override
  List<String> getLinkedProviders() => [];

  @override
  Future<Result<Unit>> deleteCurrentUser() => throw UnimplementedError();
}

/// Minimal user-repo stub: the OAuth signup controller only calls into
/// the user repo *after* a successful credential exchange. The auth repo
/// in this test fails the credential exchange, so none of these methods
/// actually run — but the controller still has to be constructed, which
/// reads the provider, which crashes without a Firebase-free fake here.
class _StubUserRepository implements UserRepository {
  @override
  Future<Result<UserProfileBasics?>> getUserProfileBasics(String uid) async =>
      const Right<AuthFailure, UserProfileBasics?>(null);

  @override
  Future<Result<bool>> isEmailRegistered(String email) async =>
      const Right<AuthFailure, bool>(false);

  @override
  Future<Result<bool>> isPhoneNumberRegistered(String phone) async =>
      const Right<AuthFailure, bool>(false);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets(
    'Login: tapping Google calls signInWithGoogle once (not Apple)',
    (tester) async {
      final repo = _CountingSocialAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            userRepositoryProvider.overrideWithValue(_StubUserRepository()),
          ],
          child: MaterialApp(
            home: LoginScreen(
              role: UserRole.client,
              onBack: () {},
              onSignup: () {},
              onNavigateToOAuthCompletion: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final googleTarget = find.bySemanticsLabel('Google social sign-in');
      await tester.ensureVisible(googleTarget);
      await tester.pumpAndSettle();
      await tester.tap(googleTarget);
      await tester.pumpAndSettle();

      expect(repo.googleCalls, 1);
      expect(repo.appleCalls, 0);
    },
  );
}
