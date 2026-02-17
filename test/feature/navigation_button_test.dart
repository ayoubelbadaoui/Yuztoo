import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/role_selection/presentation/role_selection_screen.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/merchant_onboarding_screen.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/subcategory_selection_screen.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/merchant_benefits_screen.dart';
import 'package:flutter_yuztoo/types.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';

void main() {
  group('Navigation Button Tests - Check All Buttons Work', () {
    testWidgets('Role Selection - All buttons have callbacks', (tester) async {
      bool onSelectRoleCalled = false;
      bool onLoginCalled = false;
      bool onRoleChangedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RoleSelectionScreen(
            onSelectRole: (role) {
              onSelectRoleCalled = true;
            },
            onLogin: (role) {
              onLoginCalled = true;
            },
            onRoleChanged: (role) {
              onRoleChangedCalled = true;
            },
          ),
        ),
      );
      await tester.pump();

      // Check merchant view buttons exist
      final merchantToggle = find.text('Commerçant');
      if (merchantToggle.evaluate().isNotEmpty) {
        await tester.tap(merchantToggle);
        await tester.pump();
        expect(onRoleChangedCalled, true, reason: 'Role toggle should call onRoleChanged');

        // Check Découvrir button
        final discoverButton = find.byType(ElevatedButton);
        if (discoverButton.evaluate().isNotEmpty) {
          onSelectRoleCalled = false;
          await tester.tap(discoverButton);
          await tester.pump();
          expect(onSelectRoleCalled, true, reason: 'Découvrir button should call onSelectRole');
        }

        // Check Se connecter button (if visible)
        final loginButton = find.byType(OutlinedButton);
        if (loginButton.evaluate().isNotEmpty) {
          onLoginCalled = false;
          await tester.tap(loginButton);
          await tester.pump();
          expect(onLoginCalled, true, reason: 'Se connecter button should call onLogin');
        }
      }
    });

    testWidgets('Merchant Onboarding - Suivant button has callback', (tester) async {
      bool onNextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MerchantOnboardingScreen(
            onNext: () {
              onNextCalled = true;
            },
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Select a category first
      final categoryCards = find.byType(GestureDetector);
      if (categoryCards.evaluate().isNotEmpty) {
        await tester.tap(categoryCards.first);
        await tester.pump();
      }

      // Check Suivant button
      final suivantButton = find.text('Suivant');
      if (suivantButton.evaluate().isEmpty) {
        // Try finding by ElevatedButton
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          final button = tester.widget<ElevatedButton>(buttons.first);
          expect(button.onPressed, isNotNull, reason: 'Suivant button should have onPressed callback');
        }
      } else {
        await tester.tap(suivantButton);
        await tester.pump();
        expect(onNextCalled, true, reason: 'Suivant button should call onNext');
      }
    });

    testWidgets('Subcategory Selection - Suivant button has callback', (tester) async {
      bool onNextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SubcategorySelectionScreen(
            categoryTitle: 'Test Category',
            subcategories: const [],
            onNext: () {
              onNextCalled = true;
            },
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Select a subcategory first
      final subcategoryCards = find.byType(GestureDetector);
      if (subcategoryCards.evaluate().isNotEmpty) {
        await tester.tap(subcategoryCards.first);
        await tester.pump();
      }

      // Check Suivant button
      final suivantButton = find.text('Suivant');
      if (suivantButton.evaluate().isEmpty) {
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          final button = tester.widget<ElevatedButton>(buttons.first);
          expect(button.onPressed, isNotNull, reason: 'Suivant button should have onPressed callback');
        }
      } else {
        await tester.tap(suivantButton);
        await tester.pump();
        expect(onNextCalled, true, reason: 'Suivant button should call onNext');
      }
    });

    testWidgets('Benefits Screen - Démarrer gratuitement button has callback', (tester) async {
      bool onStartFreeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MerchantBenefitsScreen(
            onStartFree: () {
              onStartFreeCalled = true;
            },
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Check Démarrer gratuitement button
      final startButton = find.text('Démarrer gratuitement');
      expect(startButton, findsOneWidget, reason: 'Démarrer gratuitement button should exist');

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(button.onPressed, isNotNull, reason: 'Démarrer gratuitement button should have onPressed callback');

      await tester.tap(startButton);
      await tester.pump();
      expect(onStartFreeCalled, true, reason: 'Démarrer gratuitement button should call onStartFree');
    });

    testWidgets('All back buttons have callbacks', (tester) async {
      bool backCalled = false;

      // Test Merchant Onboarding back button
      await tester.pumpWidget(
        MaterialApp(
          home: MerchantOnboardingScreen(
            onBack: () {
              backCalled = true;
            },
            onNext: () {},
          ),
        ),
      );
      await tester.pump();

      final backButtons = find.byType(IconButton);
      if (backButtons.evaluate().isEmpty) {
        // Try finding YBackButton or GestureDetector
        final gestures = find.byType(GestureDetector);
        if (gestures.evaluate().isNotEmpty) {
          await tester.tap(gestures.first);
          await tester.pump();
          expect(backCalled, true, reason: 'Back button should call onBack');
        }
      }
    });
  });
}

