/// Fixed design-safe media slots — mirrors Sales CMS `MEDIA_SLOT_CATALOG`.
enum AppMediaSlotId {
  brandLogo('brand.logo'),
  onboardingMerchantHeroPersonal('onboarding.merchant.hero_personal'),
  onboardingMerchantHeroCommerce('onboarding.merchant.hero_commerce'),
  onboardingMerchantHeroAudience('onboarding.merchant.hero_audience'),
  onboardingMerchantHeroCity('onboarding.merchant.hero_city'),
  onboardingClientHero('onboarding.client.hero'),
  emptyLoyalty('empty.loyalty'),
  emptyPassages('empty.passages'),
  emptyPromotions('empty.promotions'),
  categoryBouche('onboarding.category.bouche'),
  categoryCommerce('onboarding.category.commerce'),
  categoryBeaute('onboarding.category.beaute'),
  categorySante('onboarding.category.sante'),
  categoryServicesParticuliers('onboarding.category.services_particuliers'),
  categoryLoisirs('onboarding.category.loisirs'),
  categoryAssociation('onboarding.category.association'),
  categoryAutre('onboarding.category.autre'),
  categoryArtisanBtp('onboarding.category.artisan_btp'),
  categoryServicesPro('onboarding.category.services_pro'),
  categoryGrossiste('onboarding.category.grossiste'),
  categoryImmobilier('onboarding.category.immobilier'),
  categoryFinanceJuridique('onboarding.category.finance_juridique'),
  categoryLivraison('onboarding.category.livraison'),
  categoryIndependants('onboarding.category.independants'),
  categoryAutresPro('onboarding.category.autres_pro');

  const AppMediaSlotId(this.wireValue);
  final String wireValue;

  static AppMediaSlotId? tryParse(String raw) {
    for (final id in AppMediaSlotId.values) {
      if (id.wireValue == raw) return id;
    }
    return null;
  }

  /// Maps merchant category catalog ids → media slots.
  static AppMediaSlotId? forCategoryId(String categoryId) {
    return switch (categoryId) {
      'bouche' => categoryBouche,
      'commerce' => categoryCommerce,
      'beaute' => categoryBeaute,
      'sante' => categorySante,
      'services_particuliers' => categoryServicesParticuliers,
      'loisirs' => categoryLoisirs,
      'association' => categoryAssociation,
      'autre' => categoryAutre,
      'artisan_btp' => categoryArtisanBtp,
      'services_pro' => categoryServicesPro,
      'grossiste' => categoryGrossiste,
      'immobilier' => categoryImmobilier,
      'finance_juridique' => categoryFinanceJuridique,
      'livraison' => categoryLivraison,
      'independants' => categoryIndependants,
      'autres_pro' => categoryAutresPro,
      _ => null,
    };
  }
}
