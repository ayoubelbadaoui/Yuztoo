import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_list/domain/entities/merchant_client_row.dart';

void main() {
  group('MerchantClientRow — segment', () {
    // Segment is driven by validatedPassages + recency, NOT heartLevel.

    test('validatedPassages >= 10 + recent → VIP', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        validatedPassages: 10,
        lastVisitAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(row.segment, ClientSegment.vip);
    });

    test('validatedPassages > 10 → also VIP', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        validatedPassages: 15,
        lastVisitAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(row.segment, ClientSegment.vip);
    });

    test('validatedPassages >= 3 + recent → Habitué', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        validatedPassages: 3,
        lastVisitAt: DateTime.now().subtract(const Duration(days: 20)),
      );
      expect(row.segment, ClientSegment.habitue);
    });

    test('validatedPassages 0 + followed 3 days ago → Nouveau', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        followedAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(row.segment, ClientSegment.nouveau);
    });

    test('validatedPassages 0 + followed 13 days ago → Nouveau', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        followedAt: DateTime.now().subtract(const Duration(days: 13)),
      );
      expect(row.segment, ClientSegment.nouveau);
    });

    test('validatedPassages 0 + followed 30 days ago → Nouveau (< 60 days)',
        () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        followedAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(row.segment, ClientSegment.nouveau);
    });

    test('no visits, no lastVisitAt, no followedAt → Inactif (daysSince=999)',
        () {
      const row = MerchantClientRow(clientUid: 'u1');
      expect(row.segment, ClientSegment.inactif);
    });

    test('lastVisitAt > 60 days ago → Inactif regardless of passages', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        validatedPassages: 8,
        lastVisitAt: DateTime.now().subtract(const Duration(days: 61)),
      );
      expect(row.segment, ClientSegment.inactif);
    });

    test('validatedPassages 0 + recent follow → Nouveau', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        followedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(row.segment, ClientSegment.nouveau);
    });
  });

  group('MerchantClientRow — displayLabel', () {
    test('non-empty displayName is returned as-is', () {
      const row = MerchantClientRow(
        clientUid: 'abc123',
        displayName: 'Sophie Martin',
      );
      expect(row.displayLabel, 'Sophie Martin');
    });

    test('empty displayName falls back to last 8 chars of clientUid', () {
      const row = MerchantClientRow(
        clientUid: 'uid_1234abcd',
        displayName: '',
      );
      expect(row.displayLabel, '…1234abcd');
    });

    test('null displayName falls back to last 8 chars of clientUid', () {
      const row = MerchantClientRow(clientUid: 'uid_1234abcd');
      expect(row.displayLabel, '…1234abcd');
    });

    test('short clientUid (≤8 chars) shows entire uid', () {
      const row = MerchantClientRow(clientUid: 'short');
      // length 5 ≤ 8 → substring(0) = 'short'
      expect(row.displayLabel, '…short');
    });

    test('clientUid exactly 8 chars', () {
      const row = MerchantClientRow(clientUid: '12345678');
      expect(row.displayLabel, '…12345678');
    });
  });

  group('MerchantClientRow — Equatable', () {
    test('two identical rows are equal', () {
      final a = MerchantClientRow(
        clientUid: 'u1',
        displayName: 'Alice',
        city: 'Paris',
        followedAt: DateTime(2024, 1, 1),
        heartLevel: 2,
      );
      final b = MerchantClientRow(
        clientUid: 'u1',
        displayName: 'Alice',
        city: 'Paris',
        followedAt: DateTime(2024, 1, 1),
        heartLevel: 2,
      );
      expect(a, b);
    });

    test('different clientUid → not equal', () {
      const a = MerchantClientRow(clientUid: 'u1');
      const b = MerchantClientRow(clientUid: 'u2');
      expect(a, isNot(b));
    });
  });

  group('ClientSegment labels', () {
    test('all segments have correct French labels', () {
      expect(ClientSegment.nouveau.label, 'Nouveau');
      expect(ClientSegment.vip.label, 'VIP');
      expect(ClientSegment.habitue.label, 'Habitué');
      expect(ClientSegment.abonne.label, 'Abonné');
    });
  });
}
