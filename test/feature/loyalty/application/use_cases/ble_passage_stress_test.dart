import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/accept_ble_passage_as_merchant.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/confirm_active_validation.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/prepare_merchant_passage_validation.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/active_validation_request.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/failures/ble_passage_failure.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/active_validation_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart'
    show ActiveValidationCompletion, ClientLoyaltyRepository;
import 'package:flutter_yuztoo/feature/client_notification/domain/entities/client_notification.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/repositories/client_notification_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

class _CountingValidationRepo implements ActiveValidationRepository {
  int markCalls = 0;

  @override
  Future<Result<void>> markMerchantBleConnected({
    required String merchantId,
    required String clientUid,
  }) async {
    markCalls++;
    return const Right(null);
  }

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
  Future<Result<void>> markOpened({
    required String merchantId,
    required String clientUid,
  }) =>
      throw UnimplementedError();

  @override
  Stream<ActiveValidationRequest?> watchClientSession({
    required String merchantId,
    required String clientUid,
  }) =>
      Stream<ActiveValidationRequest?>.value(null);

  @override
  Future<Result<ActiveValidationRequest?>> getClientSession({
    required String merchantId,
    required String clientUid,
  }) async =>
      const Right(null);

  @override
  Stream<List<ActiveValidationRequest>> watchMerchantQueue(String merchantId) =>
      Stream<List<ActiveValidationRequest>>.value(const []);
}

class _NoopLoyaltyRepo implements ClientLoyaltyRepository {
  @override
  Future<ClientMerchantLoyaltyProgress> readProgress(
    String merchantId,
    String clientUid,
  ) async =>
      const ClientMerchantLoyaltyProgress(
        validatedPassages: 0,
        cumulativeSpendEuros: 0,
      );

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> applyPassageDeltas({
    required String merchantId,
    required String clientUid,
    int validatedPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
    LoyaltyProgramConfig? enrollProgram,
    ActiveValidationCompletion? completeActiveValidation,
    bool enforcePassageCooldown = true,
  }) async =>
      Right(
        ClientMerchantLoyaltyProgress(
          validatedPassages: 1,
          cumulativeSpendEuros: 0,
          isFirstVisit: false,
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoopNotificationRepo implements ClientNotificationRepository {
  @override
  Future<Result<ClientNotification>> create(ClientNotification notification) async =>
      Right(notification);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _merchant = Merchant(
  id: 'm-stress',
  ownerUid: 'owner-stress',
  name: 'Stress Café',
  email: 'stress@test.app',
  phone: '+33600000001',
  city: 'Paris',
  status: 'active',
  loyaltyEnabled: true,
  loyaltyProgram: LoyaltyProgramConfig(programEnabled: true),
);

ActiveValidationRequest _bleSession({
  ActiveValidationStatus status = ActiveValidationStatus.awaiting,
  bool merchantConnected = false,
  DateTime? createdAt,
}) =>
    ActiveValidationRequest(
      merchantId: _merchant.id,
      clientUid: 'client-stress',
      clientDisplayName: 'Stress Client',
      status: status,
      programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
      source: ActiveValidationSource.ble,
      clientBleConnectedAt: DateTime(2026, 1, 1),
      merchantBleConnectedAt:
          merchantConnected ? DateTime(2026, 1, 1, 0, 5) : null,
      createdAt: createdAt ?? DateTime.now(),
    );

void main() {
  group('PrepareMerchantPassageValidation stress', () {
    test('50 sequential prepares succeed when merchant BLE already connected',
        () async {
      const prepare = PrepareMerchantPassageValidation();
      final session = _bleSession(merchantConnected: true);

      for (var i = 0; i < 50; i++) {
        final result = await prepare.call(
          merchantId: _merchant.id,
          session: session,
        );
        expect(result.isRight, isTrue, reason: 'iteration $i');
      }
    });

    test('rejects expired awaiting BLE session', () async {
      const prepare = PrepareMerchantPassageValidation();
      final expired = _bleSession(
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      );
      final result = await prepare.call(
        merchantId: _merchant.id,
        session: expired,
      );
      expect(result.isLeft, isTrue);
      expect(
        result.fold((f) => f, (_) => null),
        isA<BlePassageSessionFailure>(),
      );
    });

    test('rejects completed and cancelled sessions', () async {
      const prepare = PrepareMerchantPassageValidation();

      for (final status in [
        ActiveValidationStatus.completed,
        ActiveValidationStatus.cancelled,
      ]) {
        final result = await prepare.call(
          merchantId: _merchant.id,
          session: _bleSession(status: status),
        );
        expect(result.isLeft, isTrue, reason: status.name);
      }
    });

    test('vitrine passes through across 20 calls', () async {
      const prepare = PrepareMerchantPassageValidation();
      final vitrine = ActiveValidationRequest(
        merchantId: _merchant.id,
        clientUid: 'client-stress',
        clientDisplayName: 'Client',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
        source: ActiveValidationSource.vitrine,
      );

      for (var i = 0; i < 20; i++) {
        final result = await prepare.call(
          merchantId: _merchant.id,
          session: vitrine,
        );
        expect(result.isRight, isTrue, reason: 'iteration $i');
      }
    });
  });

  group('ActiveValidationRequest.isExpired stress', () {
    test('fresh awaiting is not expired; 16 min old is expired', () {
      final fresh = _bleSession(createdAt: DateTime.now());
      final stale = _bleSession(
        createdAt: DateTime.now().subtract(const Duration(minutes: 16)),
      );
      expect(fresh.isExpired, isFalse);
      expect(stale.isExpired, isTrue);
    });

    test('completed session is never treated as expired by isExpired', () {
      final completed = _bleSession(
        status: ActiveValidationStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(completed.isExpired, isFalse);
    });
  });

  group('ConfirmActiveValidation BLE guard', () {
    test('blocks validate when BLE session lacks merchant_ble_connected', () async {
      final confirm = ConfirmActiveValidation(
        _NoopLoyaltyRepo(),
        _NoopNotificationRepo(),
      );
      final result = await confirm.call(
        actingOwnerUid: _merchant.ownerUid,
        merchant: _merchant,
        session: _bleSession(merchantConnected: false),
      );
      expect(result.isLeft, isTrue);
      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<BlePassageSessionFailure>());
    });

    test('allows validate when merchant BLE connected', () async {
      final confirm = ConfirmActiveValidation(
        _NoopLoyaltyRepo(),
        _NoopNotificationRepo(),
      );
      final result = await confirm.call(
        actingOwnerUid: _merchant.ownerUid,
        merchant: _merchant,
        session: _bleSession(merchantConnected: true),
      );
      expect(result.isRight, isTrue);
    });

    test('allows vitrine awaiting without merchant_ble_connected', () async {
      final confirm = ConfirmActiveValidation(
        _NoopLoyaltyRepo(),
        _NoopNotificationRepo(),
      );
      final vitrine = ActiveValidationRequest(
        merchantId: _merchant.id,
        clientUid: 'client-stress',
        clientDisplayName: 'Client',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
        source: ActiveValidationSource.vitrine,
      );
      final result = await confirm.call(
        actingOwnerUid: _merchant.ownerUid,
        merchant: _merchant,
        session: vitrine,
      );
      expect(result.isRight, isTrue);
    });
  });
}
