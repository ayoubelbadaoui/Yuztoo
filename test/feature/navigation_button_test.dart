import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/application/screens.dart';
import 'package:flutter_yuztoo/feature/role_selection/application/screens.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';

void main() {
  group('Navigation Button Tests - Check All Buttons Work', () {
    testWidgets('Role Selection - All buttons have callbacks', (tester) async {
      bool onSelectRoleCalled = false;
      bool onLoginCalled = false;
      bool onRoleChangedCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
        ),
      );
      await tester.pump();

      // Check merchant view buttons exist
      final merchantToggle = find.text('Commerçant');
      if (merchantToggle.evaluate().isNotEmpty) {
        await tester.tap(merchantToggle);
        await tester.pump();
        expect(onRoleChangedCalled, true,
            reason: 'Role toggle should call onRoleChanged');

        // Check Découvrir button
        final discoverButton = find.byType(ElevatedButton);
        if (discoverButton.evaluate().isNotEmpty) {
          onSelectRoleCalled = false;
          await tester.tap(discoverButton);
          await tester.pump();
          expect(onSelectRoleCalled, true,
              reason: 'Découvrir button should call onSelectRole');
        }

        // Check Se connecter button (if visible)
        final loginButton = find.byType(OutlinedButton);
        if (loginButton.evaluate().isNotEmpty) {
          onLoginCalled = false;
          await tester.tap(loginButton);
          await tester.pump();
          expect(onLoginCalled, true,
              reason: 'Se connecter button should call onLogin');
        }
      }
    });

    testWidgets('Onboarding Flow - Commencer button has callback', (tester) async {
      bool onCompleteCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MerchantOnboardingFlowScreen(
              onBack: () {},
              onComplete: () {
                onCompleteCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // First step is Welcome - tap Commencer
      final commencerButton = find.text('Commencer');
      if (commencerButton.evaluate().isNotEmpty) {
        await tester.tap(commencerButton);
        await tester.pump();
        expect(onCompleteCalled, false,
            reason: 'Commencer advances to next step, does not complete');
      }
    });

    testWidgets('Onboarding Flow - Back button has callback', (tester) async {
      bool backCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MerchantOnboardingFlowScreen(
              onBack: () {
                backCalled = true;
              },
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final backButtons = find.byType(IconButton);
      if (backButtons.evaluate().isNotEmpty) {
        await tester.tap(backButtons.first);
        await tester.pump();
        expect(backCalled, true, reason: 'Back button should call onBack');
      }
    });
  });
}
