// On-device onboarding checks (iPhone / Android), driven automatically.
//
//   flutter test integration_test/onboarding_flow_test.dart -d <device> --flavor prod
//
// Real widgets, real keyboard / gestures and the real geo.api.gouv.fr city
// search. Saving is faked: nothing is written to Firebase.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/entities/french_commune.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/providers.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/state/auth_state.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/repositories/user_repository.dart';
import 'package:flutter_yuztoo/feature/auth/core/infrastructure/user_repository_provider.dart';
import 'package:flutter_yuztoo/feature/client_onboarding/presentation/client_onboarding_screen.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/onboarding_flow_screen.dart';

const _clientUser = AuthUser(
  id: 'it-client',
  email: 'it@example.com',
  roles: {'client': true, 'merchant': false, 'provider': false},
  primaryRole: 'client',
);

class _SavedProfile {
  _SavedProfile(this.displayName, this.city, this.commune);
  final String displayName;
  final String? city;
  final FrenchCommune? commune;
}

/// Records completeClientProfile instead of writing to Firestore.
class _RecordingUserRepository implements UserRepository {
  final List<_SavedProfile> saved = [];

  @override
  Future<Result<Unit>> completeClientProfile({
    required String uid,
    required String displayName,
    String? city,
    FrenchCommune? commune,
    String? photoUrl,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) async {
    saved.add(_SavedProfile(displayName, city, commune));
    return const Right<AppFailure, Unit>(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pumps until [finder] shows up (real network), or fails after [timeout].
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Not found after ${timeout.inSeconds}s: $finder');
}

Future<_RecordingUserRepository> pumpClientOnboarding(
  WidgetTester tester, {
  required VoidCallback onComplete,
}) async {
  final repo = _RecordingUserRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => const Authenticated(_clientUser)),
        userRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(home: ClientOnboardingScreen(onComplete: onComplete)),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> fillNameStep(WidgetTester tester) async {
  await tester.tap(find.text('Commencer'));
  await tester.pumpAndSettle();
  expect(find.text('Comment vous appelez-vous ?'), findsOneWidget);
  await tester.enterText(find.widgetWithText(TextField, 'Prénom'), 'Sara');
  await tester.enterText(
      find.widgetWithText(TextField, 'Nom de famille'), 'Test');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
}

/// Opens the city sheet, searches the real API and picks [city].
Future<void> pickCity(WidgetTester tester, String query, String city) async {
  await tester.tap(find.text('Sélectionnez votre ville').first);
  await tester.pumpAndSettle();
  await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher une ville...'), query);
  final result = find.text(city);
  await pumpUntilFound(tester, result);
  await tester.tap(result.first);
  // Sheet closes; the choice must show WITHOUT waiting for the details call.
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Client onboarding', () {
    testWidgets('full flow with a real city: Suivant works right after choice',
        (tester) async {
      var completed = false;
      final repo =
          await pumpClientOnboarding(tester, onComplete: () => completed = true);

      await fillNameStep(tester);
      expect(find.text('Date de naissance'), findsOneWidget);
      await tester.tap(find.text('Passer cette étape'));
      await tester.pumpAndSettle();

      expect(find.text('Dans quelle ville êtes-vous ?'), findsOneWidget);
      await pickCity(tester, 'Héricourt', 'Héricourt');

      // The reported bug: city chosen, then « Suivant » did nothing.
      expect(find.text('Héricourt'), findsWidgets);
      expect(find.text('Suivant'), findsOneWidget,
          reason: 'city chosen → CTA must read « Suivant » immediately');
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Photo de profil'), findsOneWidget);

      await tester.tap(find.text('Terminer sans photo'));
      await pumpUntilFound(tester, find.byType(ClientOnboardingScreen),
          timeout: const Duration(seconds: 2));
      final end = DateTime.now().add(const Duration(seconds: 10));
      while (!completed && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(completed, isTrue, reason: 'onboarding must finish');
      expect(repo.saved, hasLength(1));
      expect(repo.saved.single.displayName, 'Sara Test');
      expect(repo.saved.single.city, 'Héricourt');
      // Héricourt exists in 70 and 62: the picked one is the 70 one by
      // default (most populous) — at least it must carry an INSEE code.
      expect(repo.saved.single.commune?.inseeCode, isNotNull,
          reason: 'commune details should arrive on a normal network');
    });

    testWidgets('city is optional: « Passer cette étape » works',
        (tester) async {
      var completed = false;
      final repo =
          await pumpClientOnboarding(tester, onComplete: () => completed = true);
      await fillNameStep(tester);
      await tester.tap(find.text('Passer cette étape')); // DOB
      await tester.pumpAndSettle();
      await tester.tap(find.text('Passer cette étape')); // city
      await tester.pumpAndSettle();
      expect(find.text('Photo de profil'), findsOneWidget);
      await tester.tap(find.text('Terminer sans photo'));
      final end = DateTime.now().add(const Duration(seconds: 10));
      while (!completed && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(completed, isTrue);
      expect(repo.saved.single.city, isNull);
    });

    testWidgets('fast double tap on « Suivant » never skips a step',
        (tester) async {
      await pumpClientOnboarding(tester, onComplete: () {});
      await fillNameStep(tester);
      expect(find.text('Date de naissance'), findsOneWidget);

      final skip = find.text('Passer cette étape');
      final pos = tester.getCenter(skip);
      await tester.tapAt(pos);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(pos); // second tap during the transition
      await tester.pumpAndSettle();

      expect(find.text('Dans quelle ville êtes-vous ?'), findsOneWidget,
          reason: 'second tap must not jump past the city step');
    });

    testWidgets('back from the city step returns to date of birth',
        (tester) async {
      await pumpClientOnboarding(tester, onComplete: () {});
      await fillNameStep(tester);
      await tester.tap(find.text('Passer cette étape'));
      await tester.pumpAndSettle();
      expect(find.text('Dans quelle ville êtes-vous ?'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Date de naissance'), findsOneWidget);
    });
  });

  group('Merchant onboarding', () {
    testWidgets('owner → name → … reaches city; city enables Suivant',
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

      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      // Owner info: first + last name (DOB optional).
      final ownerFields = find.byType(TextField);
      await tester.enterText(ownerFields.first, 'Sara');
      await tester.enterText(ownerFields.last, 'Test');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Suivant'));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Shop name.
      await tester.enterText(find.byType(TextField), 'Boutique Test');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Suivant'));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Merchant type: pick the first option.
      final typeCards = find.byType(GestureDetector);
      expect(typeCards, findsWidgets);
      // Walk forward until the city step, tapping the first selectable
      // card then « Suivant » (type step has a few choices).
      for (var i = 0;
          i < 3 && find.text('Sélectionnez votre ville').evaluate().isEmpty;
          i++) {
        final cards = find.byWidgetPredicate(
            (w) => w is GestureDetector && w.onTap != null);
        await tester.tap(cards.at(2), warnIfMissed: false);
        await tester.pumpAndSettle();
        final next = find.text('Suivant');
        if (next.evaluate().isNotEmpty) {
          await tester.ensureVisible(next);
          await tester.tap(next, warnIfMissed: false);
          await tester.pumpAndSettle();
        }
      }

      expect(find.text('Sélectionnez votre ville'), findsOneWidget,
          reason: 'should have reached the city step');
      await pickCity(tester, 'Montbéliard', 'Montbéliard');
      expect(find.text('Montbéliard'), findsWidgets);

      final suivant = find.text('Suivant');
      await tester.ensureVisible(suivant);
      await tester.tap(suivant);
      await tester.pumpAndSettle();
      expect(find.text('Sélectionnez votre ville'), findsNothing,
          reason: 'Suivant after the city must move on');
    });
  });
}
