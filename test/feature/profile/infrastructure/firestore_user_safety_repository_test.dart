import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/profile/domain/repositories/user_safety_repository.dart';
import 'package:flutter_yuztoo/feature/profile/infrastructure/firestore_user_safety_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreUserSafetyRepository — covers blocking idempotency, the report
// schema gates that mirror firestore.rules, and the live blocklist stream
// the carnet UI consumes.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const userId = 'u1';
  const merchantId = 'm1';

  late FakeFirebaseFirestore firestore;
  late FirestoreUserSafetyRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreUserSafetyRepository(firestore: firestore);
  });

  group('blockMerchant / unblockMerchant', () {
    test('block writes a doc and the watcher emits the new id', () async {
      // Prime the stream BEFORE the write so the test sees both states.
      final emissions = <Set<String>>[];
      final sub = repo
          .watchBlockedMerchantIds(userId)
          .listen(emissions.add);

      // Initial empty state.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emissions.first, isEmpty);

      final result = await repo.blockMerchant(
        userId: userId,
        merchantId: merchantId,
      );
      expect(result.isRight, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emissions.last, {merchantId});

      await sub.cancel();
    });

    test('block is idempotent — second call still succeeds', () async {
      final first = await repo.blockMerchant(
          userId: userId, merchantId: merchantId);
      final second = await repo.blockMerchant(
          userId: userId, merchantId: merchantId);
      expect(first.isRight, isTrue);
      expect(second.isRight, isTrue);
    });

    test('block payload contains ONLY created_at (rules allowlist)',
        () async {
      await repo.blockMerchant(userId: userId, merchantId: merchantId);
      final snap = await firestore
          .collection('users')
          .doc(userId)
          .collection('blocked_merchants')
          .doc(merchantId)
          .get();
      expect(snap.exists, isTrue);
      // The schema gate in firestore.rules rejects any extra field, so
      // this assertion is what makes the rules deployable safely.
      expect(snap.data()!.keys.toSet(), {'created_at'});
    });

    test('unblock removes the doc; idempotent on missing doc', () async {
      await repo.blockMerchant(userId: userId, merchantId: merchantId);
      final removed = await repo.unblockMerchant(
          userId: userId, merchantId: merchantId);
      expect(removed.isRight, isTrue);

      final removedAgain = await repo.unblockMerchant(
          userId: userId, merchantId: merchantId);
      expect(removedAgain.isRight, isTrue,
          reason:
              'unblocking a non-blocked merchant must not surface an error');

      final snap = await firestore
          .collection('users')
          .doc(userId)
          .collection('blocked_merchants')
          .doc(merchantId)
          .get();
      expect(snap.exists, isFalse);
    });

    test('rejects empty userId / merchantId without writing', () async {
      final r1 = await repo.blockMerchant(userId: '', merchantId: 'x');
      final r2 = await repo.blockMerchant(userId: 'x', merchantId: '');
      expect(r1.isLeft, isTrue);
      expect(r2.isLeft, isTrue);
    });

    test('watcher returns empty stream when userId is empty', () async {
      final result = await repo.watchBlockedMerchantIds('').first;
      expect(result, isEmpty);
    });
  });

  group('submitReport', () {
    test('writes a doc with all required fields when valid', () async {
      final result = await repo.submitReport(
        reporterUid: userId,
        targetType: ReportTargetType.merchant,
        targetId: merchantId,
        reason: ReportReason.spam,
        message: 'Sends 10 push per day',
      );
      expect(result.isRight, isTrue);

      final snap = await firestore.collection('reports').get();
      expect(snap.docs, hasLength(1));
      final data = snap.docs.first.data();
      expect(data['reporter_uid'], userId);
      expect(data['target_type'], 'merchant');
      expect(data['target_id'], merchantId);
      expect(data['reason'], 'spam');
      expect(data['message'], 'Sends 10 push per day');
      expect(data['created_at'], isNotNull);
    });

    test('omits empty / whitespace-only message field', () async {
      await repo.submitReport(
        reporterUid: userId,
        targetType: ReportTargetType.merchant,
        targetId: merchantId,
        reason: ReportReason.fraud,
        message: '   ',
      );
      final snap = await firestore.collection('reports').get();
      expect(snap.docs.first.data().containsKey('message'), isFalse,
          reason:
              'whitespace-only is meaningless — drop the field rather '
              'than persisting noise');
    });

    test('rejects empty reporterUid / targetId without writing', () async {
      final r1 = await repo.submitReport(
        reporterUid: '',
        targetType: ReportTargetType.merchant,
        targetId: merchantId,
        reason: ReportReason.spam,
      );
      final r2 = await repo.submitReport(
        reporterUid: userId,
        targetType: ReportTargetType.merchant,
        targetId: '',
        reason: ReportReason.spam,
      );
      expect(r1.isLeft, isTrue);
      expect(r2.isLeft, isTrue);

      final snap = await firestore.collection('reports').get();
      expect(snap.docs, isEmpty);
    });

    test('rejects oversized targetId (>128 chars)', () async {
      final result = await repo.submitReport(
        reporterUid: userId,
        targetType: ReportTargetType.merchant,
        targetId: 'a' * 129,
        reason: ReportReason.spam,
      );
      expect(result.isLeft, isTrue);
    });

    test('rejects oversized message (>500 chars)', () async {
      final result = await repo.submitReport(
        reporterUid: userId,
        targetType: ReportTargetType.merchant,
        targetId: merchantId,
        reason: ReportReason.spam,
        message: 'x' * 501,
      );
      expect(result.isLeft, isTrue);
    });

    test('every ReportReason serialises to its wire string', () {
      // Lock the wire form so a future `toString()` change can't silently
      // break the firestore.rules allowlist match.
      expect(ReportReason.spam.wire, 'spam');
      expect(ReportReason.harassment.wire, 'harassment');
      expect(ReportReason.inappropriate.wire, 'inappropriate');
      expect(ReportReason.fraud.wire, 'fraud');
      expect(ReportReason.fakeBusiness.wire, 'fake_business');
      expect(ReportReason.other.wire, 'other');
    });

    test('every ReportTargetType serialises to its wire string', () {
      expect(ReportTargetType.merchant.wire, 'merchant');
      expect(ReportTargetType.promotion.wire, 'promotion');
      expect(ReportTargetType.notification.wire, 'notification');
      expect(ReportTargetType.user.wire, 'user');
    });
  });

  group('rules integration: payload shape', () {
    test('block payload created_at is a serverTimestamp sentinel',
        () async {
      await repo.blockMerchant(userId: userId, merchantId: merchantId);
      final snap = await firestore
          .collection('users')
          .doc(userId)
          .collection('blocked_merchants')
          .doc(merchantId)
          .get();
      // FakeFirebaseFirestore resolves the sentinel to a real Timestamp;
      // production rules accept either form ("is timestamp" matches both).
      expect(snap.data()?['created_at'], isA<Timestamp>());
    });
  });
}
