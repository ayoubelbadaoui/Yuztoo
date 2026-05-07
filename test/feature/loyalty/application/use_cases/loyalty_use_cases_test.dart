import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/record_loyalty_passage.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/validate_pending_loyalty_passage.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/loyalty_pending_client_row.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

// ── Fake repository ──────────────────────────────────────────────────────────

class _FakeClientLoyaltyRepository implements ClientLoyaltyRepository {
  // capture last call
  String? lastMerchantId;
  String? lastClientUid;
  int lastValidatedDelta = 0;
  int lastPendingDelta = 0;
  double lastSpendDelta = 0;
  bool shouldFail = false;

  void reset() {
    lastMerchantId = null;
    lastClientUid = null;
    lastValidatedDelta = 0;
    lastPendingDelta = 0;
    lastSpendDelta = 0;
    shouldFail = false;
  }

  @override
  Stream<ClientMerchantLoyaltyProgress> watchProgress(
    String merchantId,
    String clientUid,
  ) =>
      Stream.value(const ClientMerchantLoyaltyProgress.empty());

  @override
  Stream<List<LoyaltyPendingClientRow>> watchPendingLoyaltyClients(
    String merchantId,
  ) =>
      Stream.value([]);

  @override
  Stream<List<LoyaltyPendingClientRow>> watchClientsWithRewardAvailable({
    required String merchantId,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool iSpendBased,
  }) =>
      Stream.value([]);

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> redeemReward({
    required String merchantId,
    required String clientUid,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool isSpendBased,
  }) async =>
      const Right(ClientMerchantLoyaltyProgress.empty());

  @override
  Future<Map<String, String>> getClientSegments(String merchantId) async =>
      {};

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> applyPassageDeltas({
    required String merchantId,
    required String clientUid,
    int validatedPassagesDelta = 0,
    int pendingPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
  }) async {
    lastMerchantId = merchantId;
    lastClientUid = clientUid;
    lastValidatedDelta = validatedPassagesDelta;
    lastPendingDelta = pendingPassagesDelta;
    lastSpendDelta = cumulativeSpendEurosDelta;
    if (shouldFail) {
      return const Left(UnexpectedFailure(message: 'Firestore error'));
    }
    return const Right(
      ClientMerchantLoyaltyProgress(
        validatedPassages: 1,
        pendingPassages: 0,
        cumulativeSpendEuros: 0,
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Merchant _merchant({
  bool loyaltyEnabled = true,
  LoyaltyProgramConfig? program,
}) =>
    Merchant(
      id: 'm1',
      ownerUid: 'owner1',
      name: 'Boutique Test',
      email: 'b@test.com',
      phone: '0600000000',
      city: 'Paris',
      loyaltyEnabled: loyaltyEnabled,
      loyaltyProgram: program,
    );

LoyaltyProgramConfig _visitCountAuto({
  bool minEnabled = false,
  double? minEuros,
}) =>
    LoyaltyProgramConfig(
      programEnabled: true,
      triggerType: LoyaltyTriggerType.visitCount,
      passageValidation: LoyaltyPassageValidation.automatic,
      minimumPerVisitEnabled: minEnabled,
      minimumPerVisitEuros: minEuros ?? 50,
    );

LoyaltyProgramConfig _visitCountManual() => const LoyaltyProgramConfig(
      programEnabled: true,
      triggerType: LoyaltyTriggerType.visitCount,
      passageValidation: LoyaltyPassageValidation.manual,
    );

LoyaltyProgramConfig _spendAuto({
  bool minEnabled = false,
  double? minEuros,
  bool optionalAmount = false,
}) =>
    LoyaltyProgramConfig(
      programEnabled: true,
      triggerType: LoyaltyTriggerType.purchaseTotal,
      passageValidation: LoyaltyPassageValidation.automatic,
      minimumPerVisitEnabled: minEnabled,
      minimumPerVisitEuros: minEuros ?? 50,
      optionalAskClientPurchaseAmount: optionalAmount,
    );

// ── RecordLoyaltyPassage tests ───────────────────────────────────────────────

void main() {
  late _FakeClientLoyaltyRepository repo;

  setUp(() {
    repo = _FakeClientLoyaltyRepository();
  });

  group('RecordLoyaltyPassage', () {
    // ── guard validations ────────────────────────────────────────────────────

    test('returns Left when clientUid is empty', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(clientUid: '', merchant: _merchant());
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''),
          contains('non connecté'));
    });

    test('returns Left when loyaltyEnabled is false', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(loyaltyEnabled: false),
      );
      expect(result.isLeft, isTrue);
    });

    test('returns Left when programEnabled is false', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(
          program: const LoyaltyProgramConfig(programEnabled: false),
        ),
      );
      expect(result.isLeft, isTrue);
    });

    // ── spend-based: amount required ─────────────────────────────────────────

    test('spend trigger — returns Left when amount null', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: _spendAuto()),
        purchaseAmountEuros: null,
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('montant'));
    });

    test('spend trigger — returns Left when amount is zero', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: _spendAuto()),
        purchaseAmountEuros: 0,
      );
      expect(result.isLeft, isTrue);
    });

    test('spend trigger — returns Left when amount below minimum', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(
          program: _spendAuto(minEnabled: true, minEuros: 50),
        ),
        purchaseAmountEuros: 30,
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('minimum'));
    });

    // ── visit-count auto: happy paths ────────────────────────────────────────

    test('visitCount + auto — increments validatedPassages by 1', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: _visitCountAuto()),
      );
      expect(result.isRight, isTrue);
      expect(repo.lastValidatedDelta, 1);
      expect(repo.lastPendingDelta, 0);
      expect(repo.lastSpendDelta, 0);
    });

    test('visitCount + auto — minimum irrelevant when no amount provided',
        () async {
      // visitCount does not check purchase amount at all
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(
          program: _visitCountAuto(minEnabled: true, minEuros: 100),
        ),
      );
      // minimum only applies when purchaseAmountEuros is provided and > 0
      expect(result.isRight, isTrue);
    });

    // ── visit-count manual ───────────────────────────────────────────────────

    test('visitCount + manual — increments pendingPassages by 1', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: _visitCountManual()),
      );
      expect(result.isRight, isTrue);
      expect(repo.lastPendingDelta, 1);
      expect(repo.lastValidatedDelta, 0);
    });

    // ── spend auto: happy path ───────────────────────────────────────────────

    test('spend trigger + auto — adds spend delta', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: _spendAuto()),
        purchaseAmountEuros: 75.0,
      );
      expect(result.isRight, isTrue);
      expect(repo.lastSpendDelta, 75.0);
      expect(repo.lastValidatedDelta, 0);
      expect(repo.lastPendingDelta, 0);
    });

    test('spend trigger + auto — amount above minimum succeeds', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(
          program: _spendAuto(minEnabled: true, minEuros: 50),
        ),
        purchaseAmountEuros: 80.0,
      );
      expect(result.isRight, isTrue);
      expect(repo.lastSpendDelta, 80.0);
    });
  });

  // ── ValidatePendingLoyaltyPassage tests ──────────────────────────────────

  group('ValidatePendingLoyaltyPassage', () {
    // ── guard validations ────────────────────────────────────────────────────

    test('returns Left when actingOwnerUid is empty', () async {
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: '',
        merchant: _merchant(program: _visitCountManual()),
        clientUid: 'c1',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('autorisée'));
    });

    test('returns Left when clientUid is empty', () async {
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _visitCountManual()),
        clientUid: '',
      );
      expect(result.isLeft, isTrue);
    });

    test('returns Left when actingOwnerUid != merchant.ownerUid', () async {
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: 'intruder',
        merchant: _merchant(program: _visitCountManual()),
        clientUid: 'c1',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('propriétaire'));
    });

    test('returns Left when loyalty disabled', () async {
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(
          loyaltyEnabled: false,
          program: _visitCountManual(),
        ),
        clientUid: 'c1',
      );
      expect(result.isLeft, isTrue);
    });

    test('returns Left when program disabled', () async {
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(
          program: const LoyaltyProgramConfig(
            programEnabled: false,
            passageValidation: LoyaltyPassageValidation.manual,
          ),
        ),
        clientUid: 'c1',
      );
      expect(result.isLeft, isTrue);
    });

    test('returns Left when passageValidation is automatic (not manual)',
        () async {
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _visitCountAuto()),
        clientUid: 'c1',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('automatique'));
    });

    // ── visitCount + manual: happy path ─────────────────────────────────────

    test('visitCount + manual — pending -1, validated +1', () async {
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _visitCountManual()),
        clientUid: 'c1',
      );
      expect(result.isRight, isTrue);
      expect(repo.lastPendingDelta, -1);
      expect(repo.lastValidatedDelta, 1);
      expect(repo.lastSpendDelta, 0);
    });

    // ── spend + manual ───────────────────────────────────────────────────────

    test('spend + manual — returns Left when declaredSpendEuros is null',
        () async {
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(
          program: const LoyaltyProgramConfig(
            programEnabled: true,
            triggerType: LoyaltyTriggerType.purchaseTotal,
            passageValidation: LoyaltyPassageValidation.manual,
          ),
        ),
        clientUid: 'c1',
        declaredSpendEuros: null,
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('montant'));
    });

    test('spend + manual — returns Left when spend below minimum', () async {
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(
          program: const LoyaltyProgramConfig(
            programEnabled: true,
            triggerType: LoyaltyTriggerType.purchaseTotal,
            passageValidation: LoyaltyPassageValidation.manual,
            minimumPerVisitEnabled: true,
            minimumPerVisitEuros: 50,
          ),
        ),
        clientUid: 'c1',
        declaredSpendEuros: 20,
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('minimum'));
    });

    test('spend + manual — valid spend: pending -1, spend delta added',
        () async {
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(
          program: const LoyaltyProgramConfig(
            programEnabled: true,
            triggerType: LoyaltyTriggerType.purchaseTotal,
            passageValidation: LoyaltyPassageValidation.manual,
          ),
        ),
        clientUid: 'c1',
        declaredSpendEuros: 60.0,
      );
      expect(result.isRight, isTrue);
      expect(repo.lastPendingDelta, -1);
      expect(repo.lastSpendDelta, 60.0);
      expect(repo.lastValidatedDelta, 0);
    });
  });
}
