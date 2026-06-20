import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/domain/repositories/followed_merchants_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/accept_ble_passage_as_merchant.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/ensure_client_follows_merchant.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/initiate_ble_passage_session.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/prepare_merchant_passage_validation.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/active_validation_request.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/failures/ble_passage_failure.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/active_validation_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

class _FakeActiveValidationRepo implements ActiveValidationRepository {
  _FakeActiveValidationRepo({
    this.followCreateResult = const Right(null),
    this.markResult = const Right(null),
  });

  Result<void> followCreateResult;
  Result<void> markResult;
  int createBleSessionCalls = 0;
  int markMerchantBleConnectedCalls = 0;

  @override
  Future<Result<void>> createBleSession({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
    required String merchantDisplayName,
  }) async {
    createBleSessionCalls++;
    return followCreateResult;
  }

  @override
  Future<Result<void>> markMerchantBleConnected({
    required String merchantId,
    required String clientUid,
  }) async {
    markMerchantBleConnectedCalls++;
    return markResult;
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

class _FakeFollowedRepo implements FollowedMerchantsRepository {
  _FakeFollowedRepo({required this.following});

  final bool following;

  @override
  Future<Result<bool>> isFollowing(String userId, String merchantId) async =>
      Right(following);

  @override
  Stream<List<String>> watchFollowedIds(String userId) =>
      Stream<List<String>>.value(const []);

  @override
  Future<Result<Unit>> add(String userId, String merchantId) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> remove(String userId, String merchantId) =>
      throw UnimplementedError();

  @override
  Future<Result<List<String>>> getFollowedIds(String userId) =>
      throw UnimplementedError();

  @override
  Future<Result<Map<String, int>>> getFollowedHeartLevels(String userId) =>
      throw UnimplementedError();

  @override
  Future<Result<Map<String, int>>> getFollowedSortIndexes(String userId) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> setHeartLevel(
    String userId,
    String merchantId,
    int heartLevel,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> getMuteState(String userId, String merchantId) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> setMuteState(
    String userId,
    String merchantId, {
    required bool muted,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<Set<String>>> getMutedMerchantIds(String userId) =>
      throw UnimplementedError();

  @override
  Future<Result<List<String>>> getFollowerIds(String merchantId) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit>> updateSortOrder(
    String userId,
    Map<String, int> sortIndexes,
  ) =>
      throw UnimplementedError();
}

const _merchant = Merchant(
  id: 'merchant-1',
  ownerUid: 'owner-1',
  name: 'Café Test',
  email: 'cafe@test.app',
  phone: '+33600000000',
  city: 'Paris',
  status: 'active',
  loyaltyEnabled: true,
  loyaltyProgram: LoyaltyProgramConfig(programEnabled: true),
);

const _client = AuthUser(
  id: 'client-1',
  email: 'client@test.app',
  displayName: 'Alice',
);

ActiveValidationRequest _awaitingBleSession({bool merchantConnected = false}) {
  return ActiveValidationRequest(
    merchantId: _merchant.id,
    clientUid: _client.id,
    clientDisplayName: 'Alice',
    status: ActiveValidationStatus.awaiting,
    programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
    source: ActiveValidationSource.ble,
    clientBleConnectedAt: DateTime(2026, 1, 1),
    merchantBleConnectedAt:
        merchantConnected ? DateTime(2026, 1, 1, 0, 1) : null,
  );
}

void main() {
  group('EnsureClientFollowsMerchant', () {
    test('returns FollowRequiredFailure when not following', () async {
      final useCase = EnsureClientFollowsMerchant(
        _FakeFollowedRepo(following: false),
      );
      final result = await useCase.call(
        clientUid: _client.id,
        merchant: _merchant,
      );
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f, (_) => null), isA<FollowRequiredFailure>());
    });

    test('returns Right when already following', () async {
      final useCase = EnsureClientFollowsMerchant(
        _FakeFollowedRepo(following: true),
      );
      final result = await useCase.call(
        clientUid: _client.id,
        merchant: _merchant,
      );
      expect(result.isRight, isTrue);
    });
  });

  group('InitiateBlePassageSession', () {
    test('creates BLE session when following', () async {
      final repo = _FakeActiveValidationRepo();
      final useCase = InitiateBlePassageSession(
        repo,
        EnsureClientFollowsMerchant(_FakeFollowedRepo(following: true)),
      );
      final result = await useCase.call(client: _client, merchant: _merchant);
      expect(result.isRight, isTrue);
      expect(repo.createBleSessionCalls, 1);
    });

    test('returns FollowRequiredFailure when not following', () async {
      final repo = _FakeActiveValidationRepo();
      final useCase = InitiateBlePassageSession(
        repo,
        EnsureClientFollowsMerchant(_FakeFollowedRepo(following: false)),
      );
      final result = await useCase.call(client: _client, merchant: _merchant);
      expect(result.isLeft, isTrue);
      expect(repo.createBleSessionCalls, 0);
    });
  });

  group('AcceptBlePassageAsMerchant', () {
    test('marks merchant BLE connected when session awaiting', () async {
      final repo = _FakeActiveValidationRepo();
      final useCase = AcceptBlePassageAsMerchant(repo);
      final result = await useCase.call(
        merchantId: _merchant.id,
        clientUid: _client.id,
        existingSession: _awaitingBleSession(),
      );
      expect(result.isRight, isTrue);
      expect(repo.markMerchantBleConnectedCalls, 1);
    });

    test('fails when no session exists', () async {
      final useCase = AcceptBlePassageAsMerchant(_FakeActiveValidationRepo());
      final result = await useCase.call(
        merchantId: _merchant.id,
        clientUid: _client.id,
        existingSession: null,
      );
      expect(result.isLeft, isTrue);
      expect(
        result.fold((f) => f, (_) => null),
        isA<BlePassageSessionFailure>(),
      );
    });

    test('skips mark when merchant already connected', () async {
      final repo = _FakeActiveValidationRepo();
      final useCase = AcceptBlePassageAsMerchant(repo);
      final result = await useCase.call(
        merchantId: _merchant.id,
        clientUid: _client.id,
        existingSession: _awaitingBleSession(merchantConnected: true),
      );
      expect(result.isRight, isTrue);
      expect(repo.markMerchantBleConnectedCalls, 0);
    });
  });

  group('PrepareMerchantPassageValidation', () {
    test('passes vitrine session through without marking BLE', () async {
      final prepare = const PrepareMerchantPassageValidation();
      final vitrine = ActiveValidationRequest(
        merchantId: _merchant.id,
        clientUid: _client.id,
        clientDisplayName: 'Client',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: LoyaltyProgramConfig.initial(),
        source: ActiveValidationSource.vitrine,
      );
      final result = await prepare.call(
        merchantId: _merchant.id,
        session: vitrine,
      );
      expect(result.isRight, isTrue);
      expect(result.fold((_) => null, (s) => s), vitrine);
    });

    test('rejects BLE session without merchant_ble_connected', () async {
      const prepare = PrepareMerchantPassageValidation();
      final result = await prepare.call(
        merchantId: _merchant.id,
        session: _awaitingBleSession(),
      );
      expect(result.isLeft, isTrue);
    });

    test('allows BLE session when merchant already connected', () async {
      const prepare = PrepareMerchantPassageValidation();
      final result = await prepare.call(
        merchantId: _merchant.id,
        session: _awaitingBleSession(merchantConnected: true),
      );
      expect(result.isRight, isTrue);
    });
  });
}
