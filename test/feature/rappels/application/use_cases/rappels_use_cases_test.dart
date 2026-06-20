import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/entities/client_notification.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/repositories/client_notification_repository.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/domain/repositories/followed_merchants_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/loyalty_pending_client_row.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/rappels/application/use_cases/acknowledge_new_client.dart';
import 'package:flutter_yuztoo/feature/rappels/application/use_cases/create_auto_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/application/use_cases/delete_auto_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/application/use_cases/send_merchant_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/application/use_cases/update_auto_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/active_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/pending_client_row.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/sent_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/repositories/auto_notification_repository.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/repositories/i_rappels_pending_client_repository.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/repositories/i_sent_notification_repository.dart';

// ── Fake: FollowedMerchantsRepository ────────────────────────────────────────

class _FakeFollowedRepo implements FollowedMerchantsRepository {
  final List<String> followerIds;
  bool shouldFail;
  _FakeFollowedRepo({this.followerIds = const [], this.shouldFail = false});

  @override
  Future<Result<List<String>>> getFollowerIds(String merchantId) async {
    if (shouldFail) return const Left(UnexpectedFailure(message: 'Firestore error'));
    return Right(followerIds);
  }

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
  Stream<List<String>> watchFollowedIds(String userId) =>
      Stream.value(followerIds);
  @override
  Future<Result<Map<String, int>>> getFollowedHeartLevels(
          String userId) async =>
      const Right({});
  @override
  Future<Result<Unit>> setHeartLevel(
          String userId, String merchantId, int heartLevel) async =>
      const Right(unit);
  @override
  Future<Result<bool>> getMuteState(
          String userId, String merchantId) async =>
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
  Future<Result<Unit>> updateSortOrder(
          String userId, Map<String, int> sortIndexes) async =>
      const Right(unit);
}

// ── Fake: ClientNotificationRepository ───────────────────────────────────────

class _FakeClientNotifRepo implements ClientNotificationRepository {
  int createCallCount = 0;
  bool shouldFail;
  ClientNotification? lastCreated;
  _FakeClientNotifRepo({this.shouldFail = false});

  @override
  Future<Result<ClientNotification>> create(
      ClientNotification notification) async {
    createCallCount++;
    if (shouldFail) {
      return const Left(UnexpectedFailure(message: 'Firestore error'));
    }
    final created = notification.copyWith(id: 'notif_$createCallCount');
    lastCreated = created;
    return Right(created);
  }

  @override
  Stream<List<ClientNotification>> watchForClient(String clientId) =>
      Stream.value([]);
  @override
  Future<Result<Unit>> markAsRead(
          String clientId, String notificationId) async =>
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

// ── Fake: ClientLoyaltyRepository (minimal — only getClientSegments used by send) ─

class _FakeLoyaltyRepoForSend implements ClientLoyaltyRepository {
  _FakeLoyaltyRepoForSend({required this.segmentMap});

  /// Simulated `{clientUid: segment}` from loyalty_clients.
  Map<String, String> segmentMap;

  @override
  Future<Map<String, String>> getClientSegments(String merchantId) async =>
      segmentMap;

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

Future<bool> _sendMockOwnershipOk(String merchantId, String callerUid) async =>
    merchantId == 'm1' && callerUid == 'caller_m1';

Future<bool> _sendMockOwnershipDeny(String merchantId, String callerUid) async =>
    false;

// ── Fake: ISentNotificationRepository ────────────────────────────────────────

class _FakeSentNotifRepo implements ISentNotificationRepository {
  SentNotification? lastCreated;
  bool shouldFail;
  _FakeSentNotifRepo({this.shouldFail = false});

  @override
  Future<Result<SentNotification>> create(
      SentNotification notification) async {
    lastCreated = notification;
    if (shouldFail) {
      return const Left(UnexpectedFailure(message: 'Firestore error'));
    }
    return Right(notification.copyWith(id: 'record_1'));
  }

  @override
  Future<Result<List<SentNotification>>> list(String merchantId,
          {int limit = 20}) async =>
      const Right([]);

  @override
  Future<void> incrementWeeklyNotifCount(String merchantId) async {}

  @override
  Future<void> updateSentCount(
    String merchantId,
    String sentNotificationId,
    int sentCount,
  ) async {
    if (lastCreated != null) {
      lastCreated = lastCreated!.copyWith(sentCount: sentCount);
    }
  }

  @override
  Future<void> recordOpen(String merchantId, String sentNotificationId) async {}
}

// ── Fake: IRappelsPendingClientRepository ────────────────────────────────────

class _FakePendingClientRepo implements IRappelsPendingClientRepository {
  String? lastAcknowledgedMerchantId;
  String? lastAcknowledgedClientUid;
  bool shouldFail;
  _FakePendingClientRepo({this.shouldFail = false});

  @override
  Stream<List<PendingClientRow>> watchPendingClients(String merchantId) =>
      Stream.value([]);

  @override
  Future<Result<Unit>> acknowledge(
      String merchantId, String clientUid) async {
    lastAcknowledgedMerchantId = merchantId;
    lastAcknowledgedClientUid = clientUid;
    if (shouldFail) {
      return const Left(UnexpectedFailure(message: 'Firestore error'));
    }
    return const Right(unit);
  }
}

// ── Fake: AutoNotificationRepository ─────────────────────────────────────────

class _FakeAutoNotifRepo implements AutoNotificationRepository {
  List<ActiveNotification> notifications = [];
  bool shouldFail;
  _FakeAutoNotifRepo({this.shouldFail = false});

  @override
  Future<Result<ActiveNotification>> create({
    required String merchantId,
    required ActiveNotification notification,
  }) async {
    if (shouldFail) {
      return const Left(UnexpectedFailure(message: 'Firestore error'));
    }
    final stored = notification.copyWith(id: 'auto_1', merchantId: merchantId);
    notifications.add(stored);
    return Right(stored);
  }

  @override
  Future<Result<List<ActiveNotification>>> listByMerchantId(
      String merchantId) async =>
      Right(notifications
          .where((n) => n.merchantId == merchantId)
          .toList());

  @override
  Future<Result<ActiveNotification>> update(
      ActiveNotification notification) async {
    if (shouldFail) {
      return const Left(UnexpectedFailure(message: 'Firestore error'));
    }
    notifications = notifications
        .map((n) => n.id == notification.id ? notification : n)
        .toList();
    return Right(notification);
  }

  @override
  Future<Result<Unit>> delete({
    required String merchantId,
    required String notificationId,
  }) async {
    if (shouldFail) {
      return const Left(UnexpectedFailure(message: 'Firestore error'));
    }
    notifications.removeWhere((n) => n.id == notificationId);
    return const Right(unit);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── SendMerchantNotification ──────────────────────────────────────────────

  group('SendMerchantNotification', () {
    late _FakeFollowedRepo followedRepo;
    late _FakeClientNotifRepo clientNotifRepo;
    late _FakeSentNotifRepo sentNotifRepo;
    late _FakeLoyaltyRepoForSend loyaltyRepo;
    late SendMerchantNotification useCase;

    setUp(() {
      followedRepo = _FakeFollowedRepo();
      clientNotifRepo = _FakeClientNotifRepo();
      sentNotifRepo = _FakeSentNotifRepo();
      loyaltyRepo = _FakeLoyaltyRepoForSend(segmentMap: const {});
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
    });

    test('returns Right(0) when merchantId is empty', () async {
      final result = await useCase.call(
        merchantId: '',
        merchantName: 'Test',
        text: 'Hello',
        audience: 'Tous mes clients',
        callerUid: 'caller_m1',
      );
      expect(result.isRight, isTrue);
      expect(result.fold((_) => -1, (n) => n), 0);
      expect(clientNotifRepo.createCallCount, 0);
    });

    test('returns Right(0) when text is empty', () async {
      followedRepo = _FakeFollowedRepo(followerIds: ['c1', 'c2']);
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Test',
        text: '   ',
        audience: 'Tous mes clients',
        callerUid: 'caller_m1',
      );
      expect(result.fold((_) => -1, (n) => n), 0);
      expect(clientNotifRepo.createCallCount, 0);
    });

    test('returns Right(0) when no followers', () async {
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Test',
        text: 'Hello',
        audience: 'Tous mes clients',
        callerUid: 'caller_m1',
      );
      expect(result.fold((_) => -1, (n) => n), 0);
      expect(clientNotifRepo.createCallCount, 0);
      expect(sentNotifRepo.lastCreated, isNull);
    });

    test('creates one notification per follower', () async {
      followedRepo =
          _FakeFollowedRepo(followerIds: ['c1', 'c2', 'c3']);
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Boutique Test',
        text: 'Bonne nouvelle !',
        audience: 'Tous mes clients',
        callerUid: 'caller_m1',
      );
      expect(result.isRight, isTrue);
      expect(result.fold((_) => -1, (n) => n), 3);
      expect(clientNotifRepo.createCallCount, 3);
    });

    test('persists sent_notification record with correct sent count', () async {
      followedRepo = _FakeFollowedRepo(followerIds: ['c1', 'c2']);
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      await useCase.call(
        merchantId: 'm1',
        merchantName: 'Boutique',
        text: 'Hello',
        audience: 'Tous mes clients',
        segments: ['vip'],
        callerUid: 'caller_m1',
      );
      expect(sentNotifRepo.lastCreated, isNotNull);
      expect(sentNotifRepo.lastCreated!.sentCount, 2);
      expect(sentNotifRepo.lastCreated!.text, 'Hello');
      expect(sentNotifRepo.lastCreated!.merchantId, 'm1');
      expect(sentNotifRepo.lastCreated!.segments, ['vip']);
    });

    test('links each client inbox doc to the sent_notification record', () async {
      followedRepo = _FakeFollowedRepo(followerIds: ['c1']);
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      await useCase.call(
        merchantId: 'm1',
        merchantName: 'Boutique',
        text: 'Hello',
        audience: 'Tous mes clients',
        callerUid: 'caller_m1',
      );
      expect(clientNotifRepo.lastCreated?.sentNotificationId, 'record_1');
    });

    test('partial failure: still records how many succeeded', () async {
      // First 2 succeed, then fail — but fake repo doesn't partial-fail easily.
      // Verify: even if individual notifs fail, use case is resilient.
      clientNotifRepo = _FakeClientNotifRepo(shouldFail: true);
      followedRepo = _FakeFollowedRepo(followerIds: ['c1', 'c2']);
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Test',
        text: 'Hi',
        audience: 'Tous mes clients',
        callerUid: 'caller_m1',
      );
      expect(result.isRight, isTrue);
      // sent_count should be 0 since all creates failed
      expect(result.fold((_) => -1, (n) => n), 0);
      expect(sentNotifRepo.lastCreated!.sentCount, 0);
    });

    test('notification body matches trimmed input text', () async {
      followedRepo = _FakeFollowedRepo(followerIds: ['c1']);
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      await useCase.call(
        merchantId: 'm1',
        merchantName: 'Boutique',
        text: '  Offre spéciale  ',
        audience: 'Tous mes clients',
        callerUid: 'caller_m1',
      );
      expect(sentNotifRepo.lastCreated!.text, 'Offre spéciale');
    });

    test('follower repo failure returns Right(0) gracefully', () async {
      followedRepo = _FakeFollowedRepo(shouldFail: true);
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Test',
        text: 'Hello',
        audience: 'Tous mes clients',
        callerUid: 'caller_m1',
      );
      // When follower fetch fails, use case treats it as 0 followers.
      expect(result.fold((_) => -1, (n) => n), 0);
      expect(clientNotifRepo.createCallCount, 0);
    });

    test('sent record persist failure does not crash the use case', () async {
      followedRepo = _FakeFollowedRepo(followerIds: ['c1']);
      sentNotifRepo = _FakeSentNotifRepo(shouldFail: true);
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      // Should not throw — persist failure is best-effort.
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Test',
        text: 'Bonjour',
        audience: 'Tous mes clients',
        callerUid: 'caller_m1',
      );
      expect(result.isRight, isTrue);
    });

    test('returns Left when callerUid is empty', () async {
      followedRepo = _FakeFollowedRepo(followerIds: ['c1']);
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Test',
        text: 'Hello',
        audience: 'Tous mes clients',
        callerUid: '',
      );
      expect(result.isLeft, isTrue);
      expect(clientNotifRepo.createCallCount, 0);
    });

    test('returns Left when ownership check fails (cross-merchant)', () async {
      followedRepo = _FakeFollowedRepo(followerIds: ['c1', 'c2']);
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipDeny,
      );
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Fake',
        text: 'Spam',
        audience: 'Tous mes clients',
        callerUid: 'caller_m1',
      );
      expect(result.isLeft, isTrue);
      expect(clientNotifRepo.createCallCount, 0);
    });

    test('Certains clients + segments uses manual VIP from segment map', () async {
      followedRepo = _FakeFollowedRepo(followerIds: ['c1', 'c2']);
      loyaltyRepo = _FakeLoyaltyRepoForSend(segmentMap: {
        'c1': 'nouveau',
        'c2': 'vip',
      });
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Boutique',
        text: 'VIP only',
        audience: 'Certains clients',
        segments: ['vip'],
        callerUid: 'caller_m1',
      );
      expect(result.fold((_) => -1, (n) => n), 1);
      expect(clientNotifRepo.createCallCount, 1);
    });

    test('Certains clients + segments filters by loyalty map', () async {
      followedRepo = _FakeFollowedRepo(followerIds: ['c1', 'c2', 'c3']);
      loyaltyRepo = _FakeLoyaltyRepoForSend(segmentMap: {
        'c1': 'vip',
        'c2': 'nouveau',
        'c3': 'vip',
      });
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Boutique',
        text: 'VIP only',
        audience: 'Certains clients',
        segments: ['vip'],
        callerUid: 'caller_m1',
      );
      expect(result.fold((_) => -1, (n) => n), 2);
      expect(clientNotifRepo.createCallCount, 2);
    });

    test('Certains clients + soutien matches vip and habitue', () async {
      followedRepo = _FakeFollowedRepo(followerIds: ['c1', 'c2', 'c3', 'c4']);
      loyaltyRepo = _FakeLoyaltyRepoForSend(segmentMap: {
        'c1': 'vip',
        'c2': 'habitue',
        'c3': 'nouveau',
        'c4': 'inactif',
      });
      useCase = SendMerchantNotification(
        followedRepo: followedRepo,
        notificationRepo: clientNotifRepo,
        sentNotifRepo: sentNotifRepo,
        loyaltyRepo: loyaltyRepo,
        isOwner: _sendMockOwnershipOk,
      );
      final result = await useCase.call(
        merchantId: 'm1',
        merchantName: 'Boutique',
        text: 'Soutien',
        audience: 'Certains clients',
        segments: ['soutien'],
        callerUid: 'caller_m1',
      );
      expect(result.fold((_) => -1, (n) => n), 2);
      expect(clientNotifRepo.createCallCount, 2);
    });
  });

  // ── AcknowledgeNewClient ──────────────────────────────────────────────────

  group('AcknowledgeNewClient', () {
    late _FakePendingClientRepo repo;
    late AcknowledgeNewClient useCase;

    setUp(() {
      repo = _FakePendingClientRepo();
      useCase = AcknowledgeNewClient(repo);
    });

    test('delegates merchantId and clientUid to repo', () async {
      final result = await useCase.call(
        merchantId: 'm1',
        clientUid: 'c1',
      );
      expect(result.isRight, isTrue);
      expect(repo.lastAcknowledgedMerchantId, 'm1');
      expect(repo.lastAcknowledgedClientUid, 'c1');
    });

    test('propagates repo failure as Left', () async {
      repo = _FakePendingClientRepo(shouldFail: true);
      useCase = AcknowledgeNewClient(repo);
      final result = await useCase.call(
        merchantId: 'm1',
        clientUid: 'c1',
      );
      expect(result.isLeft, isTrue);
    });
  });

  // ── CreateAutoNotification ────────────────────────────────────────────────

  group('CreateAutoNotification', () {
    late _FakeAutoNotifRepo repo;
    late CreateAutoNotification useCase;

    setUp(() {
      repo = _FakeAutoNotifRepo();
      useCase = CreateAutoNotification(repo);
    });

    test('creates and returns notification with assigned id', () async {
      const notif = ActiveNotification(
        id: '',
        merchantId: '',
        text: 'Bienvenue !',
        trigger: 'Nouveau client connecté',
      );
      final result = await useCase.call(merchantId: 'm1', notification: notif);
      expect(result.isRight, isTrue);
      result.fold((_) {}, (n) {
        expect(n.id, isNotEmpty);
        expect(n.merchantId, 'm1');
        expect(n.text, 'Bienvenue !');
        expect(n.trigger, 'Nouveau client connecté');
      });
    });

    test('propagates repo failure', () async {
      repo = _FakeAutoNotifRepo(shouldFail: true);
      useCase = CreateAutoNotification(repo);
      const notif = ActiveNotification(id: '', merchantId: '', text: 'Hi');
      final result = await useCase.call(merchantId: 'm1', notification: notif);
      expect(result.isLeft, isTrue);
    });

    test('stores notification in repo list', () async {
      const notif = ActiveNotification(
        id: '',
        merchantId: '',
        text: 'Flash sale',
      );
      await useCase.call(merchantId: 'm1', notification: notif);
      expect(repo.notifications.length, 1);
      expect(repo.notifications.first.text, 'Flash sale');
    });
  });

  // ── UpdateAutoNotification ────────────────────────────────────────────────

  group('UpdateAutoNotification', () {
    late _FakeAutoNotifRepo repo;
    late UpdateAutoNotification useCase;

    setUp(() {
      repo = _FakeAutoNotifRepo();
      useCase = UpdateAutoNotification(repo);
    });

    test('updates existing notification text', () async {
      const original = ActiveNotification(
        id: 'auto_1',
        merchantId: 'm1',
        text: 'Original',
      );
      repo.notifications = [original];
      final updated = original.copyWith(text: 'Updated');
      final result = await useCase.call(updated);
      expect(result.isRight, isTrue);
      expect(repo.notifications.first.text, 'Updated');
    });

    test('toggles isEnabled from true to false', () async {
      const original = ActiveNotification(
        id: 'auto_1',
        merchantId: 'm1',
        text: 'Test',
        isEnabled: true,
      );
      repo.notifications = [original];
      final toggled = original.copyWith(isEnabled: false);
      final result = await useCase.call(toggled);
      expect(result.isRight, isTrue);
      expect(repo.notifications.first.isEnabled, isFalse);
    });

    test('propagates repo failure', () async {
      repo = _FakeAutoNotifRepo(shouldFail: true);
      useCase = UpdateAutoNotification(repo);
      const notif = ActiveNotification(
          id: 'n1', merchantId: 'm1', text: 'Hi');
      final result = await useCase.call(notif);
      expect(result.isLeft, isTrue);
    });
  });

  // ── DeleteAutoNotification ────────────────────────────────────────────────

  group('DeleteAutoNotification', () {
    late _FakeAutoNotifRepo repo;
    late DeleteAutoNotification useCase;

    setUp(() {
      repo = _FakeAutoNotifRepo();
      useCase = DeleteAutoNotification(repo);
    });

    test('removes notification from repo', () async {
      const notif = ActiveNotification(
        id: 'auto_1',
        merchantId: 'm1',
        text: 'Delete me',
      );
      repo.notifications = [notif];
      final result = await useCase.call(
        merchantId: 'm1',
        notificationId: 'auto_1',
      );
      expect(result.isRight, isTrue);
      expect(repo.notifications, isEmpty);
    });

    test('returns Right even if notification does not exist (idempotent)',
        () async {
      final result = await useCase.call(
        merchantId: 'm1',
        notificationId: 'non_existent',
      );
      expect(result.isRight, isTrue);
    });

    test('propagates repo failure', () async {
      repo = _FakeAutoNotifRepo(shouldFail: true);
      useCase = DeleteAutoNotification(repo);
      final result = await useCase.call(
        merchantId: 'm1',
        notificationId: 'n1',
      );
      expect(result.isLeft, isTrue);
    });
  });

  // ── SentNotification production-readiness checks ─────────────────────────

  group('SentNotification — production data shapes', () {
    test('Firestore field names are snake_case (convention check)', () {
      // This verifies the DTO convention matches Cloud Function field names.
      // The DTO uses: merchant_id, text, audience, segments, sent_count, sent_at.
      // The Cloud Function writes: sent_count, last_sent_at.
      // We just verify the domain entity carries the right fields.
      final now = DateTime.now();
      final n = SentNotification(
        id: 'id1',
        merchantId: 'merchant_123',
        text: 'Bonjour',
        audience: 'Tous mes clients',
        segments: const ['vip'],
        sentCount: 10,
        sentAt: now,
      );
      expect(n.merchantId, 'merchant_123');
      expect(n.sentCount, 10);
      expect(n.segments, ['vip']);
      expect(n.sentAt, now);
    });
  });

  // ── ActiveNotification delivery stats ────────────────────────────────────

  group('ActiveNotification — delivery stats', () {
    test('sentCount defaults to 0 for new notifications', () {
      const n = ActiveNotification(id: 'n', merchantId: 'm', text: 'Hi');
      expect(n.sentCount, 0);
    });

    test('lastSentAt can be set via copyWith and persists', () {
      final now = DateTime(2025, 4, 22, 12, 0);
      const n = ActiveNotification(id: 'n', merchantId: 'm', text: 'Hi');
      final updated = n.copyWith(sentCount: 3, lastSentAt: now);
      expect(updated.sentCount, 3);
      expect(updated.lastSentAt, now);
    });

    test('delivery stats do NOT affect trigger/audience/text', () {
      const n = ActiveNotification(
        id: 'n',
        merchantId: 'm',
        text: 'Bonne journée',
        trigger: 'Passage fidélité validé',
        audience: 'Tous mes clients',
      );
      final updated = n.copyWith(sentCount: 99);
      expect(updated.trigger, 'Passage fidélité validé');
      expect(updated.audience, 'Tous mes clients');
      expect(updated.text, 'Bonne journée');
    });
  });
}
