import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/entities/client_notification.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/repositories/client_notification_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/client_loyalty_providers.dart'
    show loyaltyProgramsDiffer;
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
  LoyaltyProgramConfig? lastEnrollProgram;
  ClientMerchantLoyaltyProgress readProgressResult =
      const ClientMerchantLoyaltyProgress.empty();
  bool shouldFail = false;

  void reset() {
    lastMerchantId = null;
    lastClientUid = null;
    lastValidatedDelta = 0;
    lastPendingDelta = 0;
    lastSpendDelta = 0;
    lastEnrollProgram = null;
    readProgressResult = const ClientMerchantLoyaltyProgress.empty();
    shouldFail = false;
  }

  @override
  Future<ClientMerchantLoyaltyProgress> readProgress(
    String merchantId,
    String clientUid,
  ) async =>
      readProgressResult;

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
    LoyaltyProgramConfig? enrollProgram,
  }) async {
    lastMerchantId = merchantId;
    lastClientUid = clientUid;
    lastValidatedDelta = validatedPassagesDelta;
    lastPendingDelta = pendingPassagesDelta;
    lastSpendDelta = cumulativeSpendEurosDelta;
    lastEnrollProgram = enrollProgram;
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

    test('always requests pending passage only (visit program)', () async {
      final program = _visitCountAuto();
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: program),
      );
      expect(result.isRight, isTrue);
      expect(repo.lastPendingDelta, 1);
      expect(repo.lastValidatedDelta, 0);
      expect(repo.lastSpendDelta, 0);
      expect(repo.lastEnrollProgram, program);
    });

    test('always requests pending passage only (spend program)', () async {
      final program = _spendAuto();
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: program),
      );
      expect(result.isRight, isTrue);
      expect(repo.lastPendingDelta, 1);
      expect(repo.lastValidatedDelta, 0);
      expect(repo.lastSpendDelta, 0);
    });

    test('manual validation mode still creates pending only', () async {
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: _visitCountManual()),
      );
      expect(result.isRight, isTrue);
      expect(repo.lastPendingDelta, 1);
      expect(repo.lastValidatedDelta, 0);
    });

    test('repository failure propagates', () async {
      repo.shouldFail = true;
      final uc = RecordLoyaltyPassage(repo);
      final result = await uc.call(
        clientUid: 'c1',
        merchant: _merchant(program: _visitCountAuto()),
      );
      expect(result.isLeft, isTrue);
    });
  });

  group('loyaltyProgramsDiffer (enrolled program)', () {
    test('detects reward kind change', () {
      const a = LoyaltyProgramConfig(
        programEnabled: true,
        rewardKind: LoyaltyRewardKind.purchaseVoucher,
      );
      const b = LoyaltyProgramConfig(
        programEnabled: true,
        rewardKind: LoyaltyRewardKind.discountPercent,
      );
      expect(loyaltyProgramsDiffer(a, b), isTrue);
    });

    test('ignores passage validation mode', () {
      const a = LoyaltyProgramConfig(
        programEnabled: true,
        passageValidation: LoyaltyPassageValidation.automatic,
      );
      const b = LoyaltyProgramConfig(
        programEnabled: true,
        passageValidation: LoyaltyPassageValidation.manual,
      );
      expect(loyaltyProgramsDiffer(a, b), isFalse);
    });
  });

  // ── ValidatePendingLoyaltyPassage tests ──────────────────────────────────

  group('ValidatePendingLoyaltyPassage', () {
    // ── guard validations ────────────────────────────────────────────────────

    test('returns Left when actingOwnerUid is empty', () async {
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        actingOwnerUid: '',
        merchant: _merchant(program: _visitCountManual()),
        clientUid: 'c1',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('autorisée'));
    });

    test('returns Left when clientUid is empty', () async {
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(program: _visitCountManual()),
        clientUid: '',
      );
      expect(result.isLeft, isTrue);
    });

    test('returns Left when actingOwnerUid != merchant.ownerUid', () async {
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
      final result = await uc.call(
        actingOwnerUid: 'intruder',
        merchant: _merchant(program: _visitCountManual()),
        clientUid: 'c1',
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f.message, (_) => ''), contains('propriétaire'));
    });

    test('returns Left when loyalty disabled', () async {
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
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
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
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

    test('visitCount + automatic validation — pending -1, validated +1',
        () async {
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
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
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
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
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
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
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
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
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
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
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
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
      final uc = ValidatePendingLoyaltyPassage(repo, notifRepo);
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
