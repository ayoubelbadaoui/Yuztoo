import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/entities/client_notification.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/repositories/client_notification_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/record_loyalty_passage.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/validate_pending_loyalty_passage.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/loyalty_pending_client_row.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

// ── Fake repositories ────────────────────────────────────────────────────────

class _FakeClientNotificationRepository implements ClientNotificationRepository {
  @override
  Stream<List<ClientNotification>> watchForClient(String clientId) =>
      Stream.value([]);

  @override
  Future<Result<ClientNotification>> create(ClientNotification notification) async =>
      Right(notification.copyWith(id: 'fake-id'));

  @override
  Future<Result<Unit>> markAsRead(String clientId, String notificationId) async =>
      const Right(unit);

  @override
  Future<Result<Unit>> markAllAsRead(String clientId) async => const Right(unit);

  @override
  Future<Result<Unit>> deleteNotification(String clientId, String notificationId) async =>
      const Right(unit);

  @override
  Future<Result<Unit>> deleteAllNotifications(String clientId) async =>
      const Right(unit);
}

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
  Future<Result<ClientMerchantLoyaltyProgress>> claimWelcomeBon({
    required String merchantId,
    required String clientUid,
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
  late _FakeClientNotificationRepository notifRepo;

  setUp(() {
    repo = _FakeClientLoyaltyRepository();
    notifRepo = _FakeClientNotificationRepository();
  });

  group('RecordLoyaltyPassage', () {
    // ── guard validations ────────────────────────────────────────────────────

    test('returns Left when clientUid is empty', () async {
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(clientUid: '', merchant: _merchant());
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''),
          contains('non connecté'));
    });

    test('returns Left when loyaltyEnabled is false', () async {
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(loyaltyEnabled: false),
      );
      expect(result.isLeft, isTrue);
    });

    test('returns Left when programEnabled is false', () async {
      final uc = RecordLoyaltyPassage(repo, notifRepo);
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
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: _spendAuto()),
        purchaseAmountEuros: null,
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('montant'));
    });

    test('spend trigger — returns Left when amount is zero', () async {
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: _spendAuto()),
        purchaseAmountEuros: 0,
      );
      expect(result.isLeft, isTrue);
    });

    test('spend trigger — returns Left when amount below minimum', () async {
      final uc = RecordLoyaltyPassage(repo, notifRepo);
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
      final uc = RecordLoyaltyPassage(repo, notifRepo);
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
      final uc = RecordLoyaltyPassage(repo, notifRepo);
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
      final uc = RecordLoyaltyPassage(repo, notifRepo);
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
      final uc = RecordLoyaltyPassage(repo, notifRepo);
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
      final uc = RecordLoyaltyPassage(repo, notifRepo);
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

    // ── visitCount + optionalAmount edge cases ───────────────────────────────

    test('visitCount + optionalAmount=true + no amount → Left (amount required)',
        () async {
      // effectiveAskClientPurchaseAmount = true → amount IS required even for
      // visitCount programs when optionalAskClientPurchaseAmount is true.
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(
          program: LoyaltyProgramConfig(
            programEnabled: true,
            triggerType: LoyaltyTriggerType.visitCount,
            passageValidation: LoyaltyPassageValidation.automatic,
            optionalAskClientPurchaseAmount: true,
          ),
        ),
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('montant'));
    });

    test(
        'visitCount + optionalAmount=true + amount provided → '
        'validated +1, spend NOT stored (visit-count program)',
        () async {
      // Key insight: even though the merchant collected the amount for display
      // purposes, visitCount programs only track visit counts, NOT spend.
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(
          program: LoyaltyProgramConfig(
            programEnabled: true,
            triggerType: LoyaltyTriggerType.visitCount,
            passageValidation: LoyaltyPassageValidation.automatic,
            optionalAskClientPurchaseAmount: true,
          ),
        ),
        purchaseAmountEuros: 50.0,
      );
      expect(result.isRight, isTrue);
      expect(repo.lastValidatedDelta, 1); // visit counted
      expect(repo.lastSpendDelta, 0); // spend NOT stored for visitCount
      expect(repo.lastPendingDelta, 0);
    });

    test(
        'visitCount + optionalAmount=true + minimum enabled + '
        'amount below minimum → Left',
        () async {
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(
          program: LoyaltyProgramConfig(
            programEnabled: true,
            triggerType: LoyaltyTriggerType.visitCount,
            passageValidation: LoyaltyPassageValidation.automatic,
            optionalAskClientPurchaseAmount: true,
            minimumPerVisitEnabled: true,
            minimumPerVisitEuros: 30,
          ),
        ),
        purchaseAmountEuros: 20.0,
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('minimum'));
    });

    test(
        'visitCount + optionalAmount=true + minimum disabled + '
        'amount below old minimum → succeeds (minimum ignored)',
        () async {
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(
          program: LoyaltyProgramConfig(
            programEnabled: true,
            triggerType: LoyaltyTriggerType.visitCount,
            passageValidation: LoyaltyPassageValidation.automatic,
            optionalAskClientPurchaseAmount: true,
            minimumPerVisitEnabled: false, // disabled!
            minimumPerVisitEuros: 100,
          ),
        ),
        purchaseAmountEuros: 5.0,
      );
      expect(result.isRight, isTrue);
      expect(repo.lastValidatedDelta, 1);
    });

    // ── spend trigger: boundary conditions ──────────────────────────────────

    test('spend trigger + minimum enabled + amount exactly at minimum → succeeds',
        () async {
      // Edge: purchaseAmountEuros == minimumPerVisitEuros is NOT below minimum
      // The check is: purchaseAmountEuros < minimumPerVisitEuros → fail.
      // At exactly the minimum → passes.
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(
          program: _spendAuto(minEnabled: true, minEuros: 50),
        ),
        purchaseAmountEuros: 50.0, // exactly at minimum
      );
      expect(result.isRight, isTrue);
      expect(repo.lastSpendDelta, 50.0);
    });

    test('spend trigger + minimum enabled + amount 0.01 below minimum → Left',
        () async {
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(
          program: _spendAuto(minEnabled: true, minEuros: 50),
        ),
        purchaseAmountEuros: 49.99, // just below minimum
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('minimum'));
    });

    test('repository failure propagates for visitCount programs', () async {
      repo.shouldFail = true;
      final uc = RecordLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: _visitCountAuto()),
      );
      expect(result.isLeft, isTrue);
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

    // ── Boundary conditions ──────────────────────────────────────────────────

    test('spend + manual + amount exactly at minimum → succeeds (boundary)', () async {
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
        declaredSpendEuros: 50.0, // exactly at minimum
      );
      // spend >= minimum (50 >= 50) → NOT below → should pass
      expect(result.isRight, isTrue);
      expect(repo.lastSpendDelta, 50.0);
      expect(repo.lastPendingDelta, -1);
    });

    test('spend + manual + amount 0.01 below minimum → Left', () async {
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
        declaredSpendEuros: 49.99, // just below minimum
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('minimum'));
    });

    test('visitCount + manual: passing amount does not change deltas', () async {
      // Even if caller passes declaredSpendEuros for a visitCount program,
      // the use case routes to the visitCount path (pending→validated).
      final uc = ValidatePendingLoyaltyPassage(repo);
      final result = await uc.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _visitCountManual()),
        clientUid: 'c1',
        declaredSpendEuros: 999.0, // irrelevant for visitCount
      );
      expect(result.isRight, isTrue);
      expect(repo.lastPendingDelta, -1);
      expect(repo.lastValidatedDelta, 1);
      expect(repo.lastSpendDelta, 0); // spend NOT used for visitCount
    });
  });
}
