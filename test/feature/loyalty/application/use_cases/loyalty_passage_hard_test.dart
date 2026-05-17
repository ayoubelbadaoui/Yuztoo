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

class _TrackingLoyaltyRepo implements ClientLoyaltyRepository {
  int applyCalls = 0;
  int lastValidatedDelta = 0;
  int lastPendingDelta = 0;
  bool failNext = false;
  ClientMerchantLoyaltyProgress nextProgress = const ClientMerchantLoyaltyProgress(
    validatedPassages: 1,
    pendingPassages: 0,
    cumulativeSpendEuros: 0,
  );

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> applyPassageDeltas({
    required String merchantId,
    required String clientUid,
    int validatedPassagesDelta = 0,
    int pendingPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
  }) async {
    applyCalls++;
    lastValidatedDelta = validatedPassagesDelta;
    lastPendingDelta = pendingPassagesDelta;
    if (failNext) {
      return const Left(UnexpectedFailure(message: 'Firestore down'));
    }
    return Right(nextProgress);
  }

  @override
  Stream<ClientMerchantLoyaltyProgress> watchProgress(
          String merchantId, String clientUid) =>
      Stream.value(const ClientMerchantLoyaltyProgress.empty());

  @override
  Stream<List<LoyaltyPendingClientRow>> watchPendingLoyaltyClients(
          String merchantId) =>
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
  Future<Map<String, String>> getClientSegments(String merchantId) async => {};

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> claimWelcomeBon({
    required String merchantId,
    required String clientUid,
  }) async =>
      const Right(ClientMerchantLoyaltyProgress.empty());

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> redeemReward({
    required String merchantId,
    required String clientUid,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool isSpendBased,
  }) async =>
      const Right(ClientMerchantLoyaltyProgress.empty());
}

class _NoopNotifRepo implements ClientNotificationRepository {
  int creates = 0;

  @override
  Future<Result<ClientNotification>> create(ClientNotification n) async {
    creates++;
    return Right(n.copyWith(id: 'n$creates'));
  }

  @override
  Stream<List<ClientNotification>> watchForClient(String clientId) =>
      Stream.value([]);

  @override
  Future<Result<Unit>> markAsRead(String a, String b) async => const Right(unit);

  @override
  Future<Result<Unit>> markAllAsRead(String a) async => const Right(unit);

  @override
  Future<Result<Unit>> deleteNotification(String a, String b) async =>
      const Right(unit);

  @override
  Future<Result<Unit>> deleteAllNotifications(String a) async =>
      const Right(unit);
}

Merchant _merchant({
  bool loyaltyEnabled = true,
  LoyaltyPassageValidation validation = LoyaltyPassageValidation.automatic,
  bool askAmount = false,
  double? minimumPerVisit,
}) {
  return Merchant(
    id: 'm1',
    ownerUid: 'owner1',
    name: 'Shop',
    email: 's@test.com',
    phone: '+33600000000',
    city: 'Paris',
    loyaltyEnabled: loyaltyEnabled,
    loyaltyProgram: LoyaltyProgramConfig(
      programEnabled: true,
      passageValidation: validation,
      triggerType: LoyaltyTriggerType.visitCount,
      visitsRequired: 10,
      optionalAskClientPurchaseAmount: askAmount,
      minimumPerVisitEnabled: minimumPerVisit != null,
      minimumPerVisitEuros: minimumPerVisit,
    ),
  );
}

void main() {
  group('HARD: RecordLoyaltyPassage abuse / edge cases', () {
    late _TrackingLoyaltyRepo repo;
    late _NoopNotifRepo notifs;
    late RecordLoyaltyPassage useCase;

    setUp(() {
      repo = _TrackingLoyaltyRepo();
      notifs = _NoopNotifRepo();
      useCase = RecordLoyaltyPassage(repo, notifs);
    });

    test('empty clientUid → Left, no Firestore call', () async {
      final r = await useCase.call(clientUid: '', merchant: _merchant());
      expect(r, isA<Left<AppFailure, ClientMerchantLoyaltyProgress>>());
      expect(repo.applyCalls, 0);
    });

    test('loyalty disabled → Left', () async {
      final r = await useCase.call(
        clientUid: 'c1',
        merchant: _merchant(loyaltyEnabled: false),
      );
      expect(r, isA<Left<AppFailure, ClientMerchantLoyaltyProgress>>());
      expect(repo.applyCalls, 0);
    });

    test('manual validation → pending +1, not validated', () async {
      await useCase.call(
        clientUid: 'c1',
        merchant: _merchant(validation: LoyaltyPassageValidation.manual),
      );
      expect(repo.lastPendingDelta, 1);
      expect(repo.lastValidatedDelta, 0);
    });

    test('automatic validation → validated +1', () async {
      await useCase.call(
        clientUid: 'c1',
        merchant: _merchant(validation: LoyaltyPassageValidation.automatic),
      );
      expect(repo.lastValidatedDelta, 1);
      expect(repo.lastPendingDelta, 0);
    });

    test('amount required but missing → Left', () async {
      final r = await useCase.call(
        clientUid: 'c1',
        merchant: _merchant(askAmount: true),
      );
      expect(r, isA<Left<AppFailure, ClientMerchantLoyaltyProgress>>());
    });

    test('amount below minimum → Left with message', () async {
      final r = await useCase.call(
        clientUid: 'c1',
        merchant: _merchant(askAmount: true, minimumPerVisit: 20),
        purchaseAmountEuros: 5,
      );
      expect(r, isA<Left<AppFailure, ClientMerchantLoyaltyProgress>>());
      r.fold(
        (f) => expect(f.message, contains('20')),
        (_) => fail('expected Left'),
      );
    });

    test('Firestore failure → Left, no reward notification', () async {
      repo.failNext = true;
      final r = await useCase.call(clientUid: 'c1', merchant: _merchant());
      expect(r, isA<Left<AppFailure, ClientMerchantLoyaltyProgress>>());
      expect(notifs.creates, 0);
    });

    test('threshold crossing writes reward notification once', () async {
      repo.nextProgress = const ClientMerchantLoyaltyProgress(
        validatedPassages: 10,
        pendingPassages: 0,
        cumulativeSpendEuros: 0,
      );
      await useCase.call(clientUid: 'c1', merchant: _merchant());
      expect(notifs.creates, 1);
    });
  });

  group('HARD: ValidatePendingLoyaltyPassage guards', () {
    test('non-owner cannot validate', () async {
      final repo = _TrackingLoyaltyRepo();
      final useCase = ValidatePendingLoyaltyPassage(repo);
      final r = await useCase.call(
        actingOwnerUid: 'hacker',
        merchant: _merchant(validation: LoyaltyPassageValidation.manual),
        clientUid: 'c1',
      );
      expect(r, isA<Left<AppFailure, ClientMerchantLoyaltyProgress>>());
      expect(repo.applyCalls, 0);
    });

    test('automatic merchant cannot use manual validate', () async {
      final repo = _TrackingLoyaltyRepo();
      final useCase = ValidatePendingLoyaltyPassage(repo);
      final r = await useCase.call(
        actingOwnerUid: 'owner1',
        merchant: _merchant(validation: LoyaltyPassageValidation.automatic),
        clientUid: 'c1',
      );
      expect(r, isA<Left<AppFailure, ClientMerchantLoyaltyProgress>>());
    });
  });
}
