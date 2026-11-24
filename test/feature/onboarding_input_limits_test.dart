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

Future<void> _pumpClient(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => const Authenticated(_user)),
      ],
      child: MaterialApp(home: ClientOnboardingScreen(onComplete: () {})),
    ),
  );
  await tester.pumpAndSettle();
}

/// Merchant wizard opened directly on the address step (full mode:
/// 0 Welcome · 1 Owner · 2 Name · 3 Type · 4 City · 5 Image · 6 Address).
Future<void> _pumpMerchantAddressStep(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(onboardingFlowProvider.notifier).restore(
        const MerchantOnboardingData(
          fullName: 'Boulangerie Test',
          city: 'Montbéliard',
          address: '1 rue de la Paix',
          contactEmail: 'shop@example.fr',
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
          initialStep: 6,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _addressHint => find.text('123 Rue de la République, Paris');

Future<void> _tapSuivant(WidgetTester tester) async {
  final next = find.text('Suivant');
  await tester.ensureVisible(next);
  await tester.tap(next, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Finder _phoneField() => find.byWidgetPredicate((w) =>
    w is TextField &&
    w.decoration?.hintText == 'Numéro de téléphone professionnel');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('client onboarding', () {
    testWidgets('welcome step offers a way out (wrong account)',
        (tester) async {
      await _pumpClient(tester);
      final leave = find.text('Ce n\'est pas votre compte ? Se déconnecter');
      expect(leave, findsOneWidget);

      await tester.tap(leave);
      await tester.pumpAndSettle();
      expect(find.text('Quitter l\'inscription ?'), findsOneWidget);
      expect(find.textContaining('sara@example.com'), findsOneWidget,
          reason: 'shows which account is signed in');

      await tester.tap(find.text('Rester'));
      await tester.pumpAndSettle();
      expect(find.text('Quitter l\'inscription ?'), findsNothing);
      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('first / last name are capped at 50 characters',
        (tester) async {
      await _pumpClient(tester);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      final first = find.widgetWithText(TextField, 'Prénom');
      await tester.enterText(first, 'A' * 500);
      await tester.pump();
      final text = tester.widget<TextField>(first).controller!.text;
      expect(text.length, 50);
    });
  });

  group('merchant address step: phone', () {
    testWidgets('empty phone is fine (optional)', (tester) async {
      await _pumpMerchantAddressStep(tester);
      expect(_addressHint, findsOneWidget);
      await _tapSuivant(tester);
      expect(_addressHint, findsNothing, reason: 'moved past the address step');
    });

    testWidgets('a started number (« 06 ») blocks Suivant with a hint',
        (tester) async {
      await _pumpMerchantAddressStep(tester);
      await tester.enterText(_phoneField(), '06');
      await tester.pumpAndSettle();
      expect(find.textContaining('Numéro incomplet'), findsOneWidget);
      await _tapSuivant(tester);
      expect(_addressHint, findsOneWidget, reason: 'must stay on the step');
    });

    for (final input in ['0612345678', '612345678', '+33612345678']) {
      testWidgets('complete number « $input » is accepted', (tester) async {
        await _pumpMerchantAddressStep(tester);
        await tester.enterText(_phoneField(), input);
        await tester.pumpAndSettle();
        expect(find.textContaining('Numéro incomplet'), findsNothing);
        await _tapSuivant(tester);
        expect(_addressHint, findsNothing);
      });
    }
  });

  group('merchant shop name', () {
    testWidgets('capped at 60 characters', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MerchantOnboardingFlowScreen(
              onBack: () {},
              onComplete: () {},
              initialStep: 2, // shop name
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      await tester.enterText(field, 'B' * 300);
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text.length, 60);
    });
  });
}
