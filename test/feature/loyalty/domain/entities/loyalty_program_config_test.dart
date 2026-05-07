// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ─────────────────────────────────────────────────────────────────────────
  group('LoyaltyProgramConfig.initial', () {
    test('programEnabled defaults to false', () {
      expect(LoyaltyProgramConfig.initial().programEnabled, isFalse);
    });

    test('triggerType defaults to visitCount', () {
      expect(LoyaltyProgramConfig.initial().triggerType,
          LoyaltyTriggerType.visitCount);
    });

    test('visitsRequired defaults to 10', () {
      expect(LoyaltyProgramConfig.initial().visitsRequired, 10);
    });

    test('passageValidation defaults to automatic', () {
      expect(LoyaltyProgramConfig.initial().passageValidation,
          LoyaltyPassageValidation.automatic);
    });
  });

  group('LoyaltyProgramConfig.fallbackFromFlags', () {
    test('loyaltyEnabled=true → programEnabled=true', () {
      final cfg =
          LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
      expect(cfg.programEnabled, isTrue);
    });

    test('loyaltyEnabled=false → programEnabled=false', () {
      final cfg =
          LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: false);
      expect(cfg.programEnabled, isFalse);
    });

    test('all other fields remain at initial defaults', () {
      final cfg =
          LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
      expect(cfg.triggerType, LoyaltyTriggerType.visitCount);
      expect(cfg.visitsRequired, 10);
      expect(cfg.passageValidation, LoyaltyPassageValidation.automatic);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // clientMustEnterPurchaseAmount
  // ─────────────────────────────────────────────────────────────────────────
  group('clientMustEnterPurchaseAmount', () {
    test('visitCount + purchaseVoucher → false', () {
      const cfg = LoyaltyProgramConfig(
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.purchaseVoucher,
      );
      expect(cfg.clientMustEnterPurchaseAmount, isFalse);
    });

    test('purchaseTotal trigger → true regardless of reward kind', () {
      const cfg = LoyaltyProgramConfig(
        triggerType: LoyaltyTriggerType.purchaseTotal,
        rewardKind: LoyaltyRewardKind.discountPercent,
      );
      expect(cfg.clientMustEnterPurchaseAmount, isTrue);
    });

    test('loyaltyPoints reward → true regardless of trigger', () {
      const cfg = LoyaltyProgramConfig(
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.loyaltyPoints,
      );
      expect(cfg.clientMustEnterPurchaseAmount, isTrue);
    });

    test('purchaseTotal + loyaltyPoints → true (both conditions true)', () {
      const cfg = LoyaltyProgramConfig(
        triggerType: LoyaltyTriggerType.purchaseTotal,
        rewardKind: LoyaltyRewardKind.loyaltyPoints,
      );
      expect(cfg.clientMustEnterPurchaseAmount, isTrue);
    });

    test('freeProduct reward + visitCount → false', () {
      const cfg = LoyaltyProgramConfig(
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.freeProduct,
      );
      expect(cfg.clientMustEnterPurchaseAmount, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // effectiveAskClientPurchaseAmount
  // ─────────────────────────────────────────────────────────────────────────
  group('effectiveAskClientPurchaseAmount', () {
    test('false when neither mandatory nor optional', () {
      const cfg = LoyaltyProgramConfig(
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.purchaseVoucher,
        optionalAskClientPurchaseAmount: false,
      );
      expect(cfg.effectiveAskClientPurchaseAmount, isFalse);
    });

    test('true when clientMustEnterPurchaseAmount is true', () {
      const cfg = LoyaltyProgramConfig(
        triggerType: LoyaltyTriggerType.purchaseTotal,
        optionalAskClientPurchaseAmount: false,
      );
      expect(cfg.effectiveAskClientPurchaseAmount, isTrue);
    });

    test('true when optionalAskClientPurchaseAmount is true', () {
      const cfg = LoyaltyProgramConfig(
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.purchaseVoucher,
        optionalAskClientPurchaseAmount: true,
      );
      expect(cfg.effectiveAskClientPurchaseAmount, isTrue);
    });

    test('true when both mandatory and optional are true', () {
      const cfg = LoyaltyProgramConfig(
        triggerType: LoyaltyTriggerType.purchaseTotal,
        rewardKind: LoyaltyRewardKind.loyaltyPoints,
        optionalAskClientPurchaseAmount: true,
      );
      expect(cfg.effectiveAskClientPurchaseAmount, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // clientSummaryText
  // ─────────────────────────────────────────────────────────────────────────
  group('clientSummaryText', () {
    test('programEnabled=false → mentions not activated', () {
      const cfg = LoyaltyProgramConfig(programEnabled: false);
      expect(cfg.clientSummaryText, contains('pas activé'));
    });

    test('visitCount + purchaseVoucher (%) → mentions passages and %', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 8,
        rewardKind: LoyaltyRewardKind.purchaseVoucher,
        purchaseVoucherUsesPercent: true,
        purchaseVoucherValue: 15,
      );
      final text = cfg.clientSummaryText;
      expect(text, contains('15'));
      expect(text, contains('%'));
      expect(text, contains('8'));
      expect(text, contains('passages'));
    });

    test('visitCount + purchaseVoucher (fixed €) → mentions € amount', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 10,
        rewardKind: LoyaltyRewardKind.purchaseVoucher,
        purchaseVoucherUsesPercent: false,
        purchaseVoucherValue: 20,
      );
      final text = cfg.clientSummaryText;
      expect(text, contains('20'));
      expect(text, contains('€'));
    });

    test('purchaseTotal trigger → mentions € cumulés', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
        cumulativeSpendRequiredEuros: 200,
        rewardKind: LoyaltyRewardKind.discountPercent,
        discountNextPurchasePercent: 10,
      );
      final text = cfg.clientSummaryText;
      expect(text, contains('200'));
      expect(text, contains('cumulés'));
    });

    test('discountPercent reward → mentions remise', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.discountPercent,
        discountNextPurchasePercent: 20,
      );
      expect(cfg.clientSummaryText, contains('Remise'));
      expect(cfg.clientSummaryText, contains('20'));
    });

    test('freeProduct with label → shows label', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.freeProduct,
        freeProductSummaryLabel: 'café offert',
      );
      expect(cfg.clientSummaryText, contains('café offert'));
    });

    test('freeProduct without label → generic "Produit offert"', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.freeProduct,
      );
      expect(cfg.clientSummaryText, contains('Produit offert'));
    });

    test('loyaltyPoints reward → mentions points and pointsPerEuro', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.loyaltyPoints,
        pointsPerEuro: 2,
      );
      final text = cfg.clientSummaryText;
      expect(text, contains('Points'));
      expect(text, contains('2'));
    });

    test('minimum per visit enabled → mentions minimum in text', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        rewardKind: LoyaltyRewardKind.purchaseVoucher,
        minimumPerVisitEnabled: true,
        minimumPerVisitEuros: 30,
      );
      expect(cfg.clientSummaryText, contains('30'));
      expect(cfg.clientSummaryText, contains('supérieurs'));
    });

    test('minimum disabled → no minimum text', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        minimumPerVisitEnabled: false,
        minimumPerVisitEuros: 50,
      );
      expect(cfg.clientSummaryText, isNot(contains('supérieurs')));
    });

    test('reward validity enabled → mentions jours', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        rewardValidityEnabled: true,
        rewardValidityDays: 30,
      );
      expect(cfg.clientSummaryText, contains('30'));
      expect(cfg.clientSummaryText, contains('jours'));
    });

    test('reward validity disabled → no validity text', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        rewardValidityEnabled: false,
        rewardValidityDays: 30,
      );
      expect(cfg.clientSummaryText, isNot(contains('jours')));
    });

    test('manual passageValidation → mentions "manuelle"', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        passageValidation: LoyaltyPassageValidation.manual,
      );
      expect(cfg.clientSummaryText, contains('manuelle'));
    });

    test('automatic passageValidation → mentions "automatique"', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        passageValidation: LoyaltyPassageValidation.automatic,
      );
      expect(cfg.clientSummaryText, contains('automatique'));
    });

    test('effectiveAskClientPurchaseAmount=true → mentions montant', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
      );
      expect(cfg.clientSummaryText, contains('montant'));
    });

    test('summary text is non-empty for any enabled program', () {
      for (final kind in LoyaltyRewardKind.values) {
        for (final trigger in LoyaltyTriggerType.values) {
          final cfg = LoyaltyProgramConfig(
            programEnabled: true,
            rewardKind: kind,
            triggerType: trigger,
          );
          expect(cfg.clientSummaryText, isNotEmpty,
              reason: 'Empty for $kind + $trigger');
        }
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // _formatNum (via clientSummaryText)
  // ─────────────────────────────────────────────────────────────────────────
  group('_formatNum precision', () {
    test('integer value formats without decimal', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 5,
        rewardKind: LoyaltyRewardKind.purchaseVoucher,
        purchaseVoucherUsesPercent: true,
        purchaseVoucherValue: 10,
      );
      expect(cfg.clientSummaryText, contains('10'));
      expect(cfg.clientSummaryText, isNot(contains('10.0')));
    });

    test('non-integer value formats with 1 decimal', () {
      const cfg = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
        cumulativeSpendRequiredEuros: 99.5,
        rewardKind: LoyaltyRewardKind.discountPercent,
        discountNextPurchasePercent: 5,
      );
      expect(cfg.clientSummaryText, contains('99.5'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // copyWith
  // ─────────────────────────────────────────────────────────────────────────
  group('LoyaltyProgramConfig.copyWith', () {
    test('copyWith preserves unchanged fields', () {
      const original = LoyaltyProgramConfig(
        programEnabled: true,
        visitsRequired: 8,
        rewardKind: LoyaltyRewardKind.freeProduct,
        freeProductSummaryLabel: 'café',
      );
      final copy = original.copyWith(visitsRequired: 12);
      expect(copy.programEnabled, isTrue);
      expect(copy.visitsRequired, 12);
      expect(copy.rewardKind, LoyaltyRewardKind.freeProduct);
      expect(copy.freeProductSummaryLabel, 'café');
    });

    test('copyWith changes only specified field', () {
      const original = LoyaltyProgramConfig(programEnabled: false);
      final copy = original.copyWith(programEnabled: true);
      expect(copy.programEnabled, isTrue);
      expect(copy.triggerType, original.triggerType);
    });

    test('clearFreeProductSummaryLabel=true nullifies label', () {
      const original = LoyaltyProgramConfig(
        rewardKind: LoyaltyRewardKind.freeProduct,
        freeProductSummaryLabel: 'café',
      );
      final copy = original.copyWith(clearFreeProductSummaryLabel: true);
      expect(copy.freeProductSummaryLabel, isNull);
    });

    test('copyWith does not mutate original', () {
      const original = LoyaltyProgramConfig(programEnabled: false);
      original.copyWith(programEnabled: true);
      expect(original.programEnabled, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Equatable
  // ─────────────────────────────────────────────────────────────────────────
  group('LoyaltyProgramConfig Equatable', () {
    test('two identical instances are equal', () {
      const a = LoyaltyProgramConfig(programEnabled: true, visitsRequired: 5);
      const b = LoyaltyProgramConfig(programEnabled: true, visitsRequired: 5);
      expect(a, b);
    });

    test('different visitsRequired → not equal', () {
      const a = LoyaltyProgramConfig(visitsRequired: 5);
      const b = LoyaltyProgramConfig(visitsRequired: 10);
      expect(a, isNot(b));
    });

    test('different programEnabled → not equal', () {
      const a = LoyaltyProgramConfig(programEnabled: true);
      const b = LoyaltyProgramConfig(programEnabled: false);
      expect(a, isNot(b));
    });

    test('props contains all 16 fields', () {
      const cfg = LoyaltyProgramConfig();
      expect(cfg.props.length, 16);
    });
  });
}
