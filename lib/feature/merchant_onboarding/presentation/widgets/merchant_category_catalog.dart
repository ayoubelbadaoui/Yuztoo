import '../../domain/entities/merchant_audience.dart';
import '../../domain/entities/merchant_category.dart';

/// Référentiel des catégories d'activité, regroupées par audience cible
/// (niveau « Main » du tableau source : Main → Catégorie → Business).
///
/// L'écran [MerchantOnboardingScreen] affiche la grille correspondant à
/// l'audience sélectionnée ; les businesses (3e niveau) sont résolus par
/// [MerchantSubcategoryCatalog] à partir de l'id de catégorie.
class MerchantCategoryCatalog {
  MerchantCategoryCatalog._();

  /// Catégories pour les commerces & services de proximité (B2C).
  static const particuliers = <MerchantCategory>[
    MerchantCategory(
      id: 'bouche',
      title: 'Métiers de bouche',
      description: 'Restaurant, boulangerie, traiteur…',
      placeholderColorHex: '#FF9800',
    ),
    MerchantCategory(
      id: 'commerce',
      title: 'Commerce',
      description: 'Boutiques & magasins spécialisés',
      placeholderColorHex: '#2196F3',
    ),
    MerchantCategory(
      id: 'beaute',
      title: 'Beauté & Bien-être',
      description: 'Coiffure, institut, spa…',
      placeholderColorHex: '#E91E63',
    ),
    MerchantCategory(
      id: 'sante',
      title: 'Santé & Accompagnement',
      description: 'Paramédical, soins, accompagnement',
      placeholderColorHex: '#00BCD4',
    ),
    MerchantCategory(
      id: 'services_particuliers',
      title: 'Services aux particuliers',
      description: 'Services du quotidien',
      placeholderColorHex: '#9C27B0',
    ),
    MerchantCategory(
      id: 'loisirs',
      title: 'Loisirs & Expérience',
      description: 'Sport, divertissement, hôtellerie…',
      placeholderColorHex: '#4CAF50',
    ),
    MerchantCategory(
      id: 'association',
      title: 'Association & Collectivité',
      description: 'Associations & structures publiques',
      placeholderColorHex: '#795548',
    ),
  ];

  /// Catégories pour les activités au service des professionnels (B2B).
  static const professionnels = <MerchantCategory>[
    MerchantCategory(
      id: 'artisan_btp',
      title: 'Artisan BTP',
      description: 'Plomberie, électricité, maçonnerie…',
      placeholderColorHex: '#FF5722',
    ),
    MerchantCategory(
      id: 'services_pro',
      title: 'Services aux professionnels',
      description: 'Conseil, marketing, IT…',
      placeholderColorHex: '#3F51B5',
    ),
    MerchantCategory(
      id: 'grossiste',
      title: 'Grossiste spécialisé',
      description: 'Fournisseurs & distribution',
      placeholderColorHex: '#607D8B',
    ),
    MerchantCategory(
      id: 'immobilier',
      title: 'Immobilier & Foncier',
      description: 'Agence, gestion, promotion…',
      placeholderColorHex: '#009688',
    ),
    MerchantCategory(
      id: 'finance_juridique',
      title: 'Finance & Juridique',
      description: 'Comptable, avocat, assurance…',
      placeholderColorHex: '#FFC107',
    ),
    MerchantCategory(
      id: 'livraison',
      title: 'Service de livraison',
      description: 'Transport & logistique locale',
      placeholderColorHex: '#8BC34A',
    ),
    MerchantCategory(
      id: 'independants',
      title: 'Indépendants',
      description: 'Consultants & agents de terrain',
      placeholderColorHex: '#E91E63',
    ),
    MerchantCategory(
      id: 'autres_pro',
      title: 'Autres activités',
      description: 'Autre activité professionnelle',
      placeholderColorHex: '#9E9E9E',
    ),
  ];

  /// Grille de catégories pour l'audience sélectionnée.
  static List<MerchantCategory> forAudience(MerchantAudience audience) =>
      switch (audience) {
        MerchantAudience.particuliers => particuliers,
        MerchantAudience.professionnels => professionnels,
      };
}
