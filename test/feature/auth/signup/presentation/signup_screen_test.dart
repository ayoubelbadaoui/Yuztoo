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
  testWidgets('Signup flow calls onSignupSuccess with formatted phone number',
      (tester) async {
    String? receivedPhone;
    String? receivedVerificationId;
    String? receivedEmail;
    String? receivedCity;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: MaterialApp(
          home: SignupScreen(
            role: UserRole.client,
            onBack: () {},
            onSignupSuccess: (phoneNumber, verificationId, email, city) {
              receivedPhone = phoneNumber;
              receivedVerificationId = verificationId;
              receivedEmail = email;
              receivedCity = city;
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'votre@email.com'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Min. 8 caractères'),
      'Password1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Répétez votre mot de passe'),
      'Password1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '612345678'),
      '0612345678',
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

    expect(receivedPhone, '+33612345678');
    expect(receivedVerificationId, 'verif-123');
    expect(receivedEmail, 'test@example.com');
    expect(receivedCity, 'Paris');
  });
}

