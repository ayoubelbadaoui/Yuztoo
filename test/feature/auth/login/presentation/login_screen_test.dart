import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_yuztoo/feature/auth/login/presentation/login_screen.dart';
import 'package:flutter_yuztoo/types.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('should display email and password fields', (WidgetTester tester) async {
      // Arrange
      bool onLoginCalled = false;
      bool onBackCalled = false;
      bool onSignupCalled = false;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(
              role: UserRole.client,
              onBack: () => onBackCalled = true,
              onLogin: () => onLoginCalled = true,
              onSignup: () => onSignupCalled = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Adresse email'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('should display role selector', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(
              role: UserRole.client,
              onBack: () {},
              onLogin: () {},
              onSignup: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Clients'), findsOneWidget);
      expect(find.text('Commerçant'), findsOneWidget);
    });

    testWidgets('should call onBack when back button is tapped', (WidgetTester tester) async {
      // Arrange
      bool onBackCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(
              role: UserRole.client,
              onBack: () => onBackCalled = true,
              onLogin: () {},
              onSignup: () {},
            ),
          ),
        ),
      );

      // Act
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Assert
      expect(onBackCalled, true);
    });

    testWidgets('should show password visibility toggle', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(
              role: UserRole.client,
              onBack: () {},
              onLogin: () {},
              onSignup: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should toggle password visibility when eye icon is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(
              role: UserRole.client,
              onBack: () {},
              onLogin: () {},
              onSignup: () {},
            ),
          ),
        ),
      );

      // Act - Tap visibility toggle
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      // Assert - Icon should change to visibility
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(
              role: UserRole.client,
              onBack: () {},
              onLogin: () {},
              onSignup: () {},
            ),
          ),
        ),
      );

      // Act - Try to submit without entering email
      final submitButton = find.text('Se connecter');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(find.text('L\'adresse e-mail est requise.'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(
              role: UserRole.client,
              onBack: () {},
              onLogin: () {},
              onSignup: () {},
            ),
          ),
        ),
      );

      // Act - Enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Adresse e-mail invalide.'), findsOneWidget);
    });

    testWidgets('should show validation error for empty password', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(
              role: UserRole.client,
              onBack: () {},
              onLogin: () {},
              onSignup: () {},
            ),
          ),
        ),
      );

      // Act - Enter email but not password
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Le mot de passe est requis.'), findsOneWidget);
    });

    testWidgets('should show "Créer un compte" link', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(
              role: UserRole.client,
              onBack: () {},
              onLogin: () {},
              onSignup: () {},
            ),
          ),
        ),
      );

      // Assert - Text might be in TextSpan, so use textContaining
      expect(find.textContaining('Créer un compte'), findsOneWidget);
    });
  });
}

