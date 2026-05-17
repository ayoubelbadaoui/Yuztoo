import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/onboarding_flow_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// skipPersonalInfo contract — dual-profile client→merchant upgrade.
//
// User-reported regression: an existing client clicking "Créer un compte pro"
// was re-asked for first name, last name, and date of birth. The fix routes
// `_isDualProfile` through to `MerchantOnboardingFlowScreen.skipPersonalInfo`,
// which then omits the `_StepOwnerInfo` page from the PageView and removes
// `_StepImage` (logo upload).
//
// This test pins the contract so a future refactor can't silently re-introduce
// the regression.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  testWidgets(
      'skipPersonalInfo=true omits owner first/last/DOB and logo steps '
      'from the onboarding flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MerchantOnboardingFlowScreen(
            onBack: () {},
            onComplete: () {},
            skipPersonalInfo: true,
          ),
        ),
      ),
    );

    // The owner-info step asks for the merchant's date of birth via a
    // CupertinoDOBPicker labelled "Date de naissance". With skipPersonalInfo
    // it must NOT be present anywhere in the widget tree.
    expect(find.text('Date de naissance'), findsNothing,
        reason:
            'DOB is collected on the client profile already; re-asking on '
            'merchant upgrade is the user-reported regression');

    // Logo upload step is skipped too — the dual-profile user already has a
    // profile photo on their client account.
    expect(find.text('Ajoutez votre logo'), findsNothing);
  });

}
