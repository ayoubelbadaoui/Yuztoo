import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_list/domain/entities/merchant_client_row.dart';

void main() {
  group('MerchantClientRow — segment', () {
    test('heartLevel 3 → VIP', () {
      const row = MerchantClientRow(clientUid: 'u1', heartLevel: 3);
      expect(row.segment, ClientSegment.vip);
    });

    test('heartLevel > 3 → VIP (clamped by >=3 check)', () {
      const row = MerchantClientRow(clientUid: 'u1', heartLevel: 5);
      expect(row.segment, ClientSegment.vip);
    });

    test('heartLevel 2 → Habitué', () {
      const row = MerchantClientRow(clientUid: 'u1', heartLevel: 2);
      expect(row.segment, ClientSegment.habitue);
    });

    test('heartLevel 1 + followed < 14 days ago → Nouveau', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        heartLevel: 1,
        followedAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(row.segment, ClientSegment.nouveau);
    });

    test('heartLevel 1 + followed exactly 13 days ago → Nouveau', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        heartLevel: 1,
        followedAt: DateTime.now().subtract(const Duration(days: 13)),
      );
      expect(row.segment, ClientSegment.nouveau);
    });

    test('heartLevel 1 + followed 14 days ago → Abonné (boundary, not Nouveau)',
        () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        heartLevel: 1,
        followedAt: DateTime.now().subtract(const Duration(days: 14)),
      );
      // 14 days ago: difference == 14, not < 14, so falls through to abonne
      expect(row.segment, ClientSegment.abonne);
    });

    test('heartLevel 1 + followed 30 days ago → Abonné', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        heartLevel: 1,
        followedAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(row.segment, ClientSegment.abonne);
    });

    test('heartLevel 1 + followedAt null → Abonné', () {
      const row = MerchantClientRow(clientUid: 'u1', heartLevel: 1);
      expect(row.segment, ClientSegment.abonne);
    });

    test('heartLevel 0 + recent follow → Nouveau (0 < 2 threshold)', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        heartLevel: 0,
        followedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      // heartLevel 0 < 2 and < 3, so segment falls to date check
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
