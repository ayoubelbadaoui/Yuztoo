import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/client_loyalty_providers.dart'
    show loyaltyProgramsDiffer;
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';

void main() {
  group('loyaltyProgramsDiffer (enrolled program)', () {
    test('detects reward kind change', () {
      const a = LoyaltyProgramConfig(
        programEnabled: true,
        rewardKind: LoyaltyRewardKind.purchaseVoucher,
      );
      const b = LoyaltyProgramConfig(
        programEnabled: true,
        rewardKind: LoyaltyRewardKind.discountPercent,
      );
      expect(loyaltyProgramsDiffer(a, b), isTrue);
    });

    test('ignores passage validation mode', () {
      const a = LoyaltyProgramConfig(
        programEnabled: true,
        passageValidation: LoyaltyPassageValidation.automatic,
      );
      const b = LoyaltyProgramConfig(
        programEnabled: true,
        passageValidation: LoyaltyPassageValidation.manual,
      );
      expect(loyaltyProgramsDiffer(a, b), isFalse);
    });

    test('detects trigger type change', () {
      const a = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
      );
      const b = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
      );
      expect(loyaltyProgramsDiffer(a, b), isTrue);
    });

    test('detects visits required change', () {
      const a = LoyaltyProgramConfig(
        programEnabled: true,
        visitsRequired: 10,
      );
      const b = LoyaltyProgramConfig(
        programEnabled: true,
        visitsRequired: 15,
      );
      expect(loyaltyProgramsDiffer(a, b), isTrue);
    });

    test('detects spend threshold change', () {
      const a = LoyaltyProgramConfig(
        programEnabled: true,
        cumulativeSpendRequiredEuros: 100,
      );
      const b = LoyaltyProgramConfig(
        programEnabled: true,
        cumulativeSpendRequiredEuros: 150,
      );
      expect(loyaltyProgramsDiffer(a, b), isTrue);
    });
  });
}
