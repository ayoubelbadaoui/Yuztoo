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

/// (name, logical size, text scale)
const _devices = <(String, Size, double)>[
  ('iPhone SE, texte x2', Size(375, 667), 2.0),
  ('iPhone SE, texte x1.3', Size(375, 667), 1.3),
  ('petit Samsung 360x640, texte x1.5', Size(360, 640), 1.5),
];

Widget _scaled(Widget child, double scale) => MediaQuery(
      data: MediaQueryData(
        size: const Size(375, 667),
        textScaler: TextScaler.linear(scale),
        padding: const EdgeInsets.only(top: 20, bottom: 0),
      ),
      child: child,
    );

Future<void> _setDevice(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.reset);
}

List<String> _overflows(WidgetTester tester) {
  final out = <String>[];
  Object? e;
  while ((e = tester.takeException()) != null) {
    out.add(e.toString().split('\n').first);
  }
  return out;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (name, size, scale) in _devices) {
    testWidgets('client onboarding, every step, $name', (tester) async {
      await _setDevice(tester, size);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Authenticated(_user)),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: ClientOnboardingScreen(onComplete: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final problems = <String>[];
      problems.addAll(_overflows(tester).map((e) => 'Bienvenue: $e'));

      Future<void> tapText(String t) async {
        final f = find.text(t);
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      await tapText('Commencer');
      problems.addAll(_overflows(tester).map((e) => 'Nom: $e'));
      await tester.enterText(find.widgetWithText(TextField, 'Prénom'), 'Marie-Christine');
      await tester.enterText(
          find.widgetWithText(TextField, 'Nom de famille'), 'de La Fontaine-Dupont');
      await tester.pumpAndSettle();
      await tapText('Suivant');
      problems.addAll(_overflows(tester).map((e) => 'Naissance: $e'));
      expect(find.text('Date de naissance'), findsOneWidget,
          reason: '« Suivant » must stay reachable on $name');
      await tapText('Passer cette étape');
      problems.addAll(_overflows(tester).map((e) => 'Ville: $e'));
      await tapText('Passer cette étape');
      problems.addAll(_overflows(tester).map((e) => 'Photo: $e'));
      expect(find.text('Terminer sans photo'), findsOneWidget);

      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    testWidgets('merchant onboarding, all 10 steps, $name', (tester) async {
      await _setDevice(tester, size);
      final problems = <String>[];
      for (var step = 0; step <= 9; step++) {
        final container = ProviderContainer();
        container.read(onboardingFlowProvider.notifier).restore(
              const MerchantOnboardingData(
                ownerFirstName: 'Marie-Christine',
                ownerLastName: 'de La Fontaine-Dupont',
                fullName: 'La Boulangerie Artisanale du Vieux Montbéliard',
                city: 'Courcelles-lès-Montbéliard',
                address: '123 avenue du Maréchal de Lattre de Tassigny',
                contactEmail: 'contact@boulangerie-artisanale.fr',
                merchantType: 'b2c',
              ),
            );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: MerchantOnboardingFlowScreen(
                key: ValueKey('step$step'),
                onBack: () {},
                onComplete: () {},
                initialStep: step,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        problems.addAll(_overflows(tester).map((e) => 'étape $step: $e'));
        container.dispose();
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }
}
