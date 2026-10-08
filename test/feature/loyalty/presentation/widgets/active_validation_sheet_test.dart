import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/active_validation_providers.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/client_loyalty_providers.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/active_validation_request.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/active_validation_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/infrastructure/active_validation_repository_provider.dart';
import 'package:flutter_yuztoo/feature/loyalty/presentation/active_validation_ui.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

class _FakeActiveValidationRepo extends Fake
    implements ActiveValidationRepository {
  @override
  Future<Result<void>> markOpened({
    required String merchantId,
    required String clientUid,
  }) async =>
      const Right(null);
}

const _spendProgram = LoyaltyProgramConfig(
  programEnabled: true,
  passageValidation: LoyaltyPassageValidation.automatic,
  triggerType: LoyaltyTriggerType.purchaseTotal,
  cumulativeSpendRequiredEuros: 150,
);

const _merchant = Merchant(
  id: 'm1',
  ownerUid: 'o1',
  name: 'La Boutique Des Lunetiers',
  email: 'a@b.c',
  phone: '+33600000000',
  city: 'Belfort',
  loyaltyEnabled: true,
  loyaltyProgram: _spendProgram,
);

const _session = ActiveValidationRequest(
  merchantId: 'm1',
  clientUid: 'c1',
  clientDisplayName: 'Maxime André',
  status: ActiveValidationStatus.awaiting,
  programSnapshot: _spendProgram,
);

Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeValidationRepositoryProvider
            .overrideWithValue(_FakeActiveValidationRepo()),
        merchantClientLoyaltyProgressProvider.overrideWith(
          (ref, params) => Stream.value(
            const ClientMerchantLoyaltyProgress.empty(),
          ),
        ),
        activeValidationSessionForDocProvider.overrideWith(
          (ref, key) => Stream<ActiveValidationRequest?>.value(_session),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showMerchantActiveValidationSheet(
                  context: context,
                  merchant: _merchant,
                  session: _session,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _typeAmount(WidgetTester tester, String amount) async {
  await tester.tap(find.byType(TextField));
  await tester.pump();
  await tester.enterText(find.byType(TextField), amount);
  await tester.pump();
  expect(tester.testTextInput.isVisible, isTrue);
}

void main() {
  group('ActiveValidationSheet keyboard', () {
    testWidgets('tapping outside the amount field hides the keyboard',
        (tester) async {
      await _openSheet(tester);
      await _typeAmount(tester, '849');

      await tester.tap(find.text('Validation de passage'));
      await tester.pump();

      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.text('849'), findsOneWidget);
    });

    testWidgets('« Valider le passage » hides the keyboard', (tester) async {
      await _openSheet(tester);
      await _typeAmount(tester, '');

      await tester.tap(find.text('Valider le passage'));
      await tester.pump();

      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.text('Indiquez le montant de l\'achat.'), findsOneWidget);
    });

    testWidgets('the sheet stays above the keyboard', (tester) async {
      const dpr = 3.0;
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = const Size(390 * dpr, 844 * dpr);
      addTearDown(tester.view.reset);

      await _openSheet(tester);
      await _typeAmount(tester, '849');

      const keyboardHeight = 300.0;
      tester.view.viewInsets =
          const FakeViewPadding(bottom: keyboardHeight * dpr);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final screenHeight = tester.view.physicalSize.height / dpr;
      final button = tester.getRect(find.text('Valider le passage'));
      expect(button.bottom, lessThanOrEqualTo(screenHeight - keyboardHeight));
    });
  });
}
