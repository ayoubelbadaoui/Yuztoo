import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_bon.dart';
import 'package:flutter_yuztoo/feature/loyalty/infrastructure/firestore_client_bon_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreClientBonRepository — verifies the read-side contract: live
// stream of bons under users/{uid}/loyalty_bons/, with defensive parsing
// (a corrupt doc must NOT blank out the whole list — a single bad
// merchant config could otherwise hide every bon the user has).
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const userId = 'u1';
  late FakeFirebaseFirestore firestore;
  late FirestoreClientBonRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreClientBonRepository(firestore: firestore);
  });

  Future<void> writeBon(String bonId, Map<String, dynamic> data) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('loyalty_bons')
        .doc(bonId)
        .set(data);
  }

  test('empty userId emits an empty list and does not query', () async {
    final bons = await repo.watchAll('').first;
    expect(bons, isEmpty);
  });

  test('empty subcollection emits empty list', () async {
    final bons = await repo.watchAll(userId).first;
    expect(bons, isEmpty);
  });

  test('parses a well-formed welcome bon doc', () async {
    await writeBon('welcome_m1', {
      'merchant_id': 'm1',
      'kind': 'welcome',
      'description': 'Café offert',
      'issued_at': Timestamp.fromDate(DateTime(2026, 5, 1)),
      'valid_until_at': Timestamp.fromDate(DateTime(2026, 6, 1)),
      'redeemed_at': null,
      'notified_expiring_at': null,
      'notified_expired_at': null,
    });
    final bons = await repo.watchAll(userId).first;
    expect(bons, hasLength(1));
    final b = bons.single;
    expect(b.id, 'welcome_m1');
    expect(b.merchantId, 'm1');
    expect(b.kind, ClientBonKind.welcome);
    expect(b.description, 'Café offert');
    expect(b.validUntilAt, DateTime(2026, 6, 1));
    expect(b.redeemedAt, isNull);
  });

  test('parses an evergreen milestone bon (null valid_until_at)', () async {
    await writeBon('mile1', {
      'merchant_id': 'm2',
      'kind': 'milestone',
      'description': 'Bon fidélité — 10€',
      'issued_at': Timestamp.fromDate(DateTime(2026, 4, 1)),
      'valid_until_at': null,
    });
    final bons = await repo.watchAll(userId).first;
    expect(bons.single.validUntilAt, isNull);
    expect(bons.single.kind, ClientBonKind.milestone);
  });

  test('skips a doc with empty merchant_id (corrupt)', () async {
    await writeBon('orphan', {
      'merchant_id': '',
      'kind': 'milestone',
      'description': 'noise',
    });
    await writeBon('good', {
      'merchant_id': 'm3',
      'kind': 'milestone',
      'description': 'ok',
    });
    final bons = await repo.watchAll(userId).first;
    // The bad doc is dropped, the good one passes through. This is what
    // makes "Mes avantages" tolerant to data corruption.
    expect(bons, hasLength(1));
    expect(bons.single.merchantId, 'm3');
  });

  test('skips a doc with unknown kind (forward-compat guard)', () async {
    await writeBon('future', {
      'merchant_id': 'm1',
      'kind': 'invitation',
      'description': 'will be a thing in v2',
    });
    final bons = await repo.watchAll(userId).first;
    expect(bons, isEmpty);
  });

  test('emits new bon as it lands (live stream)', () async {
    final emissions = <List<ClientBon>>[];
    final sub = repo.watchAll(userId).listen(emissions.add);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(emissions.first, isEmpty);

    await writeBon('milestone_42', {
      'merchant_id': 'm4',
      'kind': 'milestone',
      'description': '10€',
      'issued_at': Timestamp.now(),
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(emissions.last, hasLength(1));
    expect(emissions.last.single.id, 'milestone_42');

    await sub.cancel();
  });

  test('redeemed and notified timestamps round-trip correctly', () async {
    await writeBon('mile2', {
      'merchant_id': 'm1',
      'kind': 'milestone',
      'description': 'x',
      'issued_at': Timestamp.now(),
      'redeemed_at': Timestamp.fromDate(DateTime(2026, 5, 6)),
      'notified_expiring_at': Timestamp.fromDate(DateTime(2026, 5, 5)),
      'notified_expired_at': Timestamp.fromDate(DateTime(2026, 5, 7)),
    });
    final bons = await repo.watchAll(userId).first;
    expect(bons.single.redeemedAt, DateTime(2026, 5, 6));
    expect(bons.single.notifiedExpiringAt, DateTime(2026, 5, 5));
    expect(bons.single.notifiedExpiredAt, DateTime(2026, 5, 7));
  });
}
