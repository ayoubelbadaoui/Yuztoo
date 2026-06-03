import '../../../domain/entities/merchant_subcategory.dart';

/// Curated subcategories for "Services" — independent service businesses
/// that fit Yuztoo's loyalty model.
class ServicesSubcategories {
  ServicesSubcategories._();

  static List<MerchantSubcategory> get all => const [
        MerchantSubcategory(
          id: 'auto',
          title: 'Garage\nAuto',
          placeholderColorHex: '#37474F',
        ),
        MerchantSubcategory(
          id: 'pressing',
          title: 'Pressing\nLaverie',
          placeholderColorHex: '#1976D2',
        ),
        MerchantSubcategory(
          id: 'cordonnerie',
          title: 'Cordonnerie\nClés',
          placeholderColorHex: '#5D4037',
        ),
        MerchantSubcategory(
          id: 'photo',
          title: 'Photographe\nVidéaste',
          placeholderColorHex: '#212121',
        ),
        MerchantSubcategory(
          id: 'imprimerie',
          title: 'Imprimerie\nReprographie',
          placeholderColorHex: '#455A64',
        ),
        MerchantSubcategory(
          id: 'reparation',
          title: 'Réparation\nélectronique',
          placeholderColorHex: '#0288D1',
        ),
        MerchantSubcategory(
          id: 'agence_voyage',
          title: 'Agence\nde voyage',
          placeholderColorHex: '#00897B',
        ),
        MerchantSubcategory(
          id: 'auto_ecole',
          title: 'Auto-école',
          placeholderColorHex: '#F57C00',
        ),
        MerchantSubcategory(
          id: 'sante',
          title: 'Santé\nParamédical',
          placeholderColorHex: '#C62828',
        ),
        MerchantSubcategory(
          id: 'animalerie_services',
          title: 'Toilettage\nanimaux',
          placeholderColorHex: '#8D6E63',
        ),
        MerchantSubcategory(
          id: 'pro_btp',
          title: 'Artisan\nBTP',
          placeholderColorHex: '#6D4C41',
        ),
        MerchantSubcategory(
          id: 'autre_services',
          title: 'Autre\nservice',
          placeholderColorHex: '#616161',
        ),
      ];
}
