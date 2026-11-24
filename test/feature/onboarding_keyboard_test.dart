import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/providers.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/state/auth_state.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/client_onboarding/presentation/client_onboarding_screen.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/application/onboarding_flow_provider.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/onboarding_flow_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _user = AuthUser(
  id: 'u1',
  email: 'sara@example.com',
  roles: {'client': true, 'merchant': false, 'provider': false},
  primaryRole: 'client',
);

/// iPhone SE-sized screen with the soft keyboard open (≈ 300 pt tall,
/// iOS with predictive bar / Samsung keyboard with toolbar).
Future<void> _smallPhoneWithKeyboard(WidgetTester tester) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(375, 667) * 2;
  tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 2);
  addTearDown(tester.view.reset);
}

/// The CTA must be reachable (scrolled into view if needed) and tappable —
/// i.e. not hidden behind the keyboard.
Future<void> _expectTappableAboveKeyboard(
    WidgetTester tester, Finder cta) async {
  await tester.ensureVisible(cta);
  await tester.pumpAndSettle();
  final rect = tester.getRect(cta);
  const keyboardTop = 667 - 300;
  expect(rect.bottom, lessThanOrEqualTo(keyboardTop),
      reason: '$cta is under the keyboard (bottom ${rect.bottom})');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('client name step: Suivant stays above the keyboard',
      (tester) async {
    await _smallPhoneWithKeyboard(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => const Authenticated(_user)),
        ],
        child: MaterialApp(home: ClientOnboardingScreen(onComplete: () {})),
      ),
    );
    await tester.pumpAndSettle();
    // No keyboard on « Bienvenue »; it opens with the name fields.
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 2);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Prénom'), 'Sara');
    await tester.enterText(
        find.widgetWithText(TextField, 'Nom de famille'), 'Test');
    await tester.pumpAndSettle();

    await _expectTappableAboveKeyboard(tester, find.text('Suivant'));
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Date de naissance'), findsOneWidget);
  });

  // 1 Owner · 2 Name · 6 Address (email + phone) · 7 Description: every
  // merchant step with a keyboard.
  for (final step in [1, 2, 6, 7]) {
    testWidgets('merchant step $step: Suivant stays above the keyboard',
        (tester) async {
      await _smallPhoneWithKeyboard(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(onboardingFlowProvider.notifier).restore(
            const MerchantOnboardingData(
              ownerFirstName: 'Sara',
              ownerLastName: 'Test',
              fullName: 'Boulangerie Test',
              city: 'Montbéliard',
              address: '1 rue de la Paix',
              contactEmail: 'shop@example.fr',
              description: 'Pain au levain',
              merchantType: 'b2c',
            ),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MerchantOnboardingFlowScreen(
              onBack: () {},
              onComplete: () {},
              initialStep: step,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cta = find.text('Suivant');
      expect(cta, findsOneWidget);
      await _expectTappableAboveKeyboard(tester, cta);
    });
  }
}
