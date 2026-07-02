import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/entities/client_notification.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/repositories/client_notification_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/record_client_visit_passage.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/loyalty_pending_client_row.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

class _FakeLoyaltyRepo implements ClientLoyaltyRepository {
  int? validatedDelta;
  LoyaltyProgramConfig? enrolledProgram;

  @override
  @override
  Future<ClientMerchantLoyaltyProgress> readProgress(
    String merchantId,
    String clientUid,
  ) async =>
      const ClientMerchantLoyaltyProgress.empty();

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
    validatedDelta = validatedPassagesDelta;
    enrolledProgram = enrollProgram;
    return const Right(
      ClientMerchantLoyaltyProgress(
        validatedPassages: 1,
        cumulativeSpendEuros: 0,
        isFirstVisit: true,
      ),
    );
  }

  @override
  Stream<ClientMerchantLoyaltyProgress> watchProgress(
          String merchantId, String clientUid) async* {}

  @override
  Stream<List<LoyaltyPendingClientRow>> watchClientsWithRewardAvailable({
    required String merchantId,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool iSpendBased,
  }) async* {}

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> redeemReward({
    required String merchantId,
    required String clientUid,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool isSpendBased,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> claimWelcomeBon({
    required String merchantId,
    required String clientUid,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, String>> getClientSegments(String merchantId) async =>
      const {};
}

class _FakeNotificationRepo implements ClientNotificationRepository {
  final List<ClientNotification> created = [];

  @override
  Future<Result<ClientNotification>> create(
    ClientNotification notification,
  ) async {
    created.add(notification);
    return Right(notification);
  }

  @override
  Stream<List<ClientNotification>> watchForClient(String clientId) =>
      const Stream.empty();

  @override
  Future<Result<Unit>> markAsRead(String clientId, String notificationId) async =>
      const Right(unit);

  @override
  Future<Result<Unit>> markAllAsRead(String clientId) async =>
      const Right(unit);

  @override
  Future<Result<Unit>> deleteNotification(
    String clientId,
    String notificationId,
  ) async =>
      const Right(unit);

  @override
  Future<Result<Unit>> deleteAllNotifications(String clientId) async =>
      const Right(unit);
}

Merchant _merchant({
  bool loyaltyEnabled = false,
  LoyaltyProgramConfig? loyaltyProgram,
}) =>
    Merchant(
      id: 'm1',
      ownerUid: 'm1',
      name: 'Shop',
      email: 'a@b.c',
      phone: '0',
      city: 'Paris',
      loyaltyEnabled: loyaltyEnabled,
      loyaltyProgram: loyaltyProgram,
    );

void main() {
  test('records +1 validated passage without loyalty program', () async {
    final repo = _FakeLoyaltyRepo();
    final uc = RecordClientVisitPassage(repo);
    final result = await uc.call(
      clientUid: 'client-1',
      merchant: _merchant(),
    );
    expect(result.isRight, isTrue);
    expect(repo.validatedDelta, 1);
  });

  test(
      'enrolls program and writes a passage-validated notification when '
      'loyalty is active (automatic mode)', () async {
    final repo = _FakeLoyaltyRepo();
    final notifRepo = _FakeNotificationRepo();
    final uc = RecordClientVisitPassage(repo, notifRepo);

    final result = await uc.call(
      clientUid: 'client-1',
      merchant: _merchant(
        loyaltyEnabled: true,
        loyaltyProgram: const LoyaltyProgramConfig(
          programEnabled: true,
          triggerType: LoyaltyTriggerType.visitCount,
          passageValidation: LoyaltyPassageValidation.automatic,
          visitsRequired: 10,
        ),
      ),
    );

    expect(result.isRight, isTrue);
    expect(repo.validatedDelta, 1);
    expect(repo.enrolledProgram, isNotNull,
        reason: 'program must be enrolled so the loyalty card appears');
    expect(notifRepo.created, hasLength(1));
    expect(notifRepo.created.single.clientId, 'client-1');
    expect(notifRepo.created.single.merchantId, 'm1');
    expect(notifRepo.created.single.type, ClientNotificationType.loyalty);
  });

  test('writes no notification when loyalty is inactive', () async {
    final repo = _FakeLoyaltyRepo();
    final notifRepo = _FakeNotificationRepo();
    final uc = RecordClientVisitPassage(repo, notifRepo);

    final result = await uc.call(
      clientUid: 'client-1',
      merchant: _merchant(),
    );

    expect(result.isRight, isTrue);
    expect(notifRepo.created, isEmpty);
  });
}
