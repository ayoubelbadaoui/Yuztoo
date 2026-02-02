import '../../../domain/entities/merchant_benefit.dart';

/// Benefits data provider
class BenefitsData {
  BenefitsData._();

  static List<MerchantBenefit> get all => [
        const MerchantBenefit(
          title: 'Vos clients, vraiment à vous:',
          description: 'Centralisez vos clients sans dépendre des plateformes.',
        ),
        const MerchantBenefit(
          title: 'Communiquez simplement:',
          description: 'Envoyez des infos utiles directement à vos clients, sans intermédiaire.',
        ),
        const MerchantBenefit(
          title: 'La fidélité se fait toute seule:',
          description: 'Chaque passage compte sans carte ni contrainte.',
        ),
        const MerchantBenefit(
          title: 'Cercle de confiance',
          description: 'Recommandez des commerces et soyez recommandés sans note ni classement.',
        ),
        const MerchantBenefit(
          title: 'Accès direct',
          description: 'Facilitez l\'accès à vos solutions existantes (réservation, click & collect...)',
        ),
      ];
}

