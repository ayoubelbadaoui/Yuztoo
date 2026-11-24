import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/utils/city_match.dart';
import 'package:flutter_yuztoo/feature/merchant/infrastructure/firestore_merchant_repository.dart';

Map<String, dynamic> _shop(String name, String city, DateTime updatedAt) => {
      'owner_uid': 'owner-$name',
      'name': name,
      'email': 'a@b.fr',
      'phone': '',
      'city': city,
      'city_keys': merchantCityKeys(city),
      'status': 'active',
      'updated_at': Timestamp.fromDate(updatedAt),
    };

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreMerchantRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreMerchantRepository(firestore: db);
  });

  Future<List<String>> names(List<String> cities, {int limit = 150}) async {
    final result = await repo.listMerchants(limit: limit, cityFilters: cities);
    return result.fold((_) => <String>[], (l) => [for (final m in l) m.name]);
  }

  // Regression: a Héricourt client saw nothing because Découvrir read only the
  // 200 most recently updated shops of the whole base, then filtered by city.
  test('an old Héricourt shop is found behind 250 newer Belfort shops',
      () async {
    await db
        .collection('merchants')
        .doc('hericourt-old')
        .set(_shop('Boulangerie Héricourt', 'Héricourt', DateTime(2025, 1)));
    for (var i = 0; i < 250; i++) {
      await db
          .collection('merchants')
          .doc('belfort-$i')
          .set(_shop('Belfort $i', 'Belfort', DateTime(2026, 11, 1, 0, i)));
    }

    expect(await names(['Héricourt']), ['Boulangerie Héricourt']);
  });

  test('Héricourt, Montbéliard and Belfort stay separate', () async {
    await db
        .collection('merchants')
        .doc('h')
        .set(_shop('H', 'Hericourt', DateTime(2026, 1)));
    await db
        .collection('merchants')
        .doc('m')
        .set(_shop('M', 'Montbéliard', DateTime(2026, 2)));
    await db
        .collection('merchants')
        .doc('b')
        .set(_shop('B', 'Belfort', DateTime(2026, 3)));

    expect(await names(['Héricourt', 'Brevilliers']), ['H']);
    expect(await names(['Montbéliard']), ['M']);
  });

  test('more than 30 communes are queried in chunks, newest first', () async {
    final communes = [for (var i = 0; i < 70; i++) 'Village $i'];
    await db
        .collection('merchants')
        .doc('v5')
        .set(_shop('V5', 'Village 5', DateTime(2026, 1)));
    await db
        .collection('merchants')
        .doc('v65')
        .set(_shop('V65', 'Village 65', DateTime(2026, 6)));

    expect(await names(communes), ['V65', 'V5']);
  });

  test('inactive shops are excluded', () async {
    await db.collection('merchants').doc('off').set({
      ..._shop('Off', 'Héricourt', DateTime(2026, 1)),
      'status': 'inactive',
    });
    expect(await names(['Héricourt']), isEmpty);
  });

  test('shops without city_keys still match until the backfill has run',
      () async {
    final legacy = _shop('Legacy', 'Héricourt', DateTime(2026, 1))
      ..remove('city_keys');
    await db.collection('merchants').doc('legacy').set(legacy);
    expect(await names(['Héricourt']), ['Legacy']);
  });
}
