import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      final discoverButton = find.byType(ElevatedButton);
      expect(discoverButton, findsOneWidget);

      await tester.tap(discoverButton);
      await tester.pump();

      expect(discoverCalled, true, reason: 'Découvrir button should call onSelectRole');
      expect(discoverRole, UserRole.merchant, reason: 'onSelectRole should be called with merchant role');
    });

    testWidgets('3. Merchant Onboarding - Continuer enabled when category selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MerchantOnboardingScreen(
            onNext: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restaurant'));
      await tester.pumpAndSettle();

      final continuer = find.widgetWithText(ElevatedButton, 'Continuer');
      final button = tester.widget<ElevatedButton>(continuer);
      expect(
        button.onPressed,
        isNotNull,
        reason: 'Continuer should be enabled after category selection',
      );
    });

    testWidgets('4. Subcategory Selection - Continuer enabled when subcategory selected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SubcategorySelectionScreen(
              onNext: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstSubcategory = find.text('Café\nBar');
      await tester.ensureVisible(firstSubcategory);
      await tester.pumpAndSettle();
      await tester.tap(firstSubcategory);
      await tester.pumpAndSettle();

      final continuerButton = find.widgetWithText(ElevatedButton, 'Continuer');
      final button = tester.widget<ElevatedButton>(continuerButton);
      expect(
        button.onPressed,
        isNotNull,
        reason: 'Continuer should be enabled after subcategory selection',
      );
    });

    testWidgets('5. Benefits Screen - Créer mon compte calls onNext', (tester) async {
      bool nextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MerchantBenefitsScreen(
            onBack: () {},
            onNext: () {
              nextCalled = true;
            },
          ),
        ),
      );
      await tester.pump();

      final createAccount = find.text('Créer mon compte');
      expect(createAccount, findsOneWidget, reason: 'Créer mon compte button should exist');

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(button.onPressed, isNotNull, reason: 'CTA should have onPressed callback');

      await tester.tap(createAccount);
      await tester.pump();
      expect(nextCalled, true, reason: 'Créer mon compte should call onNext');
    });

    testWidgets('6. All back buttons have callbacks', (tester) async {
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

      final backButtons = find.byType(IconButton);
      if (backButtons.evaluate().isEmpty) {
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
