import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/infrastructure/firestore_merchant_repository.dart';

Merchant _wizardMerchant({String? logoUrl}) => Merchant(
      id: 'u1',
      ownerUid: 'u1',
      name: 'Nouveau Nom',
      email: 'shop@example.fr',
      phone: '',
      city: 'Montbéliard',
      status: 'inactive',
      logoUrl: logoUrl,
    );

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreMerchantRepository repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = FirestoreMerchantRepository(firestore: db);
    await db.collection('users').doc('u1').set({
      'roles': {'client': true},
      'onboarding': {'client': 'completed'},
    });
  });

  test('brand-new merchant: shop created (inactive), onboarding completed',
      () async {
    final result = await repo.createMerchantAndLinkUser(
      merchant: _wizardMerchant(),
      userId: 'u1',
    );
    expect(result.isRight, isTrue);
    final shop = (await db.collection('merchants').doc('u1').get()).data()!;
    expect(shop['status'], 'inactive');
    expect(shop['name'], 'Nouveau Nom');
    final user = (await db.collection('users').doc('u1').get()).data()!;
    expect(user['onboarding']['merchant'], 'completed');
    expect(user['onboarding']['client'], 'completed',
        reason: 'client onboarding must be preserved');
  });

  test('wizard re-run on an existing live shop: profile updated, but status, '
      'loyalty, plan and logo are kept', () async {
    await db.collection('merchants').doc('u1').set({
      'owner_uid': 'u1',
      'name': 'Ancien Nom',
      'email': 'old@example.fr',
      'phone': '0601020304',
      'city': 'Montbéliard',
      'status': 'active',
      'subscription_plan': 'premium',
      'loyalty_enabled': true,
      'logo_url': 'https://cdn/logo.png',
      'news_image_urls': ['https://cdn/a.png'],
    });

    final result = await repo.createMerchantAndLinkUser(
      merchant: _wizardMerchant(), // no logo picked this time
      userId: 'u1',
    );
    expect(result.isRight, isTrue);

    final shop = (await db.collection('merchants').doc('u1').get()).data()!;
    expect(shop['name'], 'Nouveau Nom', reason: 'wizard edits are applied');
    expect(shop['email'], 'shop@example.fr');
    expect(shop['status'], 'active', reason: 'shop must not go offline');
    expect(shop['subscription_plan'], 'premium');
    expect(shop['loyalty_enabled'], isTrue);
    expect(shop['logo_url'], 'https://cdn/logo.png',
        reason: 'no new logo → existing logo kept');
    expect(shop['news_image_urls'], ['https://cdn/a.png']);
  });

  test('soft-deleted shop is recreated from scratch', () async {
    await db.collection('merchants').doc('u1').set({
      'owner_uid': 'u1',
      'name': 'Supprimé',
      'status': 'inactive',
      'deleted_at': DateTime(2026, 1, 1),
      'subscription_plan': 'premium',
    });
    final result = await repo.createMerchantAndLinkUser(
      merchant: _wizardMerchant(),
      userId: 'u1',
    );
    expect(result.isRight, isTrue);
    final shop = (await db.collection('merchants').doc('u1').get()).data()!;
    expect(shop['name'], 'Nouveau Nom');
    expect(shop.containsKey('deleted_at'), isFalse);
  });

  test('onboardingFieldsForExistingMerchant drops status / plan / null logo',
      () {
    final out = onboardingFieldsForExistingMerchant({
      'name': 'X',
      'status': 'inactive',
      'subscription_plan': 'free',
      'logo_url': null,
      'banner_url': 'https://cdn/b.png',
      'created_at': 'ts',
    });
    expect(out.keys, unorderedEquals(['name', 'banner_url']));
  });

  test('client creating a shop elsewhere keeps their own home city; the shop '
      'city is added to Découvrir cities', () async {
    await db.collection('users').doc('u1').set({
      'roles': {'client': true},
      'onboarding': {'client': 'completed'},
      'city': 'Héricourt',
      'cities': ['Héricourt'],
    });
    final result = await repo.createMerchantAndLinkUser(
      merchant: _wizardMerchant(), // shop in Montbéliard
      userId: 'u1',
    );
    expect(result.isRight, isTrue);
    final user = (await db.collection('users').doc('u1').get()).data()!;
    expect(user['city'], 'Héricourt', reason: 'personal city not replaced');
    expect(user['cities'], containsAll(['Héricourt', 'Montbéliard']));
  });

  test('merchant without a personal city: shop city becomes their city',
      () async {
    final result = await repo.createMerchantAndLinkUser(
      merchant: _wizardMerchant(),
      userId: 'u1',
    );
    expect(result.isRight, isTrue);
    final user = (await db.collection('users').doc('u1').get()).data()!;
    expect(user['city'], 'Montbéliard');
  });
}
