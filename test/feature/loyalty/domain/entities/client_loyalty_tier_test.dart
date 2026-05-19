import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // ClientLoyaltyTier.fromPassages — boundary conditions
  // ─────────────────────────────────────────────────────────────────────────
  group('ClientLoyaltyTier.fromPassages', () {
    // ── nouveau tier (0–2) ───────────────────────────────────────────────
    test('0 passages → nouveau', () {
      expect(ClientLoyaltyTier.fromPassages(0), ClientLoyaltyTier.nouveau);
    });

    test('1 passage → nouveau', () {
      expect(ClientLoyaltyTier.fromPassages(1), ClientLoyaltyTier.nouveau);
    });

    test('2 passages → nouveau', () {
      expect(ClientLoyaltyTier.fromPassages(2), ClientLoyaltyTier.nouveau);
    });

    // ── soutien tier (3–9) ───────────────────────────────────────────────
    test('3 passages → soutien (lower boundary)', () {
      expect(ClientLoyaltyTier.fromPassages(3), ClientLoyaltyTier.soutien);
    });

    test('5 passages → soutien', () {
      expect(ClientLoyaltyTier.fromPassages(5), ClientLoyaltyTier.soutien);
    });

    test('9 passages → soutien (upper boundary)', () {
      expect(ClientLoyaltyTier.fromPassages(9), ClientLoyaltyTier.soutien);
    });

    // ── habitue tier (10–19) ─────────────────────────────────────────────
    test('10 passages → habitue (lower boundary)', () {
      expect(ClientLoyaltyTier.fromPassages(10), ClientLoyaltyTier.habitue);
    });

    test('15 passages → habitue', () {
      expect(ClientLoyaltyTier.fromPassages(15), ClientLoyaltyTier.habitue);
    });

    test('19 passages → habitue (upper boundary)', () {
      expect(ClientLoyaltyTier.fromPassages(19), ClientLoyaltyTier.habitue);
    });

    // ── vip tier (20+) ───────────────────────────────────────────────────
    test('20 passages → vip (lower boundary)', () {
      expect(ClientLoyaltyTier.fromPassages(20), ClientLoyaltyTier.vip);
    });

    test('50 passages → vip', () {
      expect(ClientLoyaltyTier.fromPassages(50), ClientLoyaltyTier.vip);
    });

    test('1000 passages → vip (large count)', () {
      expect(ClientLoyaltyTier.fromPassages(1000), ClientLoyaltyTier.vip);
    });

    // ── Negative guard ───────────────────────────────────────────────────
    test('negative passages → nouveau (defensive: treated as < 3)', () {
      // The function has no explicit negative guard; negative < 3 → nouveau.
      expect(ClientLoyaltyTier.fromPassages(-1), ClientLoyaltyTier.nouveau);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ClientLoyaltyTier.label — French strings
  // ─────────────────────────────────────────────────────────────────────────
  group('ClientLoyaltyTier.label', () {
    test('nouveau label', () {
      expect(ClientLoyaltyTier.nouveau.label, 'Nouveau');
    });

    test('soutien label', () {
      expect(ClientLoyaltyTier.soutien.label, 'Soutien');
    });

    test('habitue label', () {
      expect(ClientLoyaltyTier.habitue.label, 'Habitué');
    });

    test('vip label', () {
      expect(ClientLoyaltyTier.vip.label, 'VIP');
    });

    test('all tiers have non-empty labels', () {
      for (final tier in ClientLoyaltyTier.values) {
        expect(tier.label, isNotEmpty, reason: '${tier.name} label is empty');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Tier ordering consistency
  // ─────────────────────────────────────────────────────────────────────────
  group('ClientLoyaltyTier ordering', () {
    test('tier sequence: nouveau < soutien < habitue < vip', () {
      // Ensures the enum is declared in ascending order (important for
      // any code that uses `index` comparisons).
      final values = ClientLoyaltyTier.values;
      expect(values[0], ClientLoyaltyTier.nouveau);
      expect(values[1], ClientLoyaltyTier.soutien);
      expect(values[2], ClientLoyaltyTier.habitue);
      expect(values[3], ClientLoyaltyTier.vip);
    });

    test('fromPassages yields same tier as manual threshold for boundaries', () {
      final boundaries = {
        0: ClientLoyaltyTier.nouveau,
        2: ClientLoyaltyTier.nouveau,
        3: ClientLoyaltyTier.soutien,
        9: ClientLoyaltyTier.soutien,
        10: ClientLoyaltyTier.habitue,
        19: ClientLoyaltyTier.habitue,
        20: ClientLoyaltyTier.vip,
      };
      for (final entry in boundaries.entries) {
        expect(
          ClientLoyaltyTier.fromPassages(entry.key),
          entry.value,
          reason: '${entry.key} passages should be ${entry.value.name}',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ClientMerchantLoyaltyProgress + tier integration
  // ─────────────────────────────────────────────────────────────────────────
  group('ClientMerchantLoyaltyProgress + ClientLoyaltyTier integration', () {
    test('empty progress → nouveau tier', () {
      const p = ClientMerchantLoyaltyProgress.empty();
      expect(ClientLoyaltyTier.fromPassages(p.validatedPassages),
          ClientLoyaltyTier.nouveau);
    });

    test('9-passage progress → soutien tier', () {
      const p = ClientMerchantLoyaltyProgress(
        validatedPassages: 9,
        cumulativeSpendEuros: 0,
      );
      expect(ClientLoyaltyTier.fromPassages(p.validatedPassages),
          ClientLoyaltyTier.soutien);
    });

    test('isFirstVisit flag independent of tier', () {
      const p = ClientMerchantLoyaltyProgress(
        validatedPassages: 25,
        cumulativeSpendEuros: 500,
        isFirstVisit: true,
      );
      expect(ClientLoyaltyTier.fromPassages(p.validatedPassages),
          ClientLoyaltyTier.vip);
      expect(p.isFirstVisit, isTrue);
    });
  });
}
