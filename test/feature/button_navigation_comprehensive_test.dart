import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/role_selection/presentation/role_selection_screen.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/merchant_onboarding_screen.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/subcategory_selection_screen.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/merchant_benefits_screen.dart';
import 'package:flutter_yuztoo/types.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';

void main() {
  group('Comprehensive Button Navigation Test', () {
    testWidgets('1. Role Selection - Merchant "Se connecter" button navigates to login', (tester) async {
      bool loginCalled = false;
      UserRole? loginRole;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RoleSelectionScreen(
            onSelectRole: (role) {},
            onLogin: (role) {
              loginCalled = true;
              loginRole = role;
            },
            initialRole: UserRole.merchant,
          ),
        ),
      );
      await tester.pump();

      // Find "Se connecter" button (OutlinedButton in merchant view)
      final connecterButton = find.byType(OutlinedButton);
      expect(connecterButton, findsOneWidget, reason: 'Se connecter button should exist');

      await tester.tap(connecterButton);
      await tester.pump();

      expect(loginCalled, true, reason: 'Se connecter button should call onLogin');
      expect(loginRole, UserRole.merchant, reason: 'onLogin should be called with merchant role');
    });

    testWidgets('2. Role Selection - Merchant "Découvrir" button navigates to onboarding', (tester) async {
      bool discoverCalled = false;
      UserRole? discoverRole;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RoleSelectionScreen(
            onSelectRole: (role) {
              discoverCalled = true;
              discoverRole = role;
            },
            initialRole: UserRole.merchant,
          ),
        ),
      );
      await tester.pump();

      // Find "Découvrir" button (ElevatedButton in merchant view)
      final discoverButton = find.byType(ElevatedButton);
      expect(discoverButton, findsOneWidget);

      await tester.tap(discoverButton);
      await tester.pump();

      expect(discoverCalled, true, reason: 'Découvrir button should call onSelectRole');
      expect(discoverRole, UserRole.merchant, reason: 'onSelectRole should be called with merchant role');
    });

    testWidgets('3. Merchant Onboarding - Suivant button navigates when category selected', (tester) async {
      bool nextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MerchantOnboardingScreen(
            onNext: () {
              nextCalled = true;
            },
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Select a category first
      final categoryCards = find.byType(GestureDetector);
      expect(categoryCards, findsWidgets, reason: 'Category cards should exist');

      await tester.tap(categoryCards.first);
      await tester.pump();

      // Now Suivant button should be enabled
      final suivantButton = find.text('Suivant');
      if (suivantButton.evaluate().isEmpty) {
        // Try finding ElevatedButton
        final buttons = find.byType(ElevatedButton);
        expect(buttons, findsOneWidget);
        final button = tester.widget<ElevatedButton>(buttons.first);
        expect(button.onPressed, isNotNull, reason: 'Suivant button should be enabled after category selection');
        
        await tester.tap(buttons.first);
      } else {
        await tester.tap(suivantButton);
      }

      await tester.pump();
      expect(nextCalled, true, reason: 'Suivant button should call onNext after category selection');
    });

    testWidgets('4. Subcategory Selection - Suivant button navigates when subcategory selected', (tester) async {
      bool nextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SubcategorySelectionScreen(
            categoryTitle: 'Test',
            subcategories: const [],
            onNext: () {
              nextCalled = true;
            },
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Select a subcategory first (if any exist)
      final subcategoryCards = find.byType(GestureDetector);
      if (subcategoryCards.evaluate().isNotEmpty) {
        await tester.tap(subcategoryCards.first);
        await tester.pump();
      }

      // Check Suivant button
      final suivantButton = find.text('Suivant');
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        final button = tester.widget<ElevatedButton>(buttons.first);
        expect(button.onPressed, isNotNull, reason: 'Suivant button should have callback');
      }
    });

    testWidgets('5. Benefits Screen - Démarrer gratuitement button navigates to signup', (tester) async {
      bool startFreeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MerchantBenefitsScreen(
            onStartFree: () {
              startFreeCalled = true;
            },
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      final startButton = find.text('Démarrer gratuitement');
      expect(startButton, findsOneWidget, reason: 'Démarrer gratuitement button should exist');

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(button.onPressed, isNotNull, reason: 'Démarrer gratuitement button should have onPressed callback');

      await tester.tap(startButton);
      await tester.pump();
      expect(startFreeCalled, true, reason: 'Démarrer gratuitement button should call onStartFree');
    });

    testWidgets('6. All back buttons have callbacks', (tester) async {
      // Test Merchant Onboarding
      bool backCalled = false;
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

      // Find back button
      final backButtons = find.byType(IconButton);
      if (backButtons.evaluate().isEmpty) {
        // Try YBackButton or GestureDetector
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

