import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/auth/core/application/providers.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/state/auth_state.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/client_onboarding/presentation/client_onboarding_screen.dart';

const _clientUser = AuthUser(
  id: 'u1',
  email: 'denis@example.com',
  phoneNumber: '+33600000000',
  roles: {'client': true, 'merchant': false, 'provider': false},
  primaryRole: 'client',
);

void main() {
  testWidgets('name step TextFields are focusable and accept text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => const Authenticated(_clientUser),
          ),
        ],
        child: MaterialApp(
          home: ClientOnboardingScreen(onComplete: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Welcome → name
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.text('Comment vous appelez-vous ?'), findsOneWidget);

    final firstName = find.widgetWithText(TextField, 'Prénom');
    final lastName = find.widgetWithText(TextField, 'Nom de famille');
    expect(firstName, findsOneWidget);
    expect(lastName, findsOneWidget);

    await tester.tap(firstName);
    await tester.pump();
    await tester.enterText(firstName, 'Denis');
    await tester.enterText(lastName, 'Grynzspan');
    await tester.pump();

    expect(find.text('Denis'), findsOneWidget);
    expect(find.text('Grynzspan'), findsOneWidget);

    // Name filled → Suivant enabled path reaches DOB (optional).
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Date de naissance'), findsOneWidget);

    // DOB skippable
    await tester.tap(find.text('Passer cette étape'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ville'), findsWidgets);

    // City skippable
    await tester.tap(find.text('Passer cette étape'));
    await tester.pumpAndSettle();
    expect(find.text('Photo de profil'), findsOneWidget);

    // Last step must stay finishable without a photo: a disabled primary CTA
    // here is what left clients stuck at onboarding.client=not_started.
    final finish = tester.widget<GestureDetector>(
      find.ancestor(
        of: find.text('Terminer sans photo'),
        matching: find.byType(GestureDetector),
      ).first,
    );
    expect(finish.onTap, isNotNull);
  });
}
