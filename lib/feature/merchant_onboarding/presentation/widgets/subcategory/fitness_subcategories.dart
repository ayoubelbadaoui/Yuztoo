import '../../../domain/entities/merchant_subcategory.dart';

/// Curated subcategories for "Sport & Fitness".
class FitnessSubcategories {
  FitnessSubcategories._();

  static List<MerchantSubcategory> get all => const [
        MerchantSubcategory(
          id: 'salle_sport',
          title: 'Salle\nde sport',
          placeholderColorHex: '#1B5E20',
        ),
        MerchantSubcategory(
          id: 'crossfit',
          title: 'CrossFit\nFunctional',
          placeholderColorHex: '#BF360C',
        ),
        MerchantSubcategory(
          id: 'yoga',
          title: 'Yoga\nPilates',
          placeholderColorHex: '#7CB342',
        ),
        MerchantSubcategory(
          id: 'danse',
          title: 'Danse',
          placeholderColorHex: '#D81B60',
        ),
        MerchantSubcategory(
          id: 'arts_martiaux',
          title: 'Arts\nmartiaux',
          placeholderColorHex: '#5D4037',
        ),
        MerchantSubcategory(
          id: 'piscine',
          title: 'Piscine\nNatation',
          placeholderColorHex: '#0277BD',
        ),
        MerchantSubcategory(
          id: 'tennis',
          title: 'Tennis\nPadel',
          placeholderColorHex: '#FBC02D',
        ),
        MerchantSubcategory(
          id: 'escalade',
          title: 'Escalade',
          placeholderColorHex: '#6A1B9A',
        ),
        MerchantSubcategory(
          id: 'coach_sportif',
          title: 'Coach\nsportif',
          placeholderColorHex: '#37474F',
        ),
        MerchantSubcategory(
          id: 'autre_fitness',
          title: 'Autre\nactivité',
          placeholderColorHex: '#616161',
        ),
      ];
}
