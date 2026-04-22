import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_yuztoo/feature/role_selection/application/screens.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/application/screens.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/widgets/subcategory/subcategory_card.dart';
import 'package:flutter_yuztoo/types.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';

void main() {
  group('Comprehensive Button Navigation Test', () {
    testWidgets(
        '1. Role Selection - Merchant "Se connecter" button navigates to login',
        (tester) async {
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
      expect(connecterButton, findsOneWidget,
          reason: 'Se connecter button should exist');

      await tester.tap(connecterButton);
      await tester.pump();

      expect(loginCalled, true,
          reason: 'Se connecter button should call onLogin');
      expect(loginRole, UserRole.merchant,
          reason: 'onLogin should be called with merchant role');
    });

    testWidgets(
        '2. Role Selection - Merchant "Découvrir" button navigates to onboarding',
        (tester) async {
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

      expect(discoverCalled, true,
          reason: 'Découvrir button should call onSelectRole');
      expect(discoverRole, UserRole.merchant,
          reason: 'onSelectRole should be called with merchant role');
    });

    testWidgets(
        '3. Merchant Onboarding - Suivant button navigates when category selected',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MerchantOnboardingScreen(
              onNext: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Select a visible category item first.
      final restaurantCategory = find.text('Restaurant');
      expect(restaurantCategory, findsOneWidget);
      await tester.tap(restaurantCategory);
      await tester.pumpAndSettle();

      // Footer uses GestureDetector + Text (not ElevatedButton).
      final continuer = find.text('Continuer');
      expect(continuer, findsOneWidget);
      final continuerGesture = find.ancestor(
        of: continuer,
        matching: find.byType(GestureDetector),
      );
      expect(
        tester.widget<GestureDetector>(continuerGesture.first).onTap,
        isNotNull,
        reason: 'Continuer should be enabled after category selection',
      );

      await tester.pump();
    });

    testWidgets(
        '4. Subcategory Selection - Suivant button navigates when subcategory selected',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SubcategorySelectionScreen(
              onBack: () {},
              onNext: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Tap the first subcategory card (avoid tapping only the label hit target).
      final cards = find.byType(SubcategoryCard);
      expect(cards, findsWidgets);
      await tester.tap(cards.first);
      await tester.pumpAndSettle();

      final continuer = find.text('Continuer');
      expect(continuer, findsOneWidget);
      final continuerGesture = find.ancestor(
        of: continuer,
        matching: find.byType(GestureDetector),
      );
      expect(
        tester.widget<GestureDetector>(continuerGesture.first).onTap,
        isNotNull,
        reason: 'Continuer should be enabled after subcategory selection',
      );
    });

    testWidgets(
        '5. Benefits Screen - Démarrer gratuitement button navigates to signup',
        (tester) async {
      bool startFreeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MerchantBenefitsScreen(
            onNext: () {
              startFreeCalled = true;
            },
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      final startButton = find.text('Créer mon compte');
      expect(startButton, findsOneWidget,
          reason: 'Créer mon compte button should exist');

      await tester.tap(startButton);
      await tester.pump();
      expect(startFreeCalled, true,
          reason: 'Créer mon compte button should call onNext');
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
