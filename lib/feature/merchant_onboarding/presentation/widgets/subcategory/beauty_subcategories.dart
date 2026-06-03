import '../../../domain/entities/merchant_subcategory.dart';

/// Curated subcategories for "Beauté & Bien-être".
class BeautySubcategories {
  BeautySubcategories._();

  static List<MerchantSubcategory> get all => const [
        MerchantSubcategory(
          id: 'coiffure',
          title: 'Coiffure',
          placeholderColorHex: '#8E24AA',
        ),
        MerchantSubcategory(
          id: 'barbier',
          title: 'Barbier',
          placeholderColorHex: '#3E2723',
        ),
        MerchantSubcategory(
          id: 'institut',
          title: 'Institut\nde beauté',
          placeholderColorHex: '#EC407A',
        ),
        MerchantSubcategory(
          id: 'onglerie',
          title: 'Onglerie',
          placeholderColorHex: '#F48FB1',
        ),
        MerchantSubcategory(
          id: 'spa',
          title: 'Spa',
          placeholderColorHex: '#26A69A',
        ),
        MerchantSubcategory(
          id: 'massage',
          title: 'Massage\nbien-être',
          placeholderColorHex: '#FB8C00',
        ),
        MerchantSubcategory(
          id: 'esthetique',
          title: 'Esthétique\nMédicale',
          placeholderColorHex: '#6A1B9A',
        ),
        MerchantSubcategory(
          id: 'parfumerie',
          title: 'Parfumerie\nCosmétiques',
          placeholderColorHex: '#D81B60',
        ),
        MerchantSubcategory(
          id: 'tatouage',
          title: 'Tatouage\nPiercing',
          placeholderColorHex: '#212121',
        ),
        MerchantSubcategory(
          id: 'autre_beauty',
          title: 'Autre\nbien-être',
          placeholderColorHex: '#616161',
        ),
      ];
}
