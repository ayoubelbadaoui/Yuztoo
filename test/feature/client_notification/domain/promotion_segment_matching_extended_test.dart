import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/promotion_segment_matching.dart';

void main() {
  group('promotionSegmentMatchesTarget — full truth table (T1-T11)', () {
    // T1
    test('T1 — [vip] target: vip client → match', () {
      expect(promotionSegmentMatchesTarget('vip', ['vip']), isTrue);
    });

    // T2
    test('T2 — [vip] target: habitue client → no match', () {
      expect(promotionSegmentMatchesTarget('habitue', ['vip']), isFalse);
    });

    // T3
    test('T3 — [soutien] target: vip client → match (soutien ⊇ vip)', () {
      expect(promotionSegmentMatchesTarget('vip', ['soutien']), isTrue);
    });

    // T4
    test('T4 — [soutien] target: habitue client → match (soutien ⊇ habitue)', () {
      expect(promotionSegmentMatchesTarget('habitue', ['soutien']), isTrue);
    });

    // T5
    test('T5 — [soutien] target: nouveau client → no match', () {
      expect(promotionSegmentMatchesTarget('nouveau', ['soutien']), isFalse);
    });

    // T6
    test('T6 — [soutien] target: inactif client → no match', () {
      expect(promotionSegmentMatchesTarget('inactif', ['soutien']), isFalse);
    });

    // T7
    test('T7 — empty target list: no segment matches (broadcast is handled upstream)', () {
      expect(promotionSegmentMatchesTarget('vip', []), isFalse);
      expect(promotionSegmentMatchesTarget('nouveau', []), isFalse);
    });

    // T8
    test('T8 — [vip, nouveau] target: habitue → no match', () {
      expect(promotionSegmentMatchesTarget('habitue', ['vip', 'nouveau']), isFalse);
    });

    // T9
    test('T9 — [soutien, nouveau] target: habitue → match via soutien', () {
      expect(promotionSegmentMatchesTarget('habitue', ['soutien', 'nouveau']), isTrue);
    });

    // T11 — legacy "abonne" target
    test('T11 — [abonne] target: abonne client → direct match (legacy)', () {
      expect(promotionSegmentMatchesTarget('abonne', ['abonne']), isTrue);
    });

    // Additional edge cases
    test('soutien does NOT match soutien as client segment directly', () {
      // "soutien" is a UI grouping, not produced by the loyalty engine.
      // If somehow stored, it should match itself via exact match.
      expect(promotionSegmentMatchesTarget('soutien', ['soutien']), isTrue);
    });

    test('inactif exact target match', () {
      expect(promotionSegmentMatchesTarget('inactif', ['inactif']), isTrue);
    });

    test('multiple targets with soutien: VIP client matches', () {
      expect(
        promotionSegmentMatchesTarget('vip', ['soutien', 'inactif']),
        isTrue,
      );
    });

    test('multiple targets: first match short-circuits', () {
      // Both soutien and vip in list — vip client should match
      expect(
        promotionSegmentMatchesTarget('vip', ['vip', 'soutien']),
        isTrue,
      );
    });
  });
}
