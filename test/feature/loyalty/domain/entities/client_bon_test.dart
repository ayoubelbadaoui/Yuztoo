import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_bon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ClientBon — pure entity tests. Lock the (now, valid_until_at) → status
// mapping so a future tweak to the 3-day "expire bientôt" window can't
// silently drift away from the scheduled CF that sends the matching push.
// ─────────────────────────────────────────────────────────────────────────────

ClientBon _bon({
  DateTime? validUntil,
  DateTime? redeemed,
  ClientBonKind kind = ClientBonKind.milestone,
}) {
  return ClientBon(
    id: 'b1',
    merchantId: 'm1',
    kind: kind,
    description: 'desc',
    issuedAt: DateTime(2026, 1, 1),
    validUntilAt: validUntil,
    redeemedAt: redeemed,
  );
}

void main() {
  final now = DateTime(2026, 5, 7, 12);

  group('statusAt', () {
    test('redeemed bon is redeemed regardless of dates', () {
      final b = _bon(
          validUntil: now.add(const Duration(days: 30)),
          redeemed: now.subtract(const Duration(days: 1)));
      expect(b.statusAt(now), ClientBonStatus.redeemed);
    });

    test('null validUntilAt is active (evergreen)', () {
      final b = _bon();
      expect(b.statusAt(now), ClientBonStatus.active);
    });

    test('valid in the past is expired', () {
      final b = _bon(validUntil: now.subtract(const Duration(days: 1)));
      expect(b.statusAt(now), ClientBonStatus.expired);
    });

    test('valid exactly now is expired (>= boundary)', () {
      final b = _bon(validUntil: now);
      expect(b.statusAt(now), ClientBonStatus.expired);
    });

    test('valid in 3 days is expiringSoon (boundary inclusive)', () {
      final b = _bon(validUntil: now.add(const Duration(days: 3)));
      expect(b.statusAt(now), ClientBonStatus.expiringSoon);
    });

    test('valid in 4 days is active', () {
      // 4 full days remaining → outside the "expire bientôt" window.
      final b = _bon(validUntil: now.add(const Duration(days: 4, hours: 1)));
      expect(b.statusAt(now), ClientBonStatus.active);
    });

    test('valid in <1 day still expiringSoon (e.g. 6 hours)', () {
      final b = _bon(validUntil: now.add(const Duration(hours: 6)));
      expect(b.statusAt(now), ClientBonStatus.expiringSoon);
    });
  });

  group('daysLeftAt', () {
    test('returns null for evergreen', () {
      expect(_bon().daysLeftAt(now), isNull);
    });

    test('returns floor of remaining whole days', () {
      // 3 days, 6 hours → integer-truncated to 3.
      final b = _bon(validUntil: now.add(const Duration(days: 3, hours: 6)));
      expect(b.daysLeftAt(now), 3);
    });

    test('returns 0 (not negative) when already expired', () {
      final b = _bon(validUntil: now.subtract(const Duration(days: 5)));
      expect(b.daysLeftAt(now), 0);
    });
  });
}
