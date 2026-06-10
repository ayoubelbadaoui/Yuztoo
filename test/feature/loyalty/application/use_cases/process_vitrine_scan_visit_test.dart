import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/process_vitrine_scan_visit.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/record_client_visit_passage.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/request_active_validation.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/active_validation_request.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/loyalty_pending_client_row.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/failures/passage_cooldown_failure.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/active_validation_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

class _FakeLoyaltyRepo implements ClientLoyaltyRepository {
  _FakeLoyaltyRepo({this.failure});
  final dynamic failure;
  int applyCalls = 0;

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
  }) async {
    applyCalls += 1;
    if (failure != null) {
      return Left(failure);
    }
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
    String merchantId,
    String clientUid,
  ) async* {}

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

class _FakeActiveValidationRepo implements ActiveValidationRepository {
  int createCalls = 0;

  @override
  Future<Result<void>> createForClient({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
  }) async {
    createCalls += 1;
    return const Right(null);
  }

  @override
  Future<Result<void>> createBleSession({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
    required String merchantDisplayName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> markMerchantBleConnected({
    required String merchantId,
    required String clientUid,
  }) async =>
      throw UnimplementedError();

  @override
  Stream<ActiveValidationRequest?> watchClientSession({
    required String merchantId,
    required String clientUid,
  }) async* {}

  @override
  Stream<List<ActiveValidationRequest>> watchMerchantQueue(String merchantId) async* {}

  @override
  Future<Result<void>> markOpened({
    required String merchantId,
    required String clientUid,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> completeSession({
    required String merchantId,
    required String clientUid,
    int? resultValidatedDelta,
    double? resultSpendDelta,
    double? declaredSpendEuros,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> cancelByMerchant({
    required String merchantId,
    required String clientUid,
    String? reason,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> cancelByClient({
    required String merchantId,
    required String clientUid,
  }) async =>
      throw UnimplementedError();
}

Merchant _merchant({
  bool loyaltyEnabled = true,
  LoyaltyPassageValidation validation = LoyaltyPassageValidation.automatic,
}) {
  return Merchant(
    id: 'merchant-1',
    ownerUid: 'owner-1',
    name: 'Shop',
    email: 'a@b.c',
    phone: '0',
    city: 'Paris',
    loyaltyEnabled: loyaltyEnabled,
    loyaltyProgram: LoyaltyProgramConfig.initial().copyWith(
      programEnabled: loyaltyEnabled,
      passageValidation: validation,
    ),
  );
}

const _client = AuthUser(
  id: 'client-1',
  email: 'client@example.com',
  displayName: 'Client',
);

ProcessVitrineScanVisit _useCase({
  _FakeLoyaltyRepo? loyaltyRepo,
  _FakeActiveValidationRepo? activeRepo,
}) {
  final loyalty = loyaltyRepo ?? _FakeLoyaltyRepo();
  final active = activeRepo ?? _FakeActiveValidationRepo();
  return ProcessVitrineScanVisit(
    recordVisit: RecordClientVisitPassage(loyalty),
    requestValidation: RequestActiveValidation(active),
  );
}

void main() {
  group('ProcessVitrineScanVisit', () {
    test('guest scan returns ScanVisitGuest', () async {
      final result = await _useCase().call(
        client: null,
        merchant: _merchant(),
        isFollowing: false,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitGuest>());
    });

    test('follow list not ready returns waiting state, no Firestore writes',
        () async {
      final loyalty = _FakeLoyaltyRepo();
      final active = _FakeActiveValidationRepo();
      final result = await _useCase(loyaltyRepo: loyalty, activeRepo: active)
          .call(
        client: _client,
        merchant: _merchant(),
        isFollowing: false,
        isFollowListReady: false,
      );
      expect(result, isA<ScanVisitFollowListNotReady>());
      expect(loyalty.applyCalls, 0);
      expect(active.createCalls, 0);
    });

    test('non-follower returns ScanVisitNotFollowing without writing',
        () async {
      final loyalty = _FakeLoyaltyRepo();
      final active = _FakeActiveValidationRepo();
      final result = await _useCase(loyaltyRepo: loyalty, activeRepo: active)
          .call(
        client: _client,
        merchant: _merchant(),
        isFollowing: false,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitNotFollowing>());
      expect(loyalty.applyCalls, 0);
      expect(active.createCalls, 0);
    });

    test('follower with loyalty disabled returns ScanVisitLoyaltyInactive',
        () async {
      final loyalty = _FakeLoyaltyRepo();
      final result = await _useCase(loyaltyRepo: loyalty).call(
        client: _client,
        merchant: _merchant(loyaltyEnabled: false),
        isFollowing: true,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitLoyaltyInactive>());
      expect(loyalty.applyCalls, 0);
    });

    test('follower + automatic mode records visit and returns progress',
        () async {
      final loyalty = _FakeLoyaltyRepo();
      final result = await _useCase(loyaltyRepo: loyalty).call(
        client: _client,
        merchant: _merchant(),
        isFollowing: true,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitVisitRecorded>());
      expect((result as ScanVisitVisitRecorded).progress.validatedPassages, 1);
      expect(loyalty.applyCalls, 1);
    });

    test('follower + manual mode creates active_validation session', () async {
      final active = _FakeActiveValidationRepo();
      final result = await _useCase(activeRepo: active).call(
        client: _client,
        merchant: _merchant(validation: LoyaltyPassageValidation.manual),
        isFollowing: true,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitAwaitingMerchant>());
      expect(active.createCalls, 1);
    });

    test('cooldown failure surfaces as ScanVisitCooldownBlocked', () async {
      final loyalty = _FakeLoyaltyRepo(failure: const PassageCooldownFailure());
      final result = await _useCase(loyaltyRepo: loyalty).call(
        client: _client,
        merchant: _merchant(),
        isFollowing: true,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitCooldownBlocked>());
      final blocked = result as ScanVisitCooldownBlocked;
      expect(blocked.userMessage, contains('Patientez 1 heure'));
    });
  });
}
