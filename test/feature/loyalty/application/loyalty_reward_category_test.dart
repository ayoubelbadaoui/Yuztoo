import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/loyalty_reward_category.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';

void main() {
  group('LoyaltyRewardCategory', () {
    test('matchesConfig uses real rewardKind on program config', () {
      const voucher = LoyaltyProgramConfig(
        rewardKind: LoyaltyRewardKind.purchaseVoucher,
      );
      const remise = LoyaltyProgramConfig(
        rewardKind: LoyaltyRewardKind.discountPercent,
      );
      expect(
        LoyaltyRewardCategory.purchaseVoucher.matchesConfig(voucher),
        isTrue,
      );
      expect(
        LoyaltyRewardCategory.discountPercent.matchesConfig(remise),
        isTrue,
      );
      expect(
        LoyaltyRewardCategory.purchaseVoucher.matchesConfig(remise),
        isFalse,
      );
    });

    test('fromRewardKind round-trips all four kinds', () {
      for (final kind in LoyaltyRewardKind.values) {
        final cat = loyaltyRewardCategoryFromKind(kind);
        expect(cat.rewardKind, kind);
      }
    });

    test('countEntriesForCategory counts enrolled programs', () {
      const configs = [
        LoyaltyProgramConfig(rewardKind: LoyaltyRewardKind.freeProduct),
        LoyaltyProgramConfig(rewardKind: LoyaltyRewardKind.freeProduct),
        LoyaltyProgramConfig(rewardKind: LoyaltyRewardKind.loyaltyPoints),
      ];
      expect(
        countEntriesForCategory(
          LoyaltyRewardCategory.freeProduct,
          configs,
        ),
        2,
      );
      expect(
        countEntriesForCategory(
          LoyaltyRewardCategory.purchaseVoucher,
          configs,
        ),
        0,
      );
    });
  });
}
