// ignore_for_file: unused_element_parameter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/auth/core/domain/auth_failure.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/repositories/auth_repository.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/value_objects/email_address.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/value_objects/password.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/user_profile_basics.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/repositories/user_repository.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/providers.dart'
    as auth_core;
import 'package:flutter_yuztoo/feature/auth/core/infrastructure/auth_repository_provider.dart';
import 'package:flutter_yuztoo/feature/auth/core/infrastructure/user_repository_provider.dart';
import 'package:flutter_yuztoo/feature/auth/signup/application/screens.dart';
import 'package:flutter_yuztoo/feature/auth/signup/application/widgets.dart';
import 'package:flutter_yuztoo/types.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.googleSignInResult,
    this.appleSignInResult,
  });

  /// When null, Google tap returns a generic Left (legacy test behaviour).
  final Result<AuthUser>? googleSignInResult;
  final Result<AuthUser>? appleSignInResult;

  int googleSignInCallCount = 0;

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  }) async {
    return const Left<AuthFailure, AuthUser>(
      AuthUnexpectedFailure(message: 'Not used in signup test'),
    );
  }

  @override
  Future<Result<AuthUser>> signupWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  }) async {
    return Right<AuthFailure, AuthUser>(
      AuthUser(id: 'uid-123', email: email.value),
    );
  }

  @override
  Future<Result<String>> sendPhoneVerification({
    required String phoneNumber,
  }) async {
    return const Right<AuthFailure, String>('verif-123');
  }

  @override
  Future<Result<Unit>> verifyAndLinkPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    return const Right<AuthFailure, Unit>(unit);
  }

  @override
  Future<Result<Unit>> sendPasswordResetEmail({
    required EmailAddress email,
  }) async {
    return const Right<AuthFailure, Unit>(unit);
  }

  @override
  Future<Result<AuthUser>> verifyPhoneAndCreateUser({
    required String verificationId,
    required String smsCode,
    required EmailAddress email,
    required Password password,
  }) async {
    return Right<AuthFailure, AuthUser>(
      AuthUser(id: 'uid-123', email: email.value),
    );
  }

  @override
  Future<Result<Unit>> deleteCurrentUser() async {
    return const Right<AuthFailure, Unit>(unit);
  }

  @override
  Future<Result<Unit>> signOut() async {
    return const Right<AuthFailure, Unit>(unit);
  }

  @override
  Future<Result<AuthUser>> signInWithGoogle() async {
    googleSignInCallCount++;
    return googleSignInResult ??
        const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Not used in signup test'),
        );
  }

  @override
  Future<Result<AuthUser>> signInWithApple() async {
    return appleSignInResult ??
        const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Not used in signup test'),
        );
  }

  @override
  Future<Result<Unit>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    return const Right<AuthFailure, Unit>(unit);
  }

  @override
  Future<Result<AuthUser>> linkWithGoogle() => throw UnimplementedError();

  @override
  Future<Result<AuthUser>> linkWithApple() => throw UnimplementedError();

  @override
  List<String> getLinkedProviders() => [];

  @override
  Stream<Result<AuthUser?>> watchAuthState() {
    return Stream.value(const Right<AuthFailure, AuthUser?>(null));
  }
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository({
    this.phoneRegistered = false,
    this.emailRegistered = false,
    this.phoneCheckFailure,
  });

  final bool phoneRegistered;
  final bool emailRegistered;
  final AuthFailure? phoneCheckFailure;

  @override
  Future<Result<bool>> isPhoneNumberRegistered(String phone) async =>
      phoneCheckFailure != null
          ? Left<AuthFailure, bool>(phoneCheckFailure!)
          : Right<AuthFailure, bool>(phoneRegistered);

  @override
  Future<Result<bool>> isEmailRegistered(String email) async =>
      Right<AuthFailure, bool>(emailRegistered);

  @override
  Future<Result<Unit>> createUserDocument({
    required String uid,
    required String email,
    required String phone,
    required Map<String, bool> roles,
    String city = '',
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<UserRole?>> getUserRole(String uid) => throw UnimplementedError();

  @override
  Future<Result<String?>> getUserCity(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<UserProfileBasics?>> getUserProfileBasics(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<Map<String, bool>?>> getUserRoles(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<bool?>> isMerchantOnboardingCompleted(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<bool?>> isClientOnboardingCompleted(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> completeClientProfile({
    required String uid,
    required String displayName,
    String? city,
    String? photoUrl,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> updateClientBasicInfo({
    required String uid,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? ownerEmail,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> markMerchantOnboardingCompleted(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> updateUserCity({
    required String uid,
    required String city,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<List<String>>> getConnectedCities(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> setConnectedCities({
    required String uid,
    required List<String> cities,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> patchUserDocument(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> updateLastLoginAt(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> consumeForceMerchantNextLogin(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> checkUserProfileComplete(String uid) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> addSecondaryClientRole(String uid) async =>
      const Right(unit);

  @override
  Future<Result<Unit>> addSecondaryMerchantRole(String uid) async =>
      const Right(unit);
}

/// Firestore `/users/{uid}` exists (OAuth user already registered in app).
class _FakeUserRepositoryWithProfile extends _FakeUserRepository {
  _FakeUserRepositoryWithProfile({
    super.phoneRegistered,
    super.emailRegistered,
    super.phoneCheckFailure,
  });

  @override
  Future<Result<UserProfileBasics?>> getUserProfileBasics(String uid) async {
    return const Right<AuthFailure, UserProfileBasics?>(
      UserProfileBasics(
        email: 'oauth@example.com',
        phone: '+33601020304',
        city: 'Paris',
      ),
    );
  }
}

void main() {
  testWidgets(
    'Signup flow navigates to OTPScreen with formatted phone number',
    (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => SignupScreen(
              role: UserRole.client,
              onBack: () {},
              onNavigateToOtp: (data) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OTPScreen(
                      userId: '',
                      phone: data.phone,
                      onResend: () {},
                      email: data.email,
                      password: data.password,
                      role: UserRole.client,
                      verificationId: data.verificationId,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));

    final phoneField = find.descendant(
      of: find.byType(PhoneField),
      matching: find.byType(TextField),
    );
    expect(phoneField, findsOneWidget);

    await tester.enterText(
      fields.at(0),
      'test@example.com',
    );
    await tester.enterText(
      fields.at(1),
      'Password1',
    );
    await tester.enterText(
      fields.at(2),
      'Password1',
    );
    await tester.enterText(
      phoneField,
      '612345678',
    );

    final submitBtn = find.text('Créer mon compte');
    await tester.ensureVisible(submitBtn);
    await tester.pump();
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    final otpFinder = find.byType(OTPScreen);
    expect(otpFinder, findsOneWidget);

    final otp = tester.widget<OTPScreen>(otpFinder);
    expect(otp.userId, ''); // SignupScreen defers user creation until OTP verification
    expect(otp.phone, '+33612345678');
    expect(otp.verificationId, 'verif-123');
    expect(otp.email, 'test@example.com');
    expect(otp.password, 'Password1');
    expect(otp.role, UserRole.client);
  },
  );

  testWidgets(
    'Signup does not navigate to OTP when phone is already registered',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
            userRepositoryProvider.overrideWithValue(
              _FakeUserRepository(phoneRegistered: true),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => SignupScreen(
                role: UserRole.client,
                onBack: () {},
                onNavigateToOtp: (_) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('OTP')),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'new@example.com');
      await tester.enterText(fields.at(1), 'Password1');
      await tester.enterText(fields.at(2), 'Password1');
      final phoneField = find.descendant(
        of: find.byType(PhoneField),
        matching: find.byType(TextField),
      );
      await tester.enterText(phoneField, '612345678');

      final submitBtn = find.text('Créer mon compte');
      await tester.ensureVisible(submitBtn);
      await tester.pump();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('OTP'), findsNothing);
      expect(find.byType(OTPScreen), findsNothing);
    },
  );

  testWidgets(
    'Signup does not navigate to OTP when email is already registered',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
            userRepositoryProvider.overrideWithValue(
              _FakeUserRepository(emailRegistered: true),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => SignupScreen(
                role: UserRole.client,
                onBack: () {},
                onNavigateToOtp: (_) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('OTP')),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'taken@example.com');
      await tester.enterText(fields.at(1), 'Password1');
      await tester.enterText(fields.at(2), 'Password1');
      final phoneField = find.descendant(
        of: find.byType(PhoneField),
        matching: find.byType(TextField),
      );
      await tester.enterText(phoneField, '612345678');

      final submitBtn = find.text('Créer mon compte');
      await tester.ensureVisible(submitBtn);
      await tester.pump();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('OTP'), findsNothing);
      expect(find.byType(OTPScreen), findsNothing);
    },
  );

  testWidgets(
    'Signup blocks when duplicate check fails even without mapped message',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
            userRepositoryProvider.overrideWithValue(
              _FakeUserRepository(
                phoneCheckFailure: const AuthUnexpectedFailure(
                  message: 'verification backend unavailable',
                ),
              ),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => SignupScreen(
                role: UserRole.client,
                onBack: () {},
                onNavigateToOtp: (_) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('OTP')),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'new@example.com');
      await tester.enterText(fields.at(1), 'Password1');
      await tester.enterText(fields.at(2), 'Password1');
      final phoneField = find.descendant(
        of: find.byType(PhoneField),
        matching: find.byType(TextField),
      );
      await tester.enterText(phoneField, '612345678');

      final submitBtn = find.text('Créer mon compte');
      await tester.ensureVisible(submitBtn);
      await tester.pump();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('OTP'), findsNothing);
      expect(find.byType(OTPScreen), findsNothing);
      expect(
        find.textContaining('verification'),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'Signup: Google tap shows error when sign-in fails',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _FakeAuthRepository(
                googleSignInResult: const Left<AuthFailure, AuthUser>(
                  InvalidCredentialsFailure(),
                ),
              ),
            ),
            userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
          ],
          child: MaterialApp(
            home: SignupScreen(
              role: UserRole.client,
              onBack: () {},
              onNavigateToOtp: (_) {},
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

      expect(
        find.textContaining('Identifiants incorrects'),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'Signup: Google tap with existing Firestore profile clears OAuth gate',
    (tester) async {
      final oauthAuth = _FakeAuthRepository(
        googleSignInResult: const Right<AuthFailure, AuthUser>(
          AuthUser(id: 'oauth-uid', email: 'google@example.com'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(oauthAuth),
            userRepositoryProvider.overrideWithValue(
              _FakeUserRepositoryWithProfile(),
            ),
          ],
          child: MaterialApp(
            home: SignupScreen(
              role: UserRole.client,
              onBack: () {},
              onNavigateToOtp: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container =
          ProviderScope.containerOf(tester.element(find.byType(SignupScreen)));
      expect(container.read(auth_core.oauthFirestoreProfilePendingProvider),
          isFalse);

      final googleTarget = find.bySemanticsLabel('Google social sign-in');
      await tester.ensureVisible(googleTarget);
      await tester.pumpAndSettle();
      await tester.tap(googleTarget);
      await tester.pumpAndSettle();

      expect(container.read(auth_core.oauthFirestoreProfilePendingProvider),
          isFalse);
      expect(oauthAuth.googleSignInCallCount, 1);
    },
  );
}

