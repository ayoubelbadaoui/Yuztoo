import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/entities/french_commune.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/application/merchant_onboarding_draft.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/application/onboarding_flow_provider.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/onboarding_flow_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

MerchantOnboardingData _full() => MerchantOnboardingData(
      ownerFirstName: 'Sara',
      ownerLastName: 'Test',
      ownerDateOfBirth: DateTime(1990, 5, 4),
      fullName: 'Boulangerie Test',
      city: 'Montbéliard',
      commune: const FrenchCommune(
        name: 'Montbéliard',
        inseeCode: '25388',
        departmentCode: '25',
        epciCode: '200065647',
      ),
      address: '1 rue de la Paix',
      contactEmail: 'shop@example.fr',
      websiteUrl: 'https://example.fr',
      categoryId: 'food',
      categoryTitle: 'Alimentation',
      subcategoryTitle: 'Boulangerie',
      description: 'Pain au levain',
      hoursJson: const {
        'monday': {'open': '08:00', 'close': '19:00'},
      },
      merchantType: 'b2c',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('MerchantOnboardingDraftStore', () {
    test('save → load keeps every field and the step', () async {
      await MerchantOnboardingDraftStore.save(
        'm1',
        MerchantOnboardingDraft(data: _full(), step: 6, skipPersonalInfo: false),
      );
      final draft = await MerchantOnboardingDraftStore.load('m1');
      expect(draft, isNotNull);
      final d = draft!.data;
      expect(draft.step, 6);
      expect(d.ownerFirstName, 'Sara');
      expect(d.ownerDateOfBirth, DateTime(1990, 5, 4));
      expect(d.fullName, 'Boulangerie Test');
      expect(d.city, 'Montbéliard');
      expect(d.commune?.epciCode, '200065647');
      expect(d.address, '1 rue de la Paix');
      expect(d.contactEmail, 'shop@example.fr');
      expect(d.categoryId, 'food');
      expect(d.subcategoryTitle, 'Boulangerie');
      expect(d.hoursJson?['monday'], {'open': '08:00', 'close': '19:00'});
      expect(d.merchantType, 'b2c');
      expect(d.phoneNumber, isNull, reason: 'phone stays optional');
    });

    test('step only resumes in the same mode (step lists differ)', () {
      final draft =
          MerchantOnboardingDraft(data: _full(), step: 6, skipPersonalInfo: false);
      expect(draft.resumeStep(skipPersonalInfo: false, totalSteps: 10), 6);
      expect(draft.resumeStep(skipPersonalInfo: true, totalSteps: 8), 0);
      final far =
          MerchantOnboardingDraft(data: _full(), step: 42, skipPersonalInfo: true);
      expect(far.resumeStep(skipPersonalInfo: true, totalSteps: 8), 7);
    });

    test('purged logo / cover files are dropped, the rest is kept', () async {
      await MerchantOnboardingDraftStore.save(
        'm1',
        const MerchantOnboardingDraft(
          data: MerchantOnboardingData(
            fullName: 'X',
            imagePath: '/gone/logo.png',
            bannerImagePath: '/gone/banner.png',
          ),
          step: 5,
          skipPersonalInfo: false,
        ),
      );
      final d = (await MerchantOnboardingDraftStore.load('m1'))!.data;
      expect(d.imagePath, isNull);
      expect(d.bannerImagePath, isNull);
      expect(d.fullName, 'X');
    });

    test('corrupt or foreign data → fresh start, never a crash', () async {
      SharedPreferences.setMockInitialValues(
          {'merchant_onboarding_draft_m1': '{broken'});
      expect(await MerchantOnboardingDraftStore.load('m1'), isNull);
      SharedPreferences.setMockInitialValues(
          {'merchant_onboarding_draft_m1': '{"step":"3","data":1}'});
      expect(await MerchantOnboardingDraftStore.load('m1'), isNull);
    });

    test('per account, and cleared after the shop is created', () async {
      await MerchantOnboardingDraftStore.save('alice',
          MerchantOnboardingDraft(data: _full(), step: 2, skipPersonalInfo: false));
      expect(await MerchantOnboardingDraftStore.load('bob'), isNull);
      await MerchantOnboardingDraftStore.clear('alice');
      expect(await MerchantOnboardingDraftStore.load('alice'), isNull);
    });
  });

  group('MerchantOnboardingFlowScreen resume', () {
    testWidgets('opens on the saved step with the saved city', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(onboardingFlowProvider.notifier).restore(_full());

      final steps = <int>[];
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MerchantOnboardingFlowScreen(
              onBack: () {},
              onComplete: () {},
              // 0 Welcome · 1 Owner · 2 Name · 3 Type · 4 City
              initialStep: 4,
              onStepChanged: steps.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Montbéliard'), findsOneWidget,
          reason: 'resumes on the city step with the saved city');
      final next = find.text('Suivant');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(steps, [5], reason: 'progress reported for saving');
    });

    testWidgets('a saved step beyond the flow is clamped, not a crash',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MerchantOnboardingFlowScreen(
              onBack: () {},
              onComplete: () {},
              skipPersonalInfo: true,
              initialStep: 99,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
