import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/failures/passage_cooldown_failure.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/repositories/client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/loyalty/infrastructure/firestore_client_loyalty_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';

/// P0 race / transactional guards using FakeFirebaseFirestore (no emulator).
///
/// Complements `test/firebase-rules` which exercises real `firestore.rules`.
void main() {
  const merchantId = 'm_race';
  const clientUid = 'c_race';

  late FakeFirebaseFirestore firestore;
  late FirestoreClientLoyaltyRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreClientLoyaltyRepository(
      firestore: firestore,
      passageCooldown: const Duration(hours: 1),
    );
  });

  Future<void> seedMerchant() async {
    await firestore.collection('merchants').doc(merchantId).set({
      'owner_uid': 'owner1',
      'name': 'Race Shop',
      'passage_cooldown_enabled': true,
    });
  }

  Future<void> seedAwaitingSession({
    String source = 'vitrine',
    bool merchantBleConnected = false,
  }) async {
    final data = <String, dynamic>{
      'client_uid': clientUid,
      'client_display_name': 'Client Race',
      'status': 'awaiting',
      'created_at': Timestamp.now(),
      'program_snapshot': {
        'program_enabled': true,
        'trigger_type': 'visitCount',
        'visits_required': 10,
        'passage_validation': 'manual',
      },
      'source': source,
    };
    if (source == 'ble') {
      data['client_ble_connected_at'] = Timestamp.now();
      if (merchantBleConnected) {
        data['merchant_ble_connected_at'] = Timestamp.now();
      }
    }
    await firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('active_validations')
        .doc(clientUid)
        .set(data);
  }

  Future<Result<dynamic>> confirm({
    int validatedDelta = 1,
    double spendDelta = 0,
    bool enforceCooldown = true,
  }) {
    return repo.applyPassageDeltas(
      merchantId: merchantId,
      clientUid: clientUid,
      validatedPassagesDelta: validatedDelta,
      cumulativeSpendEurosDelta: spendDelta,
      enrollProgram: const LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 10,
      ),
      completeActiveValidation: ActiveValidationCompletion(
        validatedDelta: validatedDelta,
        spendDelta: spendDelta,
      ),
      enforcePassageCooldown: enforceCooldown,
    );
  }

  group('P0 race — double confirm / session state', () {
    test('first confirm succeeds; second hits not-awaiting', () async {
      await seedMerchant();
      await seedAwaitingSession();

      final first = await confirm();
      expect(first.isRight, isTrue, reason: 'first confirm must apply');

      final session = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('active_validations')
          .doc(clientUid)
          .get();
      expect(session.data()?['status'], 'completed');

      final loyalty = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('loyalty_clients')
          .doc(clientUid)
          .get();
      expect(loyalty.data()?['validated_passages'], 1);

      final second = await confirm();
      expect(second.isLeft, isTrue);
      second.fold(
        (f) => expect(f.message, contains('déjà été traitée')),
        (_) => fail('expected Left'),
      );

      final loyaltyAfter = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('loyalty_clients')
          .doc(clientUid)
          .get();
      expect(loyaltyAfter.data()?['validated_passages'], 1,
          reason: 'no double credit');
    });

    test(
      'parallel double confirm race',
      () async {},
      skip:
          'FakeFirebaseFirestore lacks concurrent transaction isolation; covered by sequential double-tap + test/firebase-rules',
    );

    test('missing session ⇒ introuvable', () async {
      await seedMerchant();
      final out = await confirm();
      expect(out.isLeft, isTrue);
      out.fold(
        (f) => expect(f.message, contains('introuvable')),
        (_) => fail('expected Left'),
      );
    });

    test('BLE session without merchant_ble_connected_at rejected', () async {
      await seedMerchant();
      await seedAwaitingSession(source: 'ble', merchantBleConnected: false);

      final out = await confirm();
      expect(out.isLeft, isTrue);
      out.fold(
        (f) => expect(f.message.toLowerCase(), contains('ble')),
        (_) => fail('expected Left'),
      );

      final loyalty = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('loyalty_clients')
          .doc(clientUid)
          .get();
      expect(loyalty.exists, isFalse, reason: 'no credit without BLE accept');
    });

    test('BLE session with merchant_ble_connected_at succeeds', () async {
      await seedMerchant();
      await seedAwaitingSession(source: 'ble', merchantBleConnected: true);

      final out = await confirm();
      expect(out.isRight, isTrue);
    });
  });

  group('P0 race — cooldown SDK guard', () {
    test('second passage inside 1h ⇒ PassageCooldownFailure', () async {
      await seedMerchant();
      await seedAwaitingSession();

      final first = await confirm();
      expect(first.isRight, isTrue);

      // Re-open a fresh awaiting session (client reset path).
      await seedAwaitingSession();

      final second = await confirm(enforceCooldown: true);
      expect(second.isLeft, isTrue);
      second.fold(
        (f) => expect(f, isA<PassageCooldownFailure>()),
        (_) => fail('expected cooldown failure'),
      );

      final loyalty = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('loyalty_clients')
          .doc(clientUid)
          .get();
      expect(loyalty.data()?['validated_passages'], 1);
    });

    test('enforcePassageCooldown false allows rapid second passage', () async {
      await seedMerchant();
      await seedAwaitingSession();
      expect((await confirm()).isRight, isTrue);

      await seedAwaitingSession();
      final second = await confirm(enforceCooldown: false);
      expect(second.isRight, isTrue);

      final loyalty = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('loyalty_clients')
          .doc(clientUid)
          .get();
      expect(loyalty.data()?['validated_passages'], 2);
    });
  });

  group('P0 race — client cancel then merchant confirm', () {
    test('cancelled session cannot be completed', () async {
      await seedMerchant();
      await seedAwaitingSession();

      await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('active_validations')
          .doc(clientUid)
          .update({
        'status': 'cancelled',
        'cancel_reason': 'client_cancelled',
      });

      final out = await confirm();
      expect(out.isLeft, isTrue);
      out.fold(
        (f) => expect(f.message, contains('déjà été traitée')),
        (_) => fail('expected Left'),
      );
    });
  });
}
