import 'package:equatable/equatable.dart';

/// How the loyalty reward is unlocked.
enum LoyaltyTriggerType {
  /// Count validated visits.
  visitCount,

  /// Total spend threshold (€).
  purchaseTotal,
}

/// Single reward type for the program.
enum LoyaltyRewardKind {
  purchaseVoucher,
  discountPercent,
  freeProduct,
  loyaltyPoints,
}

/// Who validates a client "passage".
enum LoyaltyPassageValidation {
  automatic,
  manual,
}

/// Loyalty settings owned by the [Merchant] aggregate (persisted on merchant doc).
///
/// Business rules such as [clientMustEnterPurchaseAmount] live in the domain layer.
class LoyaltyProgramConfig extends Equatable {
  const LoyaltyProgramConfig({
    this.programEnabled = true,
    this.triggerType = LoyaltyTriggerType.visitCount,
    this.visitsRequired = 10,
    this.cumulativeSpendRequiredEuros = 100,
    this.rewardKind = LoyaltyRewardKind.purchaseVoucher,
    this.purchaseVoucherUsesPercent = true,
    this.purchaseVoucherValue = 10,
    this.discountNextPurchasePercent = 10,
    this.freeProductSummaryLabel,
    this.pointsPerEuro = 1,
    this.minimumPerVisitEnabled = true,
    this.minimumPerVisitEuros = 50,
    this.rewardValidityEnabled = true,
    this.rewardValidityDays = 30,
    this.passageValidation = LoyaltyPassageValidation.automatic,
    this.optionalAskClientPurchaseAmount = false,
  });

  factory LoyaltyProgramConfig.initial() => const LoyaltyProgramConfig();

  /// Draft when Firestore has no `loyalty_program` yet.
  factory LoyaltyProgramConfig.fallbackFromFlags({required bool loyaltyEnabled}) {
    return LoyaltyProgramConfig.initial().copyWith(programEnabled: loyaltyEnabled);
  }

  final bool programEnabled;
  final LoyaltyTriggerType triggerType;
  final int visitsRequired;
  final double cumulativeSpendRequiredEuros;
  final LoyaltyRewardKind rewardKind;
  final bool purchaseVoucherUsesPercent;
  final double purchaseVoucherValue;
  final double discountNextPurchasePercent;
  final String? freeProductSummaryLabel;
  final double pointsPerEuro;
  final bool minimumPerVisitEnabled;
  final double? minimumPerVisitEuros;
  final bool rewardValidityEnabled;
  final int? rewardValidityDays;
  final LoyaltyPassageValidation passageValidation;
  final bool optionalAskClientPurchaseAmount;

  /// Cumul d'achats or points → client must enter purchase amount each visit.
  bool get clientMustEnterPurchaseAmount =>
      triggerType == LoyaltyTriggerType.purchaseTotal ||
      rewardKind == LoyaltyRewardKind.loyaltyPoints;

  /// Effective policy for showing amount field to the client.
  bool get effectiveAskClientPurchaseAmount =>
      clientMustEnterPurchaseAmount || optionalAskClientPurchaseAmount;

  /// Short French copy for the storefront / client preview.
  String get clientSummaryText {
    if (!programEnabled) {
      return 'Le programme de fidélité n\'est pas activé. '
          'Les clients ne verront aucune offre.';
    }

    final rewardPart = _rewardPhrase();
    final triggerPart = _triggerPhrase();
    final minPart = _minimumPhrase();
    final validityPart = _validityPhrase();
    final validationPart =
        passageValidation == LoyaltyPassageValidation.automatic
            ? 'Validation des passages : automatique.'
            : 'Validation des passages : manuelle (depuis Rappels).';
    final amountPart = effectiveAskClientPurchaseAmount
        ? 'Le client saisit le montant de l\'achat à chaque passage.'
        : '';

    return [
      '$rewardPart $triggerPart$minPart'.trim(),
      if (validityPart.isNotEmpty) validityPart,
      validationPart,
      if (amountPart.isNotEmpty) amountPart,
    ].where((s) => s.isNotEmpty).join(' ');
  }

  String _rewardPhrase() {
    switch (rewardKind) {
      case LoyaltyRewardKind.purchaseVoucher:
        if (purchaseVoucherUsesPercent) {
          final p = _formatNum(purchaseVoucherValue);
          return 'Bon d\'achat équivalent à $p % de vos dépenses';
        }
        final eur = _formatNum(purchaseVoucherValue);
        return 'Bon d\'achat de $eur €';
      case LoyaltyRewardKind.discountPercent:
        final p = _formatNum(discountNextPurchasePercent);
        return 'Remise de $p % sur le prochain achat';
      case LoyaltyRewardKind.freeProduct:
        final name = (freeProductSummaryLabel ?? '').trim();
        if (name.isEmpty) {
          return 'Produit offert';
        }
        return 'Produit offert : $name';
      case LoyaltyRewardKind.loyaltyPoints:
        final pts = _formatNum(pointsPerEuro);
        return 'Points fidélité (1 € = $pts pt)';
    }
  }

  String _triggerPhrase() {
    switch (triggerType) {
      case LoyaltyTriggerType.visitCount:
        return 'après $visitsRequired passages validés';
      case LoyaltyTriggerType.purchaseTotal:
        final eur = _formatNum(cumulativeSpendRequiredEuros);
        return 'après $eur € d\'achats cumulés';
    }
  }

  String _minimumPhrase() {
    if (!minimumPerVisitEnabled ||
        minimumPerVisitEuros == null ||
        minimumPerVisitEuros! <= 0) {
      return '';
    }
    final eur = _formatNum(minimumPerVisitEuros!);
    return ', pour des passages supérieurs à $eur €';
  }

  String _validityPhrase() {
    if (!rewardValidityEnabled ||
        rewardValidityDays == null ||
        rewardValidityDays! <= 0) {
      return '';
    }
    final days = rewardValidityDays!;
    return 'Récompense à utiliser sous $days jours.';
  }

  static String _formatNum(num n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }

  LoyaltyProgramConfig copyWith({
    bool? programEnabled,
    LoyaltyTriggerType? triggerType,
    int? visitsRequired,
    double? cumulativeSpendRequiredEuros,
    LoyaltyRewardKind? rewardKind,
    bool? purchaseVoucherUsesPercent,
    double? purchaseVoucherValue,
    double? discountNextPurchasePercent,
    String? freeProductSummaryLabel,
    bool clearFreeProductSummaryLabel = false,
    double? pointsPerEuro,
    bool? minimumPerVisitEnabled,
    double? minimumPerVisitEuros,
    bool? rewardValidityEnabled,
    int? rewardValidityDays,
    LoyaltyPassageValidation? passageValidation,
    bool? optionalAskClientPurchaseAmount,
  }) {
    return LoyaltyProgramConfig(
      programEnabled: programEnabled ?? this.programEnabled,
      triggerType: triggerType ?? this.triggerType,
      visitsRequired: visitsRequired ?? this.visitsRequired,
      cumulativeSpendRequiredEuros:
          cumulativeSpendRequiredEuros ?? this.cumulativeSpendRequiredEuros,
      rewardKind: rewardKind ?? this.rewardKind,
      purchaseVoucherUsesPercent:
          purchaseVoucherUsesPercent ?? this.purchaseVoucherUsesPercent,
      purchaseVoucherValue: purchaseVoucherValue ?? this.purchaseVoucherValue,
      discountNextPurchasePercent:
          discountNextPurchasePercent ?? this.discountNextPurchasePercent,
      freeProductSummaryLabel: clearFreeProductSummaryLabel
          ? null
          : (freeProductSummaryLabel ?? this.freeProductSummaryLabel),
      pointsPerEuro: pointsPerEuro ?? this.pointsPerEuro,
      minimumPerVisitEnabled:
          minimumPerVisitEnabled ?? this.minimumPerVisitEnabled,
      minimumPerVisitEuros: minimumPerVisitEuros ?? this.minimumPerVisitEuros,
      rewardValidityEnabled:
          rewardValidityEnabled ?? this.rewardValidityEnabled,
      rewardValidityDays: rewardValidityDays ?? this.rewardValidityDays,
      passageValidation: passageValidation ?? this.passageValidation,
      optionalAskClientPurchaseAmount: optionalAskClientPurchaseAmount ??
          this.optionalAskClientPurchaseAmount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        programEnabled,
        triggerType,
        visitsRequired,
        cumulativeSpendRequiredEuros,
        rewardKind,
        purchaseVoucherUsesPercent,
        purchaseVoucherValue,
        discountNextPurchasePercent,
        freeProductSummaryLabel,
        pointsPerEuro,
        minimumPerVisitEnabled,
        minimumPerVisitEuros,
        rewardValidityEnabled,
        rewardValidityDays,
        passageValidation,
        optionalAskClientPurchaseAmount,
      ];
}
