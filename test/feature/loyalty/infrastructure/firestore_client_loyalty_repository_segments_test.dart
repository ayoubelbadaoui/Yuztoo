import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/loyalty/infrastructure/firestore_client_loyalty_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// getClientSegments — segment computation for notification / promo targeting.
//
// Covers:
//   • happy path: clients with 3+ validated passages and a recent visit are
//     classified as 'habitue' (this was the user-reported regression — sending
//     a "Habitué" notification did not reach clients who had clearly crossed
//     the threshold in the CRM view).
//   • the anchor is `last_passage_at`, NOT `updated_at` — a CRM edit (which
//     bumps `updated_at`) must not falsely re-activate an inactive client.
//   • legacy docs without `last_passage_at` fall back to `updated_at`.
//   • manual_segment from `merchants/{id}/clients/{uid}` overrides the
//     auto-computed segment.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const merchantId = 'm1';

  late FakeFirebaseFirestore firestore;
  late FirestoreClientLoyaltyRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreClientLoyaltyRepository(firestore: firestore);
  });

  Future<void> seedLoyalty(
    String clientUid, {
    required int validatedPassages,
    DateTime? lastPassageAt,
    DateTime? updatedAt,
  }) async {
    final data = <String, dynamic>{
      'validated_passages': validatedPassages,
      'pending_passages': 0,
      'cumulative_spend_euros': 0,
      'updated_at': updatedAt ?? DateTime.now(),
    };
    if (lastPassageAt != null) {
      data['last_passage_at'] = lastPassageAt;
    }
    await firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('loyalty_clients')
        .doc(clientUid)
        .set(data);
  }

  Future<void> seedManualSegment(String clientUid, String segment) async {
    await firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('clients')
        .doc(clientUid)
        .set({'manual_segment': segment});
  }

  group('getClientSegments — auto computation', () {
    test('client with 3 validated passages and recent activity → habitue',
        () async {
      await seedLoyalty(
        'c_habitue',
        validatedPassages: 3,
        lastPassageAt: DateTime.now(),
      );
      final out = await repo.getClientSegments(merchantId);
      expect(out['c_habitue'], 'habitue',
          reason:
              'this is the exact case from the user report — a client who '
              'just transitioned from nouveau to habitue must surface as '
              'habitue at send time, otherwise habitue-targeted notifications '
              'silently exclude them');
    });

    test('client with 10 validated passages → vip', () async {
      await seedLoyalty(
        'c_vip',
        validatedPassages: 10,
        lastPassageAt: DateTime.now(),
      );
      final out = await repo.getClientSegments(merchantId);
      expect(out['c_vip'], 'vip');
    });

    test('client with 2 validated passages → nouveau', () async {
      await seedLoyalty(
        'c_new',
        validatedPassages: 2,
        lastPassageAt: DateTime.now(),
      );
      final out = await repo.getClientSegments(merchantId);
      expect(out['c_new'], 'nouveau');
    });

    test(
        'client with 5 passages but last_passage_at > 60 days ago → inactif',
        () async {
      await seedLoyalty(
        'c_inactif',
        validatedPassages: 5,
        lastPassageAt: DateTime.now().subtract(const Duration(days: 90)),
        // updated_at is recent — the merchant edited their CRM notes
        // yesterday — but they have not actually visited in 3 months.
        // The previous implementation used updated_at as the anchor and
        // would have misclassified them as habitue.
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      final out = await repo.getClientSegments(merchantId);
      expect(out['c_inactif'], 'inactif',
          reason:
              'merchant CRM activity must not artificially keep a client '
              'classified as active — last_passage_at is the authoritative '
              'visit anchor');
    });
  });

  group('getClientSegments — legacy fallback to updated_at', () {
    test('doc without last_passage_at falls back to updated_at', () async {
      // No last_passage_at — simulates a doc written before the cooldown
      // anchor was introduced.
      await seedLoyalty(
        'c_legacy',
        validatedPassages: 3,
        lastPassageAt: null,
        updatedAt: DateTime.now(),
      );
      final out = await repo.getClientSegments(merchantId);
      expect(out['c_legacy'], 'habitue');
    });

    test('legacy doc with old updated_at → inactif', () async {
      await seedLoyalty(
        'c_legacy_old',
        validatedPassages: 5,
        lastPassageAt: null,
        updatedAt: DateTime.now().subtract(const Duration(days: 90)),
      );
      final out = await repo.getClientSegments(merchantId);
      expect(out['c_legacy_old'], 'inactif');
    });
  });

  group('getClientSegments — manual override', () {
    test('manual_segment overrides the auto-computed segment', () async {
      await seedLoyalty(
        'c_manual',
        validatedPassages: 0,
        lastPassageAt: DateTime.now(),
      );
      // Merchant has manually tagged this client as VIP even though they
      // have 0 visits — a "long-time friend" override.
      await seedManualSegment('c_manual', 'vip');
      final out = await repo.getClientSegments(merchantId);
      expect(out['c_manual'], 'vip');
    });

    test('empty / whitespace manual_segment is ignored', () async {
      await seedLoyalty(
        'c_blank',
        validatedPassages: 3,
        lastPassageAt: DateTime.now(),
      );
      await seedManualSegment('c_blank', '   ');
      final out = await repo.getClientSegments(merchantId);
      expect(out['c_blank'], 'habitue',
          reason:
              'a blank manual_segment must not erase the auto computation');
    });
  });
}
