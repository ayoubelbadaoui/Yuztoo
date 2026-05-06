import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/promotion_segment_matching.dart';

void main() {
  group('promotionSegmentMatchesTarget', () {
    test('exact segment match', () {
      expect(promotionSegmentMatchesTarget('vip', ['vip']), isTrue);
      expect(promotionSegmentMatchesTarget('habitue', ['habitue']), isTrue);
    });

    test('soutien matches vip and habitue only', () {
      expect(promotionSegmentMatchesTarget('vip', ['soutien']), isTrue);
      expect(promotionSegmentMatchesTarget('habitue', ['soutien']), isTrue);
      expect(promotionSegmentMatchesTarget('nouveau', ['soutien']), isFalse);
      expect(promotionSegmentMatchesTarget('inactif', ['soutien']), isFalse);
    });

    test('empty targets never matches', () {
      expect(promotionSegmentMatchesTarget('vip', []), isFalse);
    });

    test('multiple targets OR semantics', () {
      expect(promotionSegmentMatchesTarget('nouveau', ['vip', 'nouveau']), isTrue);
      expect(promotionSegmentMatchesTarget('vip', ['vip', 'habitue']), isTrue);
    });
  });
}
