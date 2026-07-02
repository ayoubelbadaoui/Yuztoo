import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/domain/repositories/followed_merchants_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/client_loyalty_providers.dart'
    show loyaltyProgramsDiffer;
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/confirm_active_validation.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/ensure_client_follows_merchant.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/initiate_ble_passage_session.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/request_active_validation.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/simulate_ble_client_passage.dart';
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

// ─── Fakes ───────────────────────────────────────────────────────────────────

class _SnapshotCaptureRepo implements ActiveValidationRepository {
  final List<LoyaltyProgramConfig> bleSnapshots = [];
  final List<LoyaltyProgramConfig> vitrineSnapshots = [];

  @override
  Future<Result<void>> createBleSession({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
    required String merchantDisplayName,
  }) async {
    bleSnapshots.add(programSnapshot);
    return const Right(null);
  }

  @override
  Future<Result<void>> createForClient({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
  }) async {
    vitrineSnapshots.add(programSnapshot);
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeFollowedRepo implements FollowedMerchantsRepository {
  @override
  Future<Result<bool>> isFollowing(String userId, String merchantId) async =>
      const Right(true);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _CapturingLoyaltyRepo implements ClientLoyaltyRepository {
  LoyaltyProgramConfig? enrollProgram;
  int? visitDelta;
  double? spendDelta;
  ClientMerchantLoyaltyProgress progress =
      const ClientMerchantLoyaltyProgress(
    validatedPassages: 0,
    cumulativeSpendEuros: 0,
  );

  @override
  Future<ClientMerchantLoyaltyProgress> readProgress(
    String merchantId,
    String clientUid,
  ) async =>
      progress;

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> applyPassageDeltas({
    required String merchantId,
    required String clientUid,
    int validatedPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
    LoyaltyProgramConfig? enrollProgram,
    ActiveValidationCompletion? completeActiveValidation,
    bool enforcePassageCooldown = true,
  }) async {
    this.enrollProgram = enrollProgram;
    visitDelta = validatedPassagesDelta;
    spendDelta = cumulativeSpendEurosDelta;
    return Right(
      ClientMerchantLoyaltyProgress(
        validatedPassages: 1,
        cumulativeSpendEuros: spendDelta ?? 0,
        isFirstVisit: false,
      ),
    );
  }

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

const _client = AuthUser(
  id: 'client-fid',
  email: 'client@test.app',
  displayName: 'Alice',
);

Merchant _merchantWith(LoyaltyProgramConfig? program, {bool loyaltyEnabled = true}) {
  return Merchant(
    id: 'm-fid',
    ownerUid: 'owner-fid',
    name: 'Fidélité Test',
    email: 'fid@test.app',
    phone: '+33600000002',
    city: 'Paris',
    status: 'active',
    loyaltyEnabled: loyaltyEnabled,
    loyaltyProgram: program,
  );
}

ActiveValidationRequest _session({
  required LoyaltyProgramConfig snapshot,
  ActiveValidationSource source = ActiveValidationSource.ble,
  bool merchantConnected = true,
}) =>
    ActiveValidationRequest(
      merchantId: 'm-fid',
      clientUid: _client.id,
      clientDisplayName: 'Alice',
      status: ActiveValidationStatus.awaiting,
      programSnapshot: snapshot,
      source: source,
      clientBleConnectedAt: DateTime(2026, 1, 1),
      merchantBleConnectedAt:
          merchantConnected ? DateTime(2026, 1, 1, 0, 1) : null,
    );

void main() {
  group('InitiateBlePassageSession × programme fidélité', () {
    test('rejects when loyaltyEnabled is false', () async {
      final repo = _SnapshotCaptureRepo();
      final useCase = InitiateBlePassageSession(
        repo,
        EnsureClientFollowsMerchant(_FakeFollowedRepo()),
      );
      final result = await useCase.call(
        client: _client,
        merchant: _merchantWith(
          const LoyaltyProgramConfig(programEnabled: true),
          loyaltyEnabled: false,
        ),
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f, (_) => null), isA<MerchantLoyaltyInactiveFailure>());
      expect(repo.bleSnapshots, isEmpty);
    });

    test('rejects when programEnabled is false', () async {
      final repo = _SnapshotCaptureRepo();
      final useCase = InitiateBlePassageSession(
        repo,
        EnsureClientFollowsMerchant(_FakeFollowedRepo()),
      );
      final result = await useCase.call(
        client: _client,
        merchant: _merchantWith(
          const LoyaltyProgramConfig(programEnabled: false),
        ),
      );
      expect(result.isLeft, isTrue);
      expect(repo.bleSnapshots, isEmpty);
    });

    test('manual passageValidation blocks BLE session', () async {
      final repo = _SnapshotCaptureRepo();
      final useCase = InitiateBlePassageSession(
        repo,
        EnsureClientFollowsMerchant(_FakeFollowedRepo()),
      );
      final merchant = _merchantWith(
        const LoyaltyProgramConfig(
          programEnabled: true,
          passageValidation: LoyaltyPassageValidation.manual,
        ),
      );
      final result = await useCase.call(client: _client, merchant: merchant);
      expect(result.isLeft, isTrue);
      expect(repo.bleSnapshots, isEmpty);
    });

    test('30 initiations freeze distinct program snapshots', () async {
      final repo = _SnapshotCaptureRepo();
      final useCase = InitiateBlePassageSession(
        repo,
        EnsureClientFollowsMerchant(_FakeFollowedRepo()),
      );

      for (var i = 0; i < 30; i++) {
        final config = LoyaltyProgramConfig(
          programEnabled: true,
          visitsRequired: 5 + (i % 5),
          triggerType: i.isEven
              ? LoyaltyTriggerType.visitCount
              : LoyaltyTriggerType.purchaseTotal,
          cumulativeSpendRequiredEuros: 50 + i.toDouble(),
        );
        final result = await useCase.call(
          client: _client,
          merchant: _merchantWith(config),
        );
        expect(result.isRight, isTrue, reason: 'iteration $i');
      }

      expect(repo.bleSnapshots, hasLength(30));
      expect(
        repo.bleSnapshots.map((c) => c.visitsRequired).toSet().length,
        greaterThan(1),
      );
    });
  });

  group('RequestActiveValidation × programme fidélité', () {
    test('rejects disabled programme', () async {
      final repo = _SnapshotCaptureRepo();
      final useCase = RequestActiveValidation(repo);
      final result = await useCase.call(
        client: _client,
        merchant: _merchantWith(
          const LoyaltyProgramConfig(programEnabled: false),
        ),
      );
      expect(result.isLeft, isTrue);
      expect(repo.vitrineSnapshots, isEmpty);
    });

    test('manual mode still creates vitrine session', () async {
      final repo = _SnapshotCaptureRepo();
      final useCase = RequestActiveValidation(repo);
      final result = await useCase.call(
        client: _client,
        merchant: _merchantWith(
          const LoyaltyProgramConfig(
            programEnabled: true,
            passageValidation: LoyaltyPassageValidation.manual,
          ),
        ),
      );
      expect(result.isRight, isTrue);
      expect(repo.vitrineSnapshots.single.passageValidation,
          LoyaltyPassageValidation.manual);
    });
  });

  group('SimulateBleClientPassage × programme fidélité', () {
    test('rejects when programme disabled', () async {
      final useCase = SimulateBleClientPassage(_SnapshotCaptureRepo());
      final result = await useCase.call(
        merchant: _merchantWith(
          const LoyaltyProgramConfig(programEnabled: false),
        ),
        clientUid: 'other-client',
        clientDisplayName: 'Bob',
      );
      expect(result.isLeft, isTrue);
    });
  });

  group('ConfirmActiveValidation × programme resolution', () {
    test('session snapshot used when client not enrolled', () async {
      const snapshot = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
      );
      const live = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
        cumulativeSpendRequiredEuros: 100,
      );
      final confirm = ConfirmActiveValidation(
        _CapturingLoyaltyRepo(),
        _NoopNotificationRepo(),
      );
      final result = await confirm.call(
        actingOwnerUid: 'owner-fid',
        merchant: _merchantWith(live),
        session: _session(snapshot: snapshot),
      );
      expect(result.isRight, isTrue);
    });

    test('enrolled program wins over live and snapshot', () async {
      const snapshot = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
        cumulativeSpendRequiredEuros: 200,
      );
      const live = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
        cumulativeSpendRequiredEuros: 50,
      );
      const enrolled = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 10,
      );
      final loyalty = _CapturingLoyaltyRepo()
        ..progress = const ClientMerchantLoyaltyProgress(
          validatedPassages: 2,
          cumulativeSpendEuros: 0,
          enrolledProgram: enrolled,
        );
      final confirm = ConfirmActiveValidation(
        loyalty,
        _NoopNotificationRepo(),
      );
      final result = await confirm.call(
        actingOwnerUid: 'owner-fid',
        merchant: _merchantWith(live),
        session: _session(snapshot: snapshot),
      );
      expect(result.isRight, isTrue);
      expect(loyalty.visitDelta, 1);
      expect(loyalty.spendDelta, 0);
    });

    test('snapshot minimum enforced for unenrolled session', () async {
      const snapshot = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
        minimumPerVisitEnabled: true,
        minimumPerVisitEuros: 50,
      );
      final confirm = ConfirmActiveValidation(
        _CapturingLoyaltyRepo(),
        _NoopNotificationRepo(),
      );
      final result = await confirm.call(
        actingOwnerUid: 'owner-fid',
        merchant: _merchantWith(snapshot),
        session: _session(snapshot: snapshot),
        declaredSpendEuros: 20,
      );
      expect(result.isLeft, isTrue);
      expect(
        result.fold((f) => f.message, (_) => ''),
        contains('minimum'),
      );
    });

    test('rejects when live programme disabled mid-session', () async {
      const snapshot = LoyaltyProgramConfig(programEnabled: true);
      final confirm = ConfirmActiveValidation(
        _CapturingLoyaltyRepo(),
        _NoopNotificationRepo(),
      );
      final result = await confirm.call(
        actingOwnerUid: 'owner-fid',
        merchant: _merchantWith(
          const LoyaltyProgramConfig(programEnabled: false),
        ),
        session: _session(snapshot: snapshot),
      );
      expect(result.isLeft, isTrue);
      expect(
        result.fold((f) => f.message, (_) => ''),
        contains('désactivé'),
      );
    });

    test('40 confirms with spend programme apply spend delta', () async {
      const config = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
        cumulativeSpendRequiredEuros: 100,
      );
      final merchant = _merchantWith(config);
      final loyalty = _CapturingLoyaltyRepo();
      final confirm = ConfirmActiveValidation(
        loyalty,
        _NoopNotificationRepo(),
      );
      final session = _session(snapshot: config);

      for (var i = 0; i < 40; i++) {
        final result = await confirm.call(
          actingOwnerUid: 'owner-fid',
          merchant: merchant,
          session: session,
          declaredSpendEuros: 12.5 + i,
        );
        expect(result.isRight, isTrue, reason: 'iteration $i');
      }
      expect(loyalty.spendDelta, greaterThan(0));
      expect(loyalty.visitDelta, 0);
    });
  });

  group('loyaltyProgramsDiffer', () {
    test('detects minimumPerVisit change', () {
      const a = LoyaltyProgramConfig(
        programEnabled: true,
        minimumPerVisitEnabled: true,
        minimumPerVisitEuros: 50,
      );
      const b = LoyaltyProgramConfig(
        programEnabled: true,
        minimumPerVisitEnabled: false,
      );
      expect(loyaltyProgramsDiffer(a, b), isTrue);
    });

    test('detects programEnabled flip', () {
      const a = LoyaltyProgramConfig(programEnabled: true);
      const b = LoyaltyProgramConfig(programEnabled: false);
      expect(loyaltyProgramsDiffer(a, b), isTrue);
    });
  });
}
