import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/core/infrastructure/ble_proximity_notifier.dart';
import 'package:flutter_yuztoo/core/shared/widgets/proximity_list_avatar.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/active_validation_providers.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/accept_ble_passage_as_merchant.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/prepare_merchant_passage_validation.dart';
import 'package:flutter_yuztoo/feature/loyalty/presentation/merchant_passage_validation_flow.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/active_validation_request.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/active_validation_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/application/providers.dart'
    as merchant_providers;
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/failures/ble_passage_failure.dart';
import 'package:flutter_yuztoo/feature/loyalty/infrastructure/active_validation_repository_provider.dart';
import 'package:flutter_yuztoo/feature/merchant/presentation/widgets/ble_client_detection_sheet.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';

class _FakeAcceptBle extends Fake implements AcceptBlePassageAsMerchant {
  int callCount = 0;
  bool shouldFail = false;

  @override
  Future<Result<ActiveValidationRequest>> call({
    required String merchantId,
    required String clientUid,
    required ActiveValidationRequest? existingSession,
  }) async {
    callCount++;
    if (shouldFail) {
      return const Left(
        BlePassageSessionFailure('erreur simulée'),
      );
    }
    return Right(
      ActiveValidationRequest(
        merchantId: merchantId,
        clientUid: clientUid,
        clientDisplayName: 'Alice',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
        source: ActiveValidationSource.ble,
        merchantBleConnectedAt: DateTime(2026, 1, 1),
      ),
    );
  }
}

class _FakeActiveValidationRepo implements ActiveValidationRepository {
  @override
  Stream<ActiveValidationRequest?> watchClientSession({
    required String merchantId,
    required String clientUid,
  }) =>
      Stream<ActiveValidationRequest?>.value(
        ActiveValidationRequest(
          merchantId: merchantId,
          clientUid: clientUid,
          clientDisplayName: 'Alice',
          status: ActiveValidationStatus.awaiting,
          programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
          source: ActiveValidationSource.ble,
          clientBleConnectedAt: DateTime(2026, 1, 1),
        ),
      );

  @override
  Future<Result<ActiveValidationRequest?>> getClientSession({
    required String merchantId,
    required String clientUid,
  }) async =>
      Right(
        ActiveValidationRequest(
          merchantId: merchantId,
          clientUid: clientUid,
          clientDisplayName: 'Alice',
          status: ActiveValidationStatus.awaiting,
          programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
          source: ActiveValidationSource.ble,
          clientBleConnectedAt: DateTime(2026, 1, 1),
        ),
      );

  @override
  Future<Result<void>> cancelByClient({
    required String merchantId,
    required String clientUid,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> cancelByMerchant({
    required String merchantId,
    required String clientUid,
    String? reason,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> completeSession({
    required String merchantId,
    required String clientUid,
    int? resultValidatedDelta,
    double? resultSpendDelta,
    double? declaredSpendEuros,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> createBleSession({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
    required String merchantDisplayName,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> createForClient({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> markMerchantBleConnected({
    required String merchantId,
    required String clientUid,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> markOpened({
    required String merchantId,
    required String clientUid,
  }) async =>
      const Right(null);

  @override
  Stream<List<ActiveValidationRequest>> watchMerchantQueue(String merchantId) =>
      Stream<List<ActiveValidationRequest>>.value(const []);
}

const _kTestMerchant = Merchant(
  id: 'merchant-1',
  ownerUid: 'owner-uid',
  name: 'Café Yuztoo',
  email: 'cafe@yuztoo.app',
  phone: '+33600000000',
  city: 'Paris',
  status: 'active',
  loyaltyEnabled: true,
  loyaltyProgram: LoyaltyProgramConfig(programEnabled: true),
);

Widget _buildSheet({
  required BleClientDetection detection,
  required Merchant? merchant,
  AcceptBlePassageAsMerchant? acceptUseCase,
  VoidCallback? onDismiss,
}) {
  final fakeAccept = acceptUseCase ?? _FakeAcceptBle();

  return ProviderScope(
    overrides: [
      merchant_providers.currentMerchantForOwnerProvider.overrideWith(
        (_) async => merchant,
      ),
      acceptBlePassageAsMerchantProvider.overrideWithValue(fakeAccept),
      prepareMerchantPassageValidationProvider.overrideWith(
        (ref) => const PrepareMerchantPassageValidation(),
      ),
      showMerchantPassageValidationSheetProvider.overrideWith(
        (ref) =>
            ({required context, required merchant, required session}) async {},
      ),
      activeValidationRepositoryProvider
          .overrideWithValue(_FakeActiveValidationRepo()),
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

void main() {
  group('BleClientDetectionSheet', () {
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

      expect(find.byType(ProximityListAvatar), findsOneWidget);
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
      final slowProvider =
          merchant_providers.currentMerchantForOwnerProvider.overrideWith(
        (_) => Completer<Merchant?>().future,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            slowProvider,
            acceptBlePassageAsMerchantProvider
                .overrideWithValue(_FakeAcceptBle()),
            prepareMerchantPassageValidationProvider.overrideWith(
              (ref) => const PrepareMerchantPassageValidation(),
            ),
            showMerchantPassageValidationSheetProvider.overrideWith(
              (ref) => (
                  {required context,
                  required merchant,
                  required session}) async {},
            ),
            activeValidationRepositoryProvider
                .overrideWithValue(_FakeActiveValidationRepo()),
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
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

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

    testWidgets('tapping Confirmer calls accept BLE use case', (tester) async {
      final fakeAccept = _FakeAcceptBle();

      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(
          clientId: 'uid-9',
          displayName: 'Alice',
        ),
        merchant: _kTestMerchant,
        acceptUseCase: fakeAccept,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmer le passage'));
      await tester.pumpAndSettle();

      expect(fakeAccept.callCount, 1);
    });

    testWidgets('failed confirmation shows snackbar error', (tester) async {
      final fakeAccept = _FakeAcceptBle()..shouldFail = true;

      await tester.pumpWidget(_buildSheet(
        detection: const BleClientDetection(clientId: 'uid-10'),
        merchant: _kTestMerchant,
        acceptUseCase: fakeAccept,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmer le passage'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('erreur simulée'), findsOneWidget);
    });
  });
}
