import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/claim_welcome_bon.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/loyalty_pending_client_row.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ClaimWelcomeBon — use-case tests
//
// These cover the *guard* branches (empty UID, loyalty disabled, no welcome
// gift configured, etc.) and verify the call is forwarded to the repository
// only after every check passes. Repository-level idempotency (a second claim
// returns success unchanged) is tested separately in
// `firestore_client_loyalty_repository_welcome_bon_test.dart` because it
// requires the real Firestore-merge semantics.
// ─────────────────────────────────────────────────────────────────────────────

class _RecordingRepo implements ClientLoyaltyRepository {
  String? lastMerchantId;
  String? lastClientUid;
  int callCount = 0;
  Result<ClientMerchantLoyaltyProgress> nextResult =
      const Right(ClientMerchantLoyaltyProgress.empty());

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> claimWelcomeBon({
    required String merchantId,
    required String clientUid,
  }) async {
    callCount++;
    lastMerchantId = merchantId;
    lastClientUid = clientUid;
    return nextResult;
  }

  // ── Unused stubs ───────────────────────────────────────────────────────────
  @override
  Future<ClientMerchantLoyaltyProgress> readProgress(
    String merchantId,
    String clientUid,
  ) async =>
      const ClientMerchantLoyaltyProgress.empty();

  @override
  Stream<ClientMerchantLoyaltyProgress> watchProgress(
          String merchantId, String clientUid) =>
      const Stream.empty();
  @override
  Stream<List<LoyaltyPendingClientRow>> watchClientsWithRewardAvailable({
    required String merchantId,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool iSpendBased,
  }) =>
      const Stream.empty();
  @override
  Future<Result<ClientMerchantLoyaltyProgress>> applyPassageDeltas({
    required String merchantId,
    required String clientUid,
    int validatedPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
    LoyaltyProgramConfig? enrollProgram,
    ActiveValidationCompletion? completeActiveValidation,
  }) async =>
      throw UnimplementedError();
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
  Future<Map<String, String>> getClientSegments(String merchantId) async => {};
}

Merchant _merchant({
  bool loyaltyEnabled = true,
  bool programEnabled = true,
  String? welcomeGift = 'Croissant offert',
}) {
  return Merchant(
    id: 'm1',
    ownerUid: 'owner1',
    name: 'Boulangerie Test',
    email: 'b@test.com',
    phone: '0600000000',
    city: 'Belfort',
    loyaltyEnabled: loyaltyEnabled,
    welcomeGiftDescription: welcomeGift,
    loyaltyProgram: LoyaltyProgramConfig(
      programEnabled: programEnabled,
    ),
  );
}

void main() {
  late _RecordingRepo repo;
  late ClaimWelcomeBon useCase;

  setUp(() {
    repo = _RecordingRepo();
    useCase = ClaimWelcomeBon(repo);
  });

  test('returns Left when clientUid is empty (does not call repo)', () async {
    final result = await useCase.call(clientUid: '', merchant: _merchant());
    expect(result.isLeft, isTrue);
    expect(repo.callCount, 0);
  });

  test('returns Left when loyaltyEnabled is false', () async {
    final result = await useCase.call(
      clientUid: 'c1',
      merchant: _merchant(loyaltyEnabled: false),
    );
    expect(result.isLeft, isTrue);
    expect(repo.callCount, 0);
  });

  test('returns Left when program is disabled', () async {
    final result = await useCase.call(
      clientUid: 'c1',
      merchant: _merchant(programEnabled: false),
    );
    expect(result.isLeft, isTrue);
    expect(repo.callCount, 0);
  });

  test('returns Left when welcomeGiftDescription is empty', () async {
    final result = await useCase.call(
      clientUid: 'c1',
      merchant: _merchant(welcomeGift: ''),
    );
    expect(result.isLeft, isTrue);
    result.fold(
      (failure) => expect(
        failure.message.toLowerCase(),
        contains('bon de bienvenue'),
      ),
      (_) => fail('expected Left when no welcome gift'),
    );
    expect(repo.callCount, 0);
  });

  test('returns Left when welcomeGiftDescription is null', () async {
    final result = await useCase.call(
      clientUid: 'c1',
      merchant: _merchant(welcomeGift: null),
    );
    expect(result.isLeft, isTrue);
    expect(repo.callCount, 0);
  });

  test('returns Left when welcomeGiftDescription is whitespace-only', () async {
    final result = await useCase.call(
      clientUid: 'c1',
      merchant: _merchant(welcomeGift: '   '),
    );
    expect(result.isLeft, isTrue);
    expect(repo.callCount, 0);
  });

  test('forwards call to repository when all guards pass', () async {
    final result = await useCase.call(
      clientUid: 'c1',
      merchant: _merchant(),
    );
    expect(result.isRight, isTrue);
    expect(repo.callCount, 1);
    expect(repo.lastMerchantId, 'm1');
    expect(repo.lastClientUid, 'c1');
  });

  test('propagates repository failure as Left', () async {
    repo.nextResult = const Left(
      UnexpectedFailure(message: 'Firestore unavailable'),
    );
    final result = await useCase.call(
      clientUid: 'c1',
      merchant: _merchant(),
    );
    expect(result.isLeft, isTrue);
    result.fold(
      (failure) => expect(failure.message, 'Firestore unavailable'),
      (_) => fail('expected Left propagating the repo failure'),
    );
  });
}
