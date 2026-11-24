import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/entities/french_commune.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/providers.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/state/auth_state.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/client_onboarding/application/client_onboarding_draft.dart';
import 'package:flutter_yuztoo/feature/client_onboarding/presentation/client_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _user = AuthUser(
  id: 'u1',
  email: 'sara@example.com',
  roles: {'client': true, 'merchant': false, 'provider': false},
  primaryRole: 'client',
);

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => const Authenticated(_user)),
      ],
      child: MaterialApp(home: ClientOnboardingScreen(onComplete: () {})),
    ),
  );
  // Draft load is async (SharedPreferences).
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pumpAndSettle();
}

/// Let Google Fonts finish loading so no frame is scheduled after teardown.
Future<void> _settleFonts(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ClientOnboardingDraft', () {
    test('json round trip keeps every field', () {
      final draft = ClientOnboardingDraft(
        step: 3,
        firstName: 'Sara',
        lastName: 'Test',
        dateOfBirth: DateTime(1990, 5, 4),
        city: 'Héricourt',
        commune: const FrenchCommune(
          name: 'Héricourt',
          inseeCode: '70285',
          departmentCode: '70',
          epciCode: '247000623',
        ),
      );
      final back = ClientOnboardingDraft.fromJson(draft.toJson())!;
      expect(back.step, 3);
      expect(back.firstName, 'Sara');
      expect(back.lastName, 'Test');
      expect(back.dateOfBirth, DateTime(1990, 5, 4));
      expect(back.city, 'Héricourt');
      expect(back.commune?.inseeCode, '70285');
      expect(back.commune?.epciCode, '247000623');
    });

    test('never resumes past the name step without a name', () {
      const draft = ClientOnboardingDraft(step: 4);
      expect(draft.resumeStep(4), 1);
    });

    test('step is clamped to the last step', () {
      const draft =
          ClientOnboardingDraft(step: 9, firstName: 'A', lastName: 'B');
      expect(draft.resumeStep(4), 4);
    });

    test('corrupt data → no draft (fresh start), never a crash', () async {
      SharedPreferences.setMockInitialValues(
          {'client_onboarding_draft_u1': '{not json'});
      expect(await ClientOnboardingDraftStore.load('u1'), isNull);
      expect(ClientOnboardingDraft.fromJson('nope'), isNull);
      expect(ClientOnboardingDraft.fromJson({'step': 'x'}), isNull);
    });

    test('a purged photo file is dropped, the rest is kept', () async {
      await ClientOnboardingDraftStore.save(
        'u1',
        const ClientOnboardingDraft(
          step: 4,
          firstName: 'A',
          lastName: 'B',
          localImagePath: '/does/not/exist.jpg',
        ),
      );
      final draft = await ClientOnboardingDraftStore.load('u1');
      expect(draft?.localImagePath, isNull);
      expect(draft?.firstName, 'A');
    });

    test('drafts are per account', () async {
      await ClientOnboardingDraftStore.save(
          'alice', const ClientOnboardingDraft(step: 3));
      expect(await ClientOnboardingDraftStore.load('bob'), isNull);
    });
  });

  group('ClientOnboardingScreen resume', () {
    testWidgets('app killed on the city step → reopens on the city step '
        'with the name kept', (tester) async {
      await ClientOnboardingDraftStore.save(
        'u1',
        const ClientOnboardingDraft(
          step: 3,
          firstName: 'Sara',
          lastName: 'Test',
          city: 'Héricourt',
        ),
      );

      await _pumpScreen(tester);

      expect(find.text('Dans quelle ville êtes-vous ?'), findsOneWidget,
          reason: 'must resume on the city step, not « Bienvenue »');
      expect(find.text('Héricourt'), findsOneWidget);
      expect(find.text('Suivant'), findsOneWidget);

      // Back to the name step: names restored.
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      await _settleFonts(tester);
    });

    testWidgets('progress is saved at each step', (tester) async {
      await _pumpScreen(tester);
      expect(find.text('Commencer'), findsOneWidget);

      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Prénom'), 'Sara');
      await tester.enterText(
          find.widgetWithText(TextField, 'Nom de famille'), 'Test');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));

      final draft = await tester
          .runAsync(() => ClientOnboardingDraftStore.load('u1'));
      expect(draft?.step, 2, reason: 'now on the date-of-birth step');
      expect(draft?.firstName, 'Sara');
      expect(draft?.lastName, 'Test');
      await _settleFonts(tester);
    });

    testWidgets('no draft → normal start on « Bienvenue »', (tester) async {
      await _pumpScreen(tester);
      expect(find.text('Bienvenue'), findsOneWidget);
      await _settleFonts(tester);
    });
  });
}
