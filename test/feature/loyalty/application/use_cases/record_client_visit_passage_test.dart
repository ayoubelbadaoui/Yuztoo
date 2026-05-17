import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/record_client_visit_passage.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/loyalty_pending_client_row.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

class _FakeLoyaltyRepo implements ClientLoyaltyRepository {
  int? validatedDelta;

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
    int pendingPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
    LoyaltyProgramConfig? enrollProgram,
  }) async {
    validatedDelta = validatedPassagesDelta;
    return const Right(
      ClientMerchantLoyaltyProgress(
        validatedPassages: 1,
        pendingPassages: 0,
        cumulativeSpendEuros: 0,
        isFirstVisit: true,
      ),
    );
  }

  @override
  Stream<ClientMerchantLoyaltyProgress> watchProgress(
          String merchantId, String clientUid) async* {}

  @override
  Stream<List<LoyaltyPendingClientRow>> watchPendingLoyaltyClients(
          String merchantId) async* {}

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

Merchant _merchant({bool loyaltyEnabled = false}) => Merchant(
      id: 'm1',
      ownerUid: 'm1',
      name: 'Shop',
      email: 'a@b.c',
      phone: '0',
      city: 'Paris',
      loyaltyEnabled: loyaltyEnabled,
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
}
