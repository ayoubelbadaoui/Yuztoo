/// Audience cible du commerçant — premier niveau du référentiel d'activités
/// (Main → Catégorie → Business). Pure Dart, pas de dépendance Flutter.
///
/// NOTE référentiel : dans le tableau source, la colonne « Main » étiquetait
/// les commerces de proximité (restaurant, coiffeur…) « B2B » et les
/// activités pro (grossiste, services aux professionnels…) « B2C ». Les
/// libellés étaient inversés par rapport à la sémantique `merchant_type`
/// déjà persistée ('b2c' = clients particuliers). Le REGROUPEMENT du tableau
/// est conservé tel quel ; seuls les libellés sont corrigés ici.
enum MerchantAudience {
  /// Commerces & services de proximité — clients particuliers (B2C).
  particuliers,

  /// Activités au service des professionnels — clients entreprises (B2B).
  professionnels;

  /// Valeur persistée dans `merchants/{id}.merchant_type` (cf.
  /// [MerchantOnboardingData.merchantType] qui n'accepte que 'b2c'/'b2b').
  String get merchantTypeValue => switch (this) {
        MerchantAudience.particuliers => 'b2c',
        MerchantAudience.professionnels => 'b2b',
      };

  /// Libellé court affiché dans le sélecteur de l'écran catégorie.
  String get labelFr => switch (this) {
        MerchantAudience.particuliers => 'Particuliers',
        MerchantAudience.professionnels => 'Professionnels',
      };

  /// Sous-titre descriptif du sélecteur.
  String get sublabelFr => switch (this) {
        MerchantAudience.particuliers => 'Commerces & services de proximité',
        MerchantAudience.professionnels => 'Activités B2B & indépendants',
      };
}
