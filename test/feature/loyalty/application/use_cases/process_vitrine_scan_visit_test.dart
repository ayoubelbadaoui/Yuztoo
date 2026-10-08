import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/process_vitrine_scan_visit.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/request_active_validation.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/active_validation_request.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/active_validation_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

class _FakeActiveValidationRepo implements ActiveValidationRepository {
  int createCalls = 0;
  LoyaltyProgramConfig? lastSnapshot;

  @override
  Future<Result<void>> createForClient({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
  }) async {
    createCalls += 1;
    lastSnapshot = programSnapshot;
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
  Future<Result<ActiveValidationRequest?>> getClientSession({
    required String merchantId,
    required String clientUid,
  }) async =>
      const Right(null);

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
  LoyaltyTriggerType trigger = LoyaltyTriggerType.visitCount,
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
      triggerType: trigger,
    ),
  );
}

const _client = AuthUser(
  id: 'client-1',
  email: 'client@example.com',
  displayName: 'Client',
);

ProcessVitrineScanVisit _useCase(_FakeActiveValidationRepo active) {
  return ProcessVitrineScanVisit(
    requestValidation: RequestActiveValidation(active),
  );
}

void main() {
  group('ProcessVitrineScanVisit', () {
    test('guest scan returns ScanVisitGuest', () async {
      final active = _FakeActiveValidationRepo();
      final result = await _useCase(active).call(
        client: null,
        merchant: _merchant(),
        isFollowing: false,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitGuest>());
      expect(active.createCalls, 0);
    });

    test('follow list not ready returns waiting state, no Firestore writes',
        () async {
      final active = _FakeActiveValidationRepo();
      final result = await _useCase(active).call(
        client: _client,
        merchant: _merchant(),
        isFollowing: false,
        isFollowListReady: false,
      );
      expect(result, isA<ScanVisitFollowListNotReady>());
      expect(active.createCalls, 0);
    });

    test('non-follower returns ScanVisitNotFollowing without writing',
        () async {
      final active = _FakeActiveValidationRepo();
      final result = await _useCase(active).call(
        client: _client,
        merchant: _merchant(),
        isFollowing: false,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitNotFollowing>());
      expect(active.createCalls, 0);
    });

    test('follower with loyalty disabled returns ScanVisitLoyaltyInactive',
        () async {
      final active = _FakeActiveValidationRepo();
      final result = await _useCase(active).call(
        client: _client,
        merchant: _merchant(loyaltyEnabled: false),
        isFollowing: true,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitLoyaltyInactive>());
      expect(active.createCalls, 0);
    });

    test(
        'automatic visit-count mode opens a session for the backend to '
        'confirm instead of writing loyalty_clients from the client', () async {
      final active = _FakeActiveValidationRepo();
      final result = await _useCase(active).call(
        client: _client,
        merchant: _merchant(),
        isFollowing: true,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitAwaitingMerchant>());
      expect(active.createCalls, 1);
    });

    test(
        'automatic amount-based mode opens a session so the merchant can '
        'enter the purchase', () async {
      final active = _FakeActiveValidationRepo();
      final result = await _useCase(active).call(
        client: _client,
        merchant: _merchant(trigger: LoyaltyTriggerType.purchaseTotal),
        isFollowing: true,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitAwaitingMerchant>());
      expect(active.createCalls, 1);
      expect(active.lastSnapshot?.triggerType, LoyaltyTriggerType.purchaseTotal);
    });

    test('follower + manual mode creates active_validation session', () async {
      final active = _FakeActiveValidationRepo();
      final result = await _useCase(active).call(
        client: _client,
        merchant: _merchant(validation: LoyaltyPassageValidation.manual),
        isFollowing: true,
        isFollowListReady: true,
      );
      expect(result, isA<ScanVisitAwaitingMerchant>());
      expect(active.createCalls, 1);
    });
  });
}
