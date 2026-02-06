import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/auth/core/domain/auth_failure.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/repositories/auth_repository.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/value_objects/email_address.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/value_objects/password.dart';
import 'package:flutter_yuztoo/feature/auth/core/infrastructure/auth_repository_provider.dart';
import 'package:flutter_yuztoo/feature/auth/signup/presentation/signup_screen.dart';
import 'package:flutter_yuztoo/feature/auth/signup/presentation/otp_screen.dart';
import 'package:flutter_yuztoo/feature/auth/signup/presentation/widgets/signup_form_fields.dart';
import 'package:flutter_yuztoo/types.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';

class _FakeAuthRepository implements AuthRepository {
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
  Stream<Result<AuthUser?>> watchAuthState() {
    return Stream.value(const Right<AuthFailure, AuthUser?>(null));
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
        ],
        child: MaterialApp(
          home: SignupScreen(
            role: UserRole.client,
            onBack: () {},
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

    final cityField = find.text('Sélectionnez votre ville');
    await tester.scrollUntilVisible(
      cityField,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(cityField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paris'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    final otpFinder = find.byType(OTPScreen);
    expect(otpFinder, findsOneWidget);

    final otp = tester.widget<OTPScreen>(otpFinder);
    expect(otp.userId, ''); // SignupScreen defers user creation until OTP verification
    expect(otp.phone, '+33612345678');
    expect(otp.verificationId, 'verif-123');
    expect(otp.email, 'test@example.com');
    expect(otp.password, 'Password1');
    expect(otp.city, 'Paris');
    expect(otp.role, UserRole.client);
  },
  );
}

