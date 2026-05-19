import '../../merchant/domain/entities/loyalty_program_config.dart';

/// Client Fidélité feed filters — one tab per [LoyaltyRewardKind].
enum LoyaltyRewardCategory {
  purchaseVoucher,
  discountPercent,
  freeProduct,
  loyaltyPoints,
}

/// All four categories, stable tab order on the client Fidélité screen.
const List<LoyaltyRewardCategory> kLoyaltyRewardCategories =
    LoyaltyRewardCategory.values;

extension LoyaltyRewardCategoryLabels on LoyaltyRewardCategory {
  String get labelFr {
    switch (this) {
      case LoyaltyRewardCategory.purchaseVoucher:
        return 'Bon d\'achat';
      case LoyaltyRewardCategory.discountPercent:
        return 'Remise';
      case LoyaltyRewardCategory.freeProduct:
        return 'Produit offert';
      case LoyaltyRewardCategory.loyaltyPoints:
        return 'Points';
    }
  }

  LoyaltyRewardKind get rewardKind {
    switch (this) {
      case LoyaltyRewardCategory.purchaseVoucher:
        return LoyaltyRewardKind.purchaseVoucher;
      case LoyaltyRewardCategory.discountPercent:
        return LoyaltyRewardKind.discountPercent;
      case LoyaltyRewardCategory.freeProduct:
        return LoyaltyRewardKind.freeProduct;
      case LoyaltyRewardCategory.loyaltyPoints:
        return LoyaltyRewardKind.loyaltyPoints;
    }
  }

  bool matchesConfig(LoyaltyProgramConfig config) =>
      config.rewardKind == rewardKind;

  /// Short empty-state line under each filter tab when count is zero.
  String get notSubscribedHintFr =>
      'Pas encore inscrit à ce type de programme';
}

LoyaltyRewardCategory loyaltyRewardCategoryFromKind(LoyaltyRewardKind kind) {
  switch (kind) {
    case LoyaltyRewardKind.purchaseVoucher:
      return LoyaltyRewardCategory.purchaseVoucher;
    case LoyaltyRewardKind.discountPercent:
      return LoyaltyRewardCategory.discountPercent;
    case LoyaltyRewardKind.freeProduct:
      return LoyaltyRewardCategory.freeProduct;
    case LoyaltyRewardKind.loyaltyPoints:
      return LoyaltyRewardCategory.loyaltyPoints;
  }
}

int countEntriesForCategory(
  LoyaltyRewardCategory category,
  Iterable<LoyaltyProgramConfig> configs,
) =>
    configs.where(category.matchesConfig).length;
