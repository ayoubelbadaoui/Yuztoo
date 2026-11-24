import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/utils/email_validator.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/providers.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/state/auth_state.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/application/onboarding_flow_provider.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/onboarding_flow_screen.dart';

Future<String> _prefilledContactEmail(
    WidgetTester tester, String authEmail) async {
  final container = ProviderContainer(overrides: [
    authStateProvider.overrideWith(
      (ref) => Authenticated(AuthUser(
        id: 'm1',
        email: authEmail,
        roles: const {'client': false, 'merchant': true, 'provider': true},
        primaryRole: 'merchant',
      )),
    ),
  ]);
  addTearDown(container.dispose);
  container.read(onboardingFlowProvider.notifier).restore(
        const MerchantOnboardingData(address: '1 rue de la Paix'),
      );
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: MerchantOnboardingFlowScreen(
        onBack: () {},
        onComplete: () {},
        initialStep: 6, // address + email + phone
      ),
    ),
  ));
  await tester.pumpAndSettle();
  final field = tester.widget<TextField>(find.byWidgetPredicate((w) =>
      w is TextField &&
      (w.decoration?.hintText ?? '').startsWith('Email de contact')));
  return field.controller!.text;
}

void main() {
  test('EmailValidator recognises Apple relay addresses', () {
    expect(EmailValidator.isApplePrivateRelay('ab12cd@privaterelay.appleid.com'),
        isTrue);
    expect(EmailValidator.isApplePrivateRelay(' AB@PrivateRelay.AppleID.com '),
        isTrue);
    expect(EmailValidator.isApplePrivateRelay('contact@boulangerie.fr'), isFalse);
    expect(EmailValidator.isPublicContactCandidate('contact@boulangerie.fr'),
        isTrue);
    expect(EmailValidator.isPublicContactCandidate('x@privaterelay.appleid.com'),
        isFalse);
    expect(EmailValidator.isPublicContactCandidate('demo@example.com'), isFalse);
  });

  testWidgets('Apple « Masquer mon adresse »: contact email is NOT prefilled',
      (tester) async {
    expect(
        await _prefilledContactEmail(
            tester, 'k7x2q9@privaterelay.appleid.com'),
        isEmpty);
  });

  testWidgets('normal login email is still prefilled', (tester) async {
    expect(await _prefilledContactEmail(tester, 'patron@gmail.com'),
        'patron@gmail.com');
  });
}
