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
      'merchant onboarding mounts only the active text-input step and keeps focus',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MerchantOnboardingFlowScreen(
            onBack: () {},
            onComplete: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField, skipOffstage: false), findsNothing);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    final ownerFields = find.byType(TextField);
    expect(ownerFields, findsNWidgets(2));
    await tester.tap(ownerFields.first);
    await tester.enterText(ownerFields.first, 'Jérôme');
    await tester.enterText(ownerFields.last, 'Pieras');
    await tester.tap(ownerFields.first);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -40),
    );
    await tester.pump();

    final ownerEditable = find.descendant(
      of: ownerFields.first,
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(ownerEditable).focusNode.hasFocus,
      isTrue,
    );

    await tester.ensureVisible(find.text('Suivant'));
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(find.textContaining('votre commerce'), findsWidgets);
    expect(
      find.byType(TextField, skipOffstage: false),
      findsOneWidget,
      reason: 'off-screen onboarding fields must be unmounted for Samsung IME',
    );
  });

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
        reason: 'DOB is collected on the client profile already; re-asking on '
            'merchant upgrade is the user-reported regression');

    // Logo upload step is skipped too — the dual-profile user already has a
    // profile photo on their client account.
    expect(find.text('Ajoutez votre logo'), findsNothing);
  });
}
