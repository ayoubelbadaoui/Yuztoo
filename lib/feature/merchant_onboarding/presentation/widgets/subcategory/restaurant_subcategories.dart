import '../../../domain/entities/merchant_subcategory.dart';

/// Restaurant subcategories data
class RestaurantSubcategories {
  RestaurantSubcategories._();

  static List<MerchantSubcategory> get all => [
        const MerchantSubcategory(
          id: 'cafe',
          title: 'Café\nBar',
          placeholderColorHex: '#8B4513',
        ),
        const MerchantSubcategory(
          id: 'restaurant',
          title: 'Restaurant\nBrasserie',
          placeholderColorHex: '#6B7B8C',
        ),
        const MerchantSubcategory(
          id: 'restauration',
          title: 'Restauration\nrapide',
          placeholderColorHex: '#D4A017',
        ),
        const MerchantSubcategory(
          id: 'boulangerie',
          title: 'Boulangerie\nPatisserie',
          placeholderColorHex: '#D2691E',
        ),
        const MerchantSubcategory(
          id: 'boucherie',
          title: 'Boucherie\nCharcuterie',
          placeholderColorHex: '#8B0000',
        ),
        const MerchantSubcategory(
          id: 'poissonnerie',
          title: 'Poissonnerie',
          placeholderColorHex: '#4682B4',
        ),
        const MerchantSubcategory(
          id: 'fromagerie',
          title: 'Fromagerie\nCrèmerie',
          placeholderColorHex: '#DAA520',
        ),
        const MerchantSubcategory(
          id: 'confiserie',
          title: 'Confiserie\nChocolatier',
          placeholderColorHex: '#654321',
        ),
        const MerchantSubcategory(
          id: 'glacier',
          title: 'Glacier',
          placeholderColorHex: '#FFE4B5',
        ),
        const MerchantSubcategory(
          id: 'caviste',
          title: 'Caviste &\nEpicerie',
          placeholderColorHex: '#722F37',
        ),
        const MerchantSubcategory(
          id: 'maraicher',
          title: 'Maraîcher',
          placeholderColorHex: '#228B22',
        ),
        const MerchantSubcategory(
          id: 'ferme',
          title: 'Ferme\nProduit Locaux',
          placeholderColorHex: '#8FBC8F',
        ),
        const MerchantSubcategory(
          id: 'artisans',
          title: 'Artisans\nmarché',
          placeholderColorHex: '#CD853F',
        ),
        const MerchantSubcategory(
          id: 'boutique',
          title: 'Boutique BIO',
          placeholderColorHex: '#90EE90',
        ),
        const MerchantSubcategory(
          id: 'traiteur',
          title: 'Traiteur',
          placeholderColorHex: '#FF8C00',
        ),
      ];
}

