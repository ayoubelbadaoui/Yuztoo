import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/client_notification/application/use_cases/notify_followers_of_promotion.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/entities/client_notification.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/repositories/client_notification_repository.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/domain/repositories/followed_merchants_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/loyalty_pending_client_row.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/entities/promotion.dart';

// ── Fakes (duplicated from rappels tests to keep feature tests self-contained) ─

class _FakeFollowed implements FollowedMerchantsRepository {
  _FakeFollowed({this.followerIds = const []});
  final List<String> followerIds;

  @override
  Future<Result<List<String>>> getFollowerIds(String merchantId) async =>
      Right(followerIds);

  @override
  Future<Result<Unit>> add(String userId, String merchantId) async =>
      const Right(unit);
  @override
  Future<Result<Unit>> remove(String userId, String merchantId) async =>
      const Right(unit);
  @override
  Future<Result<bool>> isFollowing(String userId, String merchantId) async =>
      const Right(false);
  @override
  Future<Result<List<String>>> getFollowedIds(String userId) async =>
      const Right([]);
  @override
  Future<Result<Map<String, int>>> getFollowedHeartLevels(String userId) async =>
      const Right({});
  @override
  Future<Result<Unit>> setHeartLevel(
          String userId, String merchantId, int heartLevel) async =>
      const Right(unit);
  @override
  Future<Result<bool>> getMuteState(String userId, String merchantId) async =>
      const Right(false);
  @override
  Future<Result<Unit>> setMuteState(
          String userId, String merchantId,
          {required bool muted}) async =>
      const Right(unit);
  @override
  Future<Result<Set<String>>> getMutedMerchantIds(String userId) async =>
      const Right(<String>{});

  @override
  Future<Result<Map<String, int>>> getFollowedSortIndexes(String userId) async =>
      const Right({});

  @override
  Stream<List<String>> watchFollowedIds(String userId) =>
      Stream.value(followerIds);

  @override
  Future<Result<Unit>> updateSortOrder(
          String userId, Map<String, int> sortIndexes) async =>
      const Right(unit);
}

class _FakeNotifRepo implements ClientNotificationRepository {
  int createCount = 0;
  @override
  Future<Result<ClientNotification>> create(ClientNotification n) async {
    createCount++;
    return Right(n.copyWith(id: 'nid_$createCount'));
  }

  @override
  Stream<List<ClientNotification>> watchForClient(String clientId) async* {}
  @override
  Future<Result<Unit>> markAsRead(String clientId, String notificationId) async =>
      const Right(unit);
  @override
  Future<Result<Unit>> markAllAsRead(String clientId) async =>
      const Right(unit);
  @override
  Future<Result<Unit>> deleteNotification(
          String clientId, String notificationId) async =>
      const Right(unit);
  @override
  Future<Result<Unit>> deleteAllNotifications(String clientId) async =>
      const Right(unit);
}

class _FakeLoyalty implements ClientLoyaltyRepository {
  _FakeLoyalty({Map<String, String>? segments})
      : segments = segments ?? const {};

  Map<String, String> segments;

  @override
  Future<Map<String, String>> getClientSegments(String merchantId) async =>
      segments;

  @override
  Future<ClientMerchantLoyaltyProgress> readProgress(
    String merchantId,
    String clientUid,
  ) async =>
      const ClientMerchantLoyaltyProgress.empty();

  @override
  Stream<ClientMerchantLoyaltyProgress> watchProgress(
          String merchantId, String clientUid) async* {}

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> applyPassageDeltas({
    required String merchantId,
    required String clientUid,
    int validatedPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
    LoyaltyProgramConfig? enrollProgram,
    ActiveValidationCompletion? completeActiveValidation,
    bool enforcePassageCooldown = true,
  }) async =>
      throw UnimplementedError();

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
}

Promotion _promo({
  required String id,
  ClientType type = ClientType.gratuit,
  List<String> targetSegments = const [],
}) =>
    Promotion(
      id: id,
      merchantId: 'm1',
      title: 'Title',
      subtitle: 'Sub',
      dateFrom: DateTime(2025, 1, 1),
      dateTo: DateTime(2025, 12, 31),
      selectedClientType: type,
      isOnline: true,
      targetSegments: targetSegments,
    );

Future<bool> _ownsM1(String merchantId, String callerUid) async =>
    merchantId == 'm1' && callerUid == 'owner1';

Future<bool> _ownsNever(String merchantId, String callerUid) async => false;

void main() {
  group('NotifyFollowersOfPromotion', () {
    test('returns Left when callerUid is empty', () async {
      final uc = NotifyFollowersOfPromotion(
        followedRepo: _FakeFollowed(followerIds: ['a']),
        notificationRepo: _FakeNotifRepo(),
        loyaltyRepo: _FakeLoyalty(),
        isOwner: _ownsM1,
      );
      final r = await uc.call(
        merchantId: 'm1',
        merchantName: 'Shop',
        promotion: _promo(id: 'p1'),
        callerUid: '',
      );
      expect(r.isLeft, isTrue);
    });

    test('returns Left when ownership fails', () async {
      final notif = _FakeNotifRepo();
      final uc = NotifyFollowersOfPromotion(
        followedRepo: _FakeFollowed(followerIds: ['a', 'b']),
        notificationRepo: notif,
        loyaltyRepo: _FakeLoyalty(),
        isOwner: _ownsNever,
      );
      final r = await uc.call(
        merchantId: 'm1',
        merchantName: 'Shop',
        promotion: _promo(id: 'p1'),
        callerUid: 'owner1',
      );
      expect(r.isLeft, isTrue);
      expect(notif.createCount, 0);
    });

    test('gratuit notifies all followers', () async {
      final notif = _FakeNotifRepo();
      final uc = NotifyFollowersOfPromotion(
        followedRepo: _FakeFollowed(followerIds: ['a', 'b']),
        notificationRepo: notif,
        loyaltyRepo: _FakeLoyalty(),
        isOwner: _ownsM1,
      );
      final r = await uc.call(
        merchantId: 'm1',
        merchantName: 'Shop',
        promotion: _promo(id: 'p1', type: ClientType.gratuit),
        callerUid: 'owner1',
      );
      expect(r.fold((_) => -1, (n) => n), 2);
      expect(notif.createCount, 2);
    });

    test('premium + soutien targets vip and habitue followers only', () async {
      final notif = _FakeNotifRepo();
      final loyalty = _FakeLoyalty(
        segments: {
          'f1': 'vip',
          'f2': 'habitue',
          'f3': 'nouveau',
        },
      );
      final uc = NotifyFollowersOfPromotion(
        followedRepo: _FakeFollowed(followerIds: ['f1', 'f2', 'f3']),
        notificationRepo: notif,
        loyaltyRepo: loyalty,
        isOwner: _ownsM1,
      );
      final r = await uc.call(
        merchantId: 'm1',
        merchantName: 'Shop',
        promotion: _promo(
          id: 'p2',
          type: ClientType.premium,
          targetSegments: const ['soutien'],
        ),
        callerUid: 'owner1',
      );
      expect(r.fold((_) => -1, (n) => n), 2);
      expect(notif.createCount, 2);
    });

    test('empty loyalty map treats followers as nouveau (parity with Rappels)',
        () async {
      final notif = _FakeNotifRepo();
      final loyalty = _FakeLoyalty(segments: {});
      final uc = NotifyFollowersOfPromotion(
        followedRepo: _FakeFollowed(followerIds: ['f1', 'f2']),
        notificationRepo: notif,
        loyaltyRepo: loyalty,
        isOwner: _ownsM1,
      );
      final r = await uc.call(
        merchantId: 'm1',
        merchantName: 'Shop',
        promotion: _promo(
          id: 'p3',
          type: ClientType.premium,
          targetSegments: const ['vip'],
        ),
        callerUid: 'owner1',
      );
      expect(r.fold((_) => -1, (n) => n), 0);
      expect(notif.createCount, 0);
    });

    test('premium + vip targets only vip followers', () async {
      final notif = _FakeNotifRepo();
      final uc = NotifyFollowersOfPromotion(
        followedRepo: _FakeFollowed(followerIds: ['f1', 'f2', 'f3']),
        notificationRepo: notif,
        loyaltyRepo: _FakeLoyalty(
          segments: {
            'f1': 'vip',
            'f2': 'habitue',
            'f3': 'nouveau',
          },
        ),
        isOwner: _ownsM1,
      );
      final r = await uc.call(
        merchantId: 'm1',
        merchantName: 'Shop',
        promotion: _promo(
          id: 'p4',
          type: ClientType.premium,
          targetSegments: const ['vip'],
        ),
        callerUid: 'owner1',
      );
      expect(r.fold((_) => -1, (n) => n), 1);
      expect(notif.createCount, 1);
    });
  });
}
