import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/auth_failure.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/repositories/auth_repository.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/value_objects/email_address.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/value_objects/password.dart';
import 'package:flutter_yuztoo/feature/auth/login/application/sign_in_with_email_password.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignInWithEmailPassword useCase;

  setUpAll(() {
    // Register fallback values for value objects
    registerFallbackValue(EmailAddress('test@example.com'));
    registerFallbackValue(Password('password123'));
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithEmailPassword(mockRepository);
  });

  group('SignInWithEmailPassword', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUser = AuthUser(
      id: 'user123',
      email: testEmail,
      role: 'client',
    );

    test('should return AuthUser when credentials are valid', () async {
      // Arrange
      when(() => mockRepository.signInWithEmailAndPassword(
            email: any(named: 'email', that: isA<EmailAddress>()),
            password: any(named: 'password', that: isA<Password>()),
          )).thenAnswer((_) async => Right<AuthFailure, AuthUser>(testUser));

      // Act
      final result = await useCase.call(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result.isRight, true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (user) {
          expect(user.id, testUser.id);
          expect(user.email, testEmail);
        },
      );

      verify(() => mockRepository.signInWithEmailAndPassword(
            email: any(named: 'email', that: isA<EmailAddress>()),
            password: any(named: 'password', that: isA<Password>()),
          )).called(1);
    });

    test('should return InvalidCredentialsFailure when email is invalid', () async {
      // Arrange
      const invalidEmail = 'invalid-email';

      // Act
      final result = await useCase.call(
        email: invalidEmail,
        password: testPassword,
      );

      // Assert
      expect(result.isLeft, true);
      result.fold(
        (failure) {
          expect(failure, isA<InvalidCredentialsFailure>());
        },
        (user) => fail('Should return failure'),
      );

      verifyNever(() => mockRepository.signInWithEmailAndPassword(
            email: any(named: 'email', that: isA<EmailAddress>()),
            password: any(named: 'password', that: isA<Password>()),
          ));
    });

    test('should return InvalidCredentialsFailure when password is invalid', () async {
      // Arrange
      const invalidPassword = '123'; // Too short

      // Act
      final result = await useCase.call(
        email: testEmail,
        password: invalidPassword,
      );

      // Assert
      expect(result.isLeft, true);
      result.fold(
        (failure) {
          expect(failure, isA<InvalidCredentialsFailure>());
        },
        (user) => fail('Should return failure'),
      );

      verifyNever(() => mockRepository.signInWithEmailAndPassword(
            email: any(named: 'email', that: isA<EmailAddress>()),
            password: any(named: 'password', that: isA<Password>()),
          ));
    });

    test('should return AuthFailure when repository returns failure', () async {
      // Arrange
      const failure = AuthNetworkFailure();
      when(() => mockRepository.signInWithEmailAndPassword(
            email: any(named: 'email', that: isA<EmailAddress>()),
            password: any(named: 'password', that: isA<Password>()),
          )).thenAnswer((_) async => const Left<AuthFailure, AuthUser>(failure));

      // Act
      final result = await useCase.call(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result.isLeft, true);
      result.fold(
        (f) => expect(f, isA<AuthNetworkFailure>()),
        (user) => fail('Should return failure'),
      );
    });

    test('should handle empty email', () async {
      // Act
      final result = await useCase.call(
        email: '',
        password: testPassword,
      );

      // Assert
      expect(result.isLeft, true);
      result.fold(
        (failure) => expect(failure, isA<InvalidCredentialsFailure>()),
        (user) => fail('Should return failure'),
      );
    });

    test('should handle empty password', () async {
      // Act
      final result = await useCase.call(
        email: testEmail,
        password: '',
      );

      // Assert
      expect(result.isLeft, true);
      result.fold(
        (failure) => expect(failure, isA<InvalidCredentialsFailure>()),
        (user) => fail('Should return failure'),
      );
    });
  });
}

