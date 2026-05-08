import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/merchant_partners/infrastructure/merchant_partner_repository_impl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreMerchantPartnerRepository — pins the partner_merchant_type
// snapshot semantics that drive the B2B/B2C filter on the
// recommandations screen. Three behaviours that have to agree:
//   1. addPartner persists a clean ('b2b'|'b2c') type;
//   2. addPartner DROPS exotic types so a typo can't pollute Firestore;
//   3. fromFirestore round-trips the field and is defensive against
//      legacy docs (no field) and forward-compat docs (unknown values).
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const merchantId = 'm1';
  late FakeFirebaseFirestore firestore;
  late FirestoreMerchantPartnerRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreMerchantPartnerRepository(firestore);
  });

  Future<Map<String, dynamic>?> readFirstPartnerDoc() async {
    final snap = await firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('partners')
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  group('addPartner — partnerMerchantType', () {
    test('persists b2c when explicitly passed', () async {
      await repo.addPartner(
        merchantId: merchantId,
        partnerMerchantId: 'm-other',
        partnerName: 'Café du coin',
        partnerMerchantType: 'b2c',
      );
      final data = await readFirstPartnerDoc();
      expect(data!['partner_merchant_type'], 'b2c');
    });

    test('persists b2b when explicitly passed', () async {
      await repo.addPartner(
        merchantId: merchantId,
        partnerMerchantId: 'm-other',
        partnerName: 'Plombier Pro',
        partnerMerchantType: 'b2b',
      );
      final data = await readFirstPartnerDoc();
      expect(data!['partner_merchant_type'], 'b2b');
    });

    test('omits the field when no type is provided (legacy callers)',
        () async {
      await repo.addPartner(
        merchantId: merchantId,
        partnerMerchantId: 'm-other',
        partnerName: 'Sans Type',
      );
      final data = await readFirstPartnerDoc();
      expect(data!.containsKey('partner_merchant_type'), isFalse,
          reason:
              'Omitting the field signals "type unknown" — the entity\'s '
              'null check + the badge widget then hide the badge.');
    });

    test('drops an unknown type value (defensive)', () async {
      await repo.addPartner(
        merchantId: merchantId,
        partnerMerchantId: 'm-other',
        partnerName: 'Bad Caller',
        partnerMerchantType: 'b2x',
      );
      final data = await readFirstPartnerDoc();
      expect(data!.containsKey('partner_merchant_type'), isFalse);
    });
  });

  group('getMerchantPartners — round-trip', () {
    test('reads partner_merchant_type back into the entity', () async {
      await repo.addPartner(
        merchantId: merchantId,
        partnerMerchantId: 'p1',
        partnerName: 'Café',
        partnerMerchantType: 'b2c',
      );
      final list = await repo.getMerchantPartners(merchantId).first;
      expect(list, hasLength(1));
      expect(list.single.partnerMerchantType, 'b2c');
    });

    test('treats a legacy doc (no field) as null type', () async {
      // Direct write — bypass the validator so we simulate a doc
      // written by an old client.
      await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('partners')
          .add({
        'partner_merchant_id': 'p2',
        'partner_name': 'Old Doc',
        'added_at': Timestamp.now(),
        'is_pending': true,
      });
      final list = await repo.getMerchantPartners(merchantId).first;
      expect(list.single.partnerMerchantType, isNull);
    });

    test('drops an unknown type value to null on read (forward-compat)',
        () async {
      await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('partners')
          .add({
        'partner_merchant_id': 'p3',
        'partner_name': 'Future',
        'partner_merchant_type': 'b2g',
        'added_at': Timestamp.now(),
        'is_pending': true,
      });
      final list = await repo.getMerchantPartners(merchantId).first;
      expect(list.single.partnerMerchantType, isNull,
          reason:
              'Unknown values must NEVER reach the UI — would render '
              'as garbage in the badge widget.');
    });
  });
}
