import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/core/infrastructure/ble_proximity_notifier.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/merchant/application/providers.dart'
    as merchant_providers;
import 'package:flutter_yuztoo/feature/merchant/application/use_cases/merchant_record_client_passage.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/presentation/widgets/ble_client_detection_sheet.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class _FakePassageUseCase extends Fake implements MerchantRecordClientPassage {
  int callCount = 0;
  bool shouldFail = false;

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> call({
    required String clientUid,
    required Merchant merchant,
    double? purchaseAmountEuros,
  }) async {
    callCount++;
    if (shouldFail) {
      return const Left(UnexpectedFailure(message: 'erreur simulée'));
    }
    return const Right(ClientMerchantLoyaltyProgress.empty());
  }
}

const _kTestMerchant = Merchant(
  id: 'merchant-1',
  ownerUid: 'owner-uid',
  name: 'Café Yuztoo',
  email: 'cafe@yuztoo.app',
  phone: '+33600000000',
  city: 'Paris',
  status: 'active',
  // The BLE detection sheet hides the "Confirmer le passage" button when
  // `_merchantLoyaltyLive` returns false (i.e. the merchant hasn't enabled
  // loyalty). The test fixture needs loyalty live to exercise the confirm path.
  loyaltyEnabled: true,
  loyaltyProgram: LoyaltyProgramConfig(programEnabled: true),
);

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _buildSheet({
  required BleClientDetection detection,
  required Merchant? merchant,
  MerchantRecordClientPassage? useCase,
  VoidCallback? onDismiss,
}) {
  final fakeUseCase = useCase ?? _FakePassageUseCase();

  return ProviderScope(
    overrides: [
      merchant_providers.currentMerchantForOwnerProvider.overrideWith(
        (_) async => merchant,
      ),
      merchant_providers.merchantRecordClientPassageProvider
          .overrideWithValue(fakeUseCase),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BleClientDetectionSheet(
          detection: detection,
          onDismiss: onDismiss ?? () {},
        ),
      ),
    ),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('BleClientDetectionSheet', () {
    // ── Rendering ───────────────────────────────────────────────────────────

    testWidgets('shows client display name when provided', (tester) async {
      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(
          clientId: 'uid-1',
          displayName: 'Sophie Dupont',
        ),
        merchant: _kTestMerchant,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sophie Dupont'), findsOneWidget);
    });

    testWidgets('falls back to "Client" label when displayName is null',
        (tester) async {
      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(clientId: 'uid-2'),
        merchant: _kTestMerchant,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Client'), findsOneWidget);
    });

    testWidgets('shows initials avatar derived from name', (tester) async {
      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(
          clientId: 'uid-3',
          displayName: 'Jean Martin',
        ),
        merchant: _kTestMerchant,
      ));
      await tester.pumpAndSettle();

      // "Jean Martin" → initials "JM"
      expect(find.text('JM'), findsOneWidget);
    });

    testWidgets('shows single-letter initial for single-word name',
        (tester) async {
      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(
          clientId: 'uid-4',
          displayName: 'Camille',
        ),
        merchant: _kTestMerchant,
      ));
      await tester.pumpAndSettle();

      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('shows "Client à proximité" label', (tester) async {
      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(clientId: 'uid-5'),
        merchant: _kTestMerchant,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Client à proximité'), findsOneWidget);
    });

    testWidgets('shows confirm and ignore buttons', (tester) async {
      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(clientId: 'uid-6'),
        merchant: _kTestMerchant,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Confirmer le passage'), findsOneWidget);
      expect(find.text('Ignorer'), findsOneWidget);
    });

    testWidgets('shows loading indicator while merchant is loading',
        (tester) async {
      // Completer that never completes — simulates perpetual loading without
      // leaving a pending timer that would fail the test teardown assertion.
      final slowProvider =
          merchant_providers.currentMerchantForOwnerProvider.overrideWith(
        (_) => Completer<Merchant?>().future,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            slowProvider,
            merchant_providers.merchantRecordClientPassageProvider
                .overrideWithValue(_FakePassageUseCase()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: BleClientDetectionSheet(
                detection: const BleClientDetection(clientId: 'uid-7'),
                onDismiss: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(); // one frame — merchant not yet resolved

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    // ── Ignore path ─────────────────────────────────────────────────────────

    testWidgets('tapping Ignorer calls onDismiss', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(clientId: 'uid-8'),
        merchant: _kTestMerchant,
        onDismiss: () => dismissed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ignorer'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    // ── Confirm path ────────────────────────────────────────────────────────

    testWidgets('tapping Confirmer calls the passage use case', (tester) async {
      final fakeUseCase = _FakePassageUseCase();

      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(
          clientId: 'uid-9',
          displayName: 'Alice',
        ),
        merchant: _kTestMerchant,
        useCase: fakeUseCase,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmer le passage'));
      await tester.pumpAndSettle();

      expect(fakeUseCase.callCount, 1);
    });

    testWidgets('failed confirmation shows error message', (tester) async {
      final fakeUseCase = _FakePassageUseCase()..shouldFail = true;

      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(clientId: 'uid-10'),
        merchant: _kTestMerchant,
        useCase: fakeUseCase,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmer le passage'));
      await tester.pumpAndSettle();

      expect(find.text('erreur simulée'), findsOneWidget);
    });
  });
}
