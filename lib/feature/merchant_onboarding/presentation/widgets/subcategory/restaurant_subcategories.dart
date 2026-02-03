import '../../../domain/entities/merchant_subcategory.dart';

/// Restaurant subcategories data
class RestaurantSubcategories {
  RestaurantSubcategories._();

  static List<MerchantSubcategory> get all => [
        MerchantSubcategory(
          id: 'cafe',
          title: 'Café\nBar',
          placeholderColorHex: '#8B4513',
        ),
        MerchantSubcategory(
          id: 'restaurant',
          title: 'Restaurant\nBrasserie',
          placeholderColorHex: '#6B7B8C',
        ),
        MerchantSubcategory(
          id: 'restauration',
          title: 'Restauration\nrapide',
          placeholderColorHex: '#D4A017',
        ),
        MerchantSubcategory(
          id: 'boulangerie',
          title: 'Boulangerie\nPatisserie',
          placeholderColorHex: '#D2691E',
        ),
        MerchantSubcategory(
          id: 'boucherie',
          title: 'Boucherie\nCharcuterie',
          placeholderColorHex: '#8B0000',
        ),
        MerchantSubcategory(
          id: 'poissonnerie',
          title: 'Poissonnerie',
          placeholderColorHex: '#4682B4',
        ),
        MerchantSubcategory(
          id: 'fromagerie',
          title: 'Fromagerie\nCrèmerie',
          placeholderColorHex: '#DAA520',
        ),
        MerchantSubcategory(
          id: 'confiserie',
          title: 'Confiserie\nChocolatier',
          placeholderColorHex: '#654321',
        ),
        MerchantSubcategory(
          id: 'glacier',
          title: 'Glacier',
          placeholderColorHex: '#FFE4B5',
        ),
        MerchantSubcategory(
          id: 'caviste',
          title: 'Caviste &\nEpicerie',
          placeholderColorHex: '#722F37',
        ),
        MerchantSubcategory(
          id: 'maraicher',
          title: 'Maraîcher',
          placeholderColorHex: '#228B22',
        ),
        MerchantSubcategory(
          id: 'ferme',
          title: 'Ferme\nProduit Locaux',
          placeholderColorHex: '#8FBC8F',
        ),
        MerchantSubcategory(
          id: 'artisans',
          title: 'Artisans\nmarché',
          placeholderColorHex: '#CD853F',
        ),
        MerchantSubcategory(
          id: 'boutique',
          title: 'Boutique BIO',
          placeholderColorHex: '#90EE90',
        ),
        MerchantSubcategory(
          id: 'traiteur',
          title: 'Traiteur',
          placeholderColorHex: '#FF8C00',
        ),
      ];
}

