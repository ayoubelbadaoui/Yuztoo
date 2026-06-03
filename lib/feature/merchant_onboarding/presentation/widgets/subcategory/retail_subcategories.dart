import '../../../domain/entities/merchant_subcategory.dart';

/// Curated subcategories for the "Commerce de détail" top-level category.
/// Picked to cover the most common French independent retail formats; the
/// list is intentionally short so the grid stays scannable on phones.
class RetailSubcategories {
  RetailSubcategories._();

  static List<MerchantSubcategory> get all => const [
        MerchantSubcategory(
          id: 'mode',
          title: 'Mode &\nAccessoires',
          placeholderColorHex: '#C2185B',
        ),
        MerchantSubcategory(
          id: 'chaussures',
          title: 'Chaussures',
          placeholderColorHex: '#5D4037',
        ),
        MerchantSubcategory(
          id: 'maroquinerie',
          title: 'Maroquinerie',
          placeholderColorHex: '#6D4C41',
        ),
        MerchantSubcategory(
          id: 'bijouterie',
          title: 'Bijouterie\nHorlogerie',
          placeholderColorHex: '#FFC107',
        ),
        MerchantSubcategory(
          id: 'librairie',
          title: 'Librairie\nPapeterie',
          placeholderColorHex: '#1976D2',
        ),
        MerchantSubcategory(
          id: 'jouets',
          title: 'Jouets &\nLoisirs',
          placeholderColorHex: '#F57C00',
        ),
        MerchantSubcategory(
          id: 'decoration',
          title: 'Décoration\nMaison',
          placeholderColorHex: '#7CB342',
        ),
        MerchantSubcategory(
          id: 'fleuriste',
          title: 'Fleuriste',
          placeholderColorHex: '#EC407A',
        ),
        MerchantSubcategory(
          id: 'animalerie',
          title: 'Animalerie',
          placeholderColorHex: '#8D6E63',
        ),
        MerchantSubcategory(
          id: 'electronique',
          title: 'Électronique\nMultimédia',
          placeholderColorHex: '#455A64',
        ),
        MerchantSubcategory(
          id: 'sport_equipement',
          title: 'Articles\nde sport',
          placeholderColorHex: '#388E3C',
        ),
        MerchantSubcategory(
          id: 'autre_retail',
          title: 'Autre\ncommerce',
          placeholderColorHex: '#616161',
        ),
      ];
}
