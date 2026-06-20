// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/redeem_loyalty_reward.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/loyalty_pending_client_row.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

// ── Fake repository ──────────────────────────────────────────────────────────

class _FakeRepo implements ClientLoyaltyRepository {
  // Captured call args
  String? capturedMerchantId;
  String? capturedClientUid;
  int? capturedVisitsRequired;
  double? capturedSpendRequired;
  bool? capturedIsSpendBased;
  bool shouldFail = false;
  bool redeemShouldFail = false;

  Result<ClientMerchantLoyaltyProgress> redeemResult =
      const Right(ClientMerchantLoyaltyProgress.empty());

  void reset() {
    capturedMerchantId = null;
    capturedClientUid = null;
    capturedVisitsRequired = null;
    capturedSpendRequired = null;
    capturedIsSpendBased = null;
    shouldFail = false;
    redeemShouldFail = false;
    redeemResult = const Right(ClientMerchantLoyaltyProgress.empty());
  }

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> redeemReward({
    required String merchantId,
    required String clientUid,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool isSpendBased,
  }) async {
    capturedMerchantId = merchantId;
    capturedClientUid = clientUid;
    capturedVisitsRequired = visitsRequired;
    capturedSpendRequired = spendRequiredEuros;
    capturedIsSpendBased = isSpendBased;
    if (redeemShouldFail) {
      return const Left(UnexpectedFailure(message: 'Firestore error'));
    }
    return redeemResult;
  }

  @override
  Future<ClientMerchantLoyaltyProgress> readProgress(
    String merchantId,
    String clientUid,
  ) async =>
      const ClientMerchantLoyaltyProgress.empty();

  @override
  Stream<ClientMerchantLoyaltyProgress> watchProgress(
          String merchantId, String clientUid) =>
      Stream.value(const ClientMerchantLoyaltyProgress.empty());

  @override
  Stream<List<LoyaltyPendingClientRow>> watchClientsWithRewardAvailable({
    required String merchantId,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool iSpendBased,
  }) =>
      Stream.value([]);

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
      const Right(ClientMerchantLoyaltyProgress.empty());

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> claimWelcomeBon({
    required String merchantId,
    required String clientUid,
  }) async =>
      const Right(ClientMerchantLoyaltyProgress.empty());

  @override
  Future<Map<String, String>> getClientSegments(String merchantId) async => {};
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Merchant _merchant({
  String ownerUid = 'owner1',
  bool loyaltyEnabled = true,
  LoyaltyProgramConfig? program,
}) =>
    Merchant(
      id: 'm1',
      ownerUid: ownerUid,
      name: 'Boutique Test',
      email: 'b@test.com',
      phone: '0600000000',
      city: 'Paris',
      loyaltyEnabled: loyaltyEnabled,
      loyaltyProgram: program,
    );

const _visitProgram = LoyaltyProgramConfig(
  programEnabled: true,
  triggerType: LoyaltyTriggerType.visitCount,
  visitsRequired: 10,
);

const _spendProgram = LoyaltyProgramConfig(
  programEnabled: true,
  triggerType: LoyaltyTriggerType.purchaseTotal,
  cumulativeSpendRequiredEuros: 150,
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _FakeRepo repo;
  late RedeemLoyaltyReward useCase;

  setUp(() {
    repo = _FakeRepo();
    useCase = RedeemLoyaltyReward(repo);
  });

  // ── Guard: empty UIDs ──────────────────────────────────────────────────────

  group('RedeemLoyaltyReward — UID guards', () {
    test('empty actingOwnerUid → Left "non autorisée"', () async {
      final result = await useCase.call(
        actingOwnerUid: '',
        merchant: _merchant(program: _visitProgram),
        clientUid: 'client1',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''),
          contains('non autorisée'));
    });

    test('empty clientUid → Left "non autorisée"', () async {
      final result = await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _visitProgram),
        clientUid: '',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''),
          contains('non autorisée'));
    });

    test('both empty → Left', () async {
      final result = await useCase.call(
        actingOwnerUid: '',
        merchant: _merchant(program: _visitProgram),
        clientUid: '',
      );
      expect(result.isLeft, isTrue);
    });
  });

  // ── Guard: ownership ──────────────────────────────────────────────────────

  group('RedeemLoyaltyReward — ownership guard', () {
    test('actingOwnerUid != merchant.ownerUid → Left "propriétaire"', () async {
      final result = await useCase.call(
        actingOwnerUid: 'intruder',
        merchant: _merchant(ownerUid: 'owner1', program: _visitProgram),
        clientUid: 'client1',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''),
          contains('propriétaire'));
    });

    test('correct owner passes ownership check', () async {
      final result = await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(ownerUid: 'owner1', program: _visitProgram),
        clientUid: 'client1',
      );
      expect(result.isRight, isTrue);
    });
  });

  // ── Guard: loyalty enabled ────────────────────────────────────────────────

  group('RedeemLoyaltyReward — loyalty enabled guard', () {
    test('loyaltyEnabled=false → Left "inactive"', () async {
      final result = await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(loyaltyEnabled: false, program: _visitProgram),
        clientUid: 'client1',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''),
          contains('inactive'));
    });

    test('loyaltyEnabled=true with program passes', () async {
      final result = await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(loyaltyEnabled: true, program: _visitProgram),
        clientUid: 'client1',
      );
      expect(result.isRight, isTrue);
    });
  });

  // ── Guard: program enabled ────────────────────────────────────────────────

  group('RedeemLoyaltyReward — program enabled guard', () {
    test('programEnabled=false → Left "désactivé"', () async {
      final result = await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(
          program: const LoyaltyProgramConfig(programEnabled: false),
        ),
        clientUid: 'client1',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''),
          contains('désactivé'));
    });

    test('no loyaltyProgram set — fallback with loyaltyEnabled=true → passes',
        () async {
      // merchant.loyaltyProgram == null → fallback is created with
      // programEnabled = loyaltyEnabled (true) → should proceed.
      final result = await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(loyaltyEnabled: true, program: null),
        clientUid: 'client1',
      );
      expect(result.isRight, isTrue);
    });
  });

  // ── visitCount program: isSpendBased = false ──────────────────────────────

  group('RedeemLoyaltyReward — visitCount trigger', () {
    test('passes isSpendBased=false to repository', () async {
      await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _visitProgram),
        clientUid: 'client1',
      );
      expect(repo.capturedIsSpendBased, isFalse);
    });

    test('passes correct visitsRequired from config', () async {
      const program = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 7,
      );
      await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: program),
        clientUid: 'client1',
      );
      expect(repo.capturedVisitsRequired, 7);
    });

    test('merchantId and clientUid forwarded correctly', () async {
      await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _visitProgram),
        clientUid: 'clientABC',
      );
      expect(repo.capturedMerchantId, 'm1');
      expect(repo.capturedClientUid, 'clientABC');
    });

    test('repository failure is propagated as-is', () async {
      repo.redeemShouldFail = true;
      final result = await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _visitProgram),
        clientUid: 'client1',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''),
          contains('Firestore error'));
    });
  });

  // ── purchaseTotal program: isSpendBased = true ────────────────────────────

  group('RedeemLoyaltyReward — purchaseTotal trigger', () {
    test('passes isSpendBased=true to repository', () async {
      await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _spendProgram),
        clientUid: 'client1',
      );
      expect(repo.capturedIsSpendBased, isTrue);
    });

    test('passes correct spendRequired from config', () async {
      await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _spendProgram),
        clientUid: 'client1',
      );
      expect(repo.capturedSpendRequired, 150.0);
    });

    test('returns repository success result', () async {
      repo.redeemResult = const Right(
        ClientMerchantLoyaltyProgress(
          validatedPassages: 0,
          cumulativeSpendEuros: 0,
        ),
      );
      final result = await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _spendProgram),
        clientUid: 'client1',
      );
      expect(result.isRight, isTrue);
    });
  });

  // ── loyaltyPoints reward kind (also spend-based via clientMustEnterPurchaseAmount)

  group('RedeemLoyaltyReward — loyaltyPoints reward kind', () {
    test('loyaltyPoints reward kind: triggerType=visitCount → isSpendBased=false',
        () async {
      const program = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.loyaltyPoints,
      );
      await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: program),
        clientUid: 'client1',
      );
      // isSpendBased is determined by triggerType alone in RedeemLoyaltyReward,
      // not by rewardKind.
      expect(repo.capturedIsSpendBased, isFalse);
    });
  });

  // ── Edge: merchant redeems for themselves (dual-profile: G6) ─────────────

  group('RedeemLoyaltyReward — G6: merchant redeeming for themselves', () {
    test('merchant owner can redeem reward for their OWN client account', () async {
      // Same UID as owner — this is the dual-profile scenario.
      // The use case itself does NOT block this (it only checks merchant ownership,
      // not whether clientUid == actingOwnerUid). Firestore rules govern it.
      final result = await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(ownerUid: 'owner1', program: _visitProgram),
        clientUid: 'owner1', // same UID as owner!
      );
      // Use case passes — Firestore rules are the last gatekeeper.
      expect(result.isRight, isTrue);
      expect(repo.capturedClientUid, 'owner1');
    });
  });

  // ── Custom visitsRequired edge cases ──────────────────────────────────────

  group('RedeemLoyaltyReward — visitsRequired edge cases', () {
    test('visitsRequired=1 (minimal) passed through', () async {
      const program = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 1,
      );
      await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: program),
        clientUid: 'client1',
      );
      expect(repo.capturedVisitsRequired, 1);
    });

    test('visitsRequired=100 (large) passed through', () async {
      const program = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 100,
      );
      await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: program),
        clientUid: 'client1',
      );
      expect(repo.capturedVisitsRequired, 100);
    });

    test('cumulativeSpendRequiredEuros=0 (edge) passed through', () async {
      const program = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
        cumulativeSpendRequiredEuros: 0,
      );
      await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: program),
        clientUid: 'client1',
      );
      expect(repo.capturedSpendRequired, 0.0);
    });
  });
}
