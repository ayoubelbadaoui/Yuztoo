import '../../../domain/entities/merchant_subcategory.dart';

/// Référentiel des « businesses » (3e niveau du tableau source
/// Main → Catégorie → Business), indexés par l'id de catégorie défini dans
/// [MerchantCategoryCatalog].
///
/// Conventions :
/// - Les ids sont préfixés par la catégorie (ex. `bouche_cafe`) pour rester
///   uniques au global — « Coach professionnel » existe par ex. à la fois en
///   services pro et en indépendants.
/// - Les entrées « Autre… » sont placées en fin de liste (le tableau source
///   les triait alphabétiquement, donc parfois en tête).
/// - Une catégorie sans liste (ex. `autres_pro`, business unique « Autres
///   activités ») retourne une liste vide — le
///   [SubcategorySelectionScreen] saute alors l'étape au lieu d'afficher une
///   grille à un seul choix.
class MerchantSubcategoryCatalog {
  MerchantSubcategoryCatalog._();

  /// Returns the curated businesses for [categoryId], or an empty list when
  /// none are defined. The caller MUST handle the empty case (skip step /
  /// show fallback) rather than rendering a blank grid.
  static List<MerchantSubcategory> forCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return const [];
    return _byCategory[categoryId] ?? const [];
  }

  /// True when the catalog has a non-empty list for [categoryId] — used by
  /// the wizard to decide whether the business step should be rendered.
  static bool hasSubcategoriesFor(String? categoryId) =>
      forCategory(categoryId).isNotEmpty;

  /// Builds a category list where every business shares the category color
  /// (cohérent avec la teinte de la carte catégorie correspondante).
  static List<MerchantSubcategory> _list(
    String colorHex,
    List<(String, String)> items,
  ) =>
      [
        for (final (id, title) in items)
          MerchantSubcategory(
            id: id,
            title: title,
            placeholderColorHex: colorHex,
          ),
      ];

  static final Map<String, List<MerchantSubcategory>> _byCategory = {
    // ── Particuliers (B2C) ────────────────────────────────────────────────
    'bouche': _list('#FF9800', const [
      ('bouche_restaurant', 'Restaurant & Brasserie'),
      ('bouche_cafe', 'Café & Bar'),
      ('bouche_resto_rapide', 'Restauration rapide'),
      ('bouche_boulangerie', 'Boulangerie & Pâtisserie'),
      ('bouche_boucherie', 'Boucherie & Charcuterie'),
      ('bouche_poissonnerie', 'Poissonnerie'),
      ('bouche_epicerie', 'Épicerie spécialisée'),
      ('bouche_caviste', 'Caviste & Boissons spécialisées'),
      ('bouche_fromagerie', 'Fromagerie & Crèmerie'),
      ('bouche_producteurs', 'Producteurs & Vente directe'),
      ('bouche_traiteur', 'Traiteur & Plats préparés'),
      ('bouche_glacier', 'Glacier, Chocolatier & Confiserie'),
      ('bouche_autre', 'Autre métier de bouche'),
    ]),
    'commerce': _list('#2196F3', const [
      ('commerce_atelier', 'Atelier fabrication locale'),
      ('commerce_bijouterie', 'Bijouterie, Joaillerie & Horlogerie'),
      ('commerce_cadeaux', 'Cadeaux & Souvenirs'),
      ('commerce_chaussures', 'Chaussures & Maroquinerie'),
      ('commerce_concept_store', 'Concept store & Galerie-boutique'),
      ('commerce_createur', 'Créateur & Artisan d’art'),
      ('commerce_decoration', 'Décoration & Ameublement'),
      ('commerce_jeux', 'Jeux, Jouets & Loisirs créatifs'),
      ('commerce_librairie', 'Librairie & Papeterie'),
      ('commerce_linge', 'Linge de maison & Arts de la table'),
      ('commerce_musique', 'Musique, Culture & Disques'),
      ('commerce_nature', 'Nature, Découverte et animalerie'),
      ('commerce_mode', 'Prêt-à-porter & Mode'),
      ('commerce_spa_piscine', 'SPA, Piscine et entretien'),
      ('commerce_autre', 'Autre boutique spécialisée'),
    ]),
    'beaute': _list('#E91E63', const [
      ('beaute_barbier', 'Barbier'),
      ('beaute_bronzage', 'Centre de bronzage'),
      ('beaute_coach', 'Coach bien-être'),
      ('beaute_coiffeur', 'Coiffeur'),
      ('beaute_institut', 'Institut de beauté & Esthétique'),
      ('beaute_maquillage', 'Maquillage professionnel'),
      ('beaute_massage', 'Massage bien-être'),
      ('beaute_onglerie', 'Onglerie & Prothésie ongulaire'),
      ('beaute_piercing', 'Piercing'),
      ('beaute_capillaire', 'Prothésiste capillaire'),
      ('beaute_relaxation', 'Relaxation & Gestion du stress'),
      ('beaute_toilettage', 'Soins pour animaux (Toilettage)'),
      ('beaute_spa', 'Spa & Centre de bien-être'),
      ('beaute_tatouage', 'Tatouage'),
      ('beaute_autre', 'Autre activité'),
    ]),
    'sante': _list('#00BCD4', const [
      ('sante_coaching', 'Accompagnement & Coaching'),
      ('sante_aide_personne', 'Aide à la personne'),
      ('sante_paramedical', 'Cabinet paramédical'),
      ('sante_chiropraxie', 'Chiropraxie'),
      ('sante_kine', 'Kinésithérapie & Rééducation'),
      ('sante_nutrition', 'Nutrition & Diététique'),
      ('sante_opticien', 'Opticien & Audioprothésiste'),
      ('sante_osteo', 'Ostéopathie'),
      ('sante_podologie', 'Pédicurie & Podologie'),
      ('sante_pharmacie', 'Pharmacie & Parapharmacie'),
      ('sante_psy', 'Psychologue / psychopraticien'),
      ('sante_sage_femme', 'Sage-femme (suivi non médical)'),
      ('sante_infirmier', 'Soins infirmiers à domicile'),
      ('sante_veterinaire', 'Vétérinaire'),
      ('sante_autre', 'Autre activité'),
    ]),
    'services_particuliers': _list('#9C27B0', const [
      ('servpart_aide_domicile', 'Aide à domicile (Ménage, Jardin)'),
      ('servpart_cordonnerie', 'Cordonnerie, Serrurerie & Sécurité'),
      ('servpart_depannage', 'Dépannage à domicile'),
      ('servpart_piscine', 'Entretien Piscine et Spa'),
      ('servpart_formation', 'Formation & Professeur particulier'),
      ('servpart_garagiste', 'Garagiste & Entretien automobile'),
      ('servpart_garde_enfants', 'Garde d’enfants & Soutien scolaire'),
      ('servpart_location', 'Location de matériel'),
      ('servpart_photographe', 'Photographe'),
      ('servpart_pressing', 'Pressing & Blanchisserie'),
      ('servpart_electromenager', 'Réparation électroménager'),
      ('servpart_multimedia', 'Réparation Multimédia'),
      ('servpart_reprographie', 'Reprographie, Impression & Copie'),
      ('servpart_couture', 'Retouche & Couture'),
      ('servpart_autre', 'Autre service du quotidien'),
    ]),
    'loisirs': _list('#4CAF50', const [
      ('loisirs_bowling', 'Bowling'),
      ('loisirs_equestre', 'Centre équestre'),
      ('loisirs_multiactivite', 'Centre multiactivité loisir'),
      ('loisirs_club_sportif', 'Club sportif'),
      ('loisirs_discotheque', 'Discothèque / Boîte de nuit / Club'),
      ('loisirs_escape_game', 'Escape game'),
      ('loisirs_guide', 'Guide local & Expériences'),
      ('loisirs_hotel', 'Hôtel & Location saisonnière'),
      ('loisirs_karting', 'Karting'),
      ('loisirs_laser_game', 'Laser game'),
      ('loisirs_location', 'Location de matériel de loisirs'),
      ('loisirs_stages', 'Organisation d’activités & stages'),
      ('loisirs_fitness', 'Salle de sport & Fitness'),
      ('loisirs_yoga', 'Studio de yoga / Pilates'),
      ('loisirs_autre', 'Autre loisir & Expérience'),
    ]),
    'association': _list('#795548', const [
      ('assoc_culturelle', 'Association culturelle'),
      ('assoc_quartier', 'Association de quartier'),
      ('assoc_solidaire', 'Association solidaire & caritative'),
      ('assoc_sportive', 'Association sportive'),
      ('assoc_ccas', 'CCAS'),
      ('assoc_centre_social', 'Centre social & socio-culturel'),
      ('assoc_collectivite', 'Collectivité locale'),
      ('assoc_comite_fetes', 'Comité des fêtes'),
      ('assoc_equipement_public', 'Équipement public local'),
      ('assoc_etablissement_public', 'Établissement public local'),
      ('assoc_mairie', 'Mairie'),
      ('assoc_office_municipal', 'Office municipal (hors tourisme)'),
      ('assoc_structure_municipale', 'Structure municipale'),
      ('assoc_autre', 'Autre association ou structure'),
    ]),

    // ── Professionnels (B2B) ──────────────────────────────────────────────
    'artisan_btp': _list('#FF5722', const [
      ('btp_carrelage', 'Carrelage & Revêtements'),
      ('btp_charpente', 'Charpente & Couverture'),
      ('btp_chauffage', 'Chauffage & Chauffagiste'),
      ('btp_climatisation', 'Climatisation & Froid (frigoriste)'),
      ('btp_electricite', 'Électricité'),
      ('btp_espaces_verts', 'Entretien des espaces verts'),
      ('btp_maconnerie', 'Maçonnerie'),
      ('btp_menuiserie', 'Menuiserie'),
      ('btp_multiservices', 'Multi-services bâtiment'),
      ('btp_paysagiste', 'Paysagiste'),
      ('btp_peinture', 'Peinture & Finitions'),
      ('btp_plaquisterie', 'Plaquisterie & Isolation'),
      ('btp_plomberie', 'Plomberie'),
      ('btp_serrurerie', 'Serrurerie & Vitrerie'),
      ('btp_autre', 'Autre métier du bâtiment'),
    ]),
    'services_pro': _list('#3F51B5', const [
      ('servpro_communication', 'Agence de communication'),
      ('servpro_architecte', 'Architecte Extérieur / Intérieur'),
      ('servpro_bureau_etudes', 'Bureau d’études'),
      ('servpro_coach', 'Coach professionnel'),
      ('servpro_community', 'Community manager & Contenus'),
      ('servpro_rh', 'Conseil Ressources Humaines'),
      ('servpro_consultant', 'Consultant & Conseil en gestion'),
      ('servpro_design', 'Design & Création visuelle'),
      ('servpro_it', 'Développement informatique & IT'),
      ('servpro_formation', 'Formation & Formateur'),
      ('servpro_geometre', 'Géomètre & Diagnostic'),
      ('servpro_graphisme', 'Graphisme & Identité visuelle'),
      ('servpro_marketing', 'Marketing & Digital'),
      ('servpro_photo', 'Photographie & Vidéo pro.'),
      ('servpro_autre', 'Autre service aux professionnels'),
    ]),
    'grossiste': _list('#607D8B', const [
      ('grossiste_distributeur', 'Distributeur multi-produits B2B'),
      ('grossiste_equipements', 'Équipements professionnels'),
      ('grossiste_chr', 'Fournisseur CHR'),
      ('grossiste_emballages', 'Fournisseur d’emballages'),
      ('grossiste_hygiene', 'Fournisseur hygiène & entretien'),
      ('grossiste_materiel_technique', 'Fournisseur matériel technique'),
      ('grossiste_fournitures', 'Fournitures professionnelles'),
      ('grossiste_alimentaire', 'Grossiste alimentaire'),
      ('grossiste_boissons', 'Grossiste boissons'),
      ('grossiste_non_alimentaire', 'Grossiste non alimentaire'),
      ('grossiste_imprimerie', 'Imprimerie et enseigne'),
      ('grossiste_location', 'Location matériel & équipements'),
      ('grossiste_mobilier', 'Mobilier & agencement pro.'),
      ('grossiste_textile', 'Textile & linge professionnel'),
      ('grossiste_autre', 'Autre fournisseur ou grossiste'),
    ]),
    'immobilier': _list('#009688', const [
      ('immo_agence', 'Agence immobilière'),
      ('immo_amenagement', 'Aménagement & Foncier'),
      ('immo_conciergerie', 'Conciergerie professionnelle'),
      ('immo_expert', 'Expert immobilier'),
      // « Gestion locative & Administration de biens » abrégé : 43 caractères
      // ne tiennent pas sur les 2 lignes de la carte (3 colonnes, 11pt).
      ('immo_gestion_locative', 'Gestion locative & Adm. de biens'),
      ('immo_courte_duree', 'Location courte durée'),
      ('immo_marchand', 'Marchand de biens'),
      ('immo_promoteur', 'Promoteur immobilier'),
      ('immo_syndic', 'Syndic de copropriété'),
      ('immo_autre', 'Autre activité'),
    ]),
    'finance_juridique': _list('#FFC107', const [
      ('finjur_assurance', 'Assurance professionnelle'),
      ('finjur_audit', 'Audit & conformité'),
      ('finjur_avocat', 'Avocat'),
      ('finjur_financier', 'Conseil financier'),
      ('finjur_fiscal', 'Conseil fiscal'),
      ('finjur_juridique', 'Conseil juridique'),
      ('finjur_courtier', 'Courtier (assurance & crédit)'),
      ('finjur_comptable', 'Expert & Cabinet comptable'),
      ('finjur_mediation', 'Médiation & règlement des litiges'),
      ('finjur_notaire', 'Notaire'),
      ('finjur_autre', 'Autre service'),
    ]),
    'livraison': _list('#8BC34A', const [
      ('livraison_coursier', 'Coursier'),
      ('livraison_urbaine', 'Livraison urbaine'),
      ('livraison_logistique', 'Logistique locale'),
      ('livraison_mutualisation', 'Mutualisation de livraisons'),
      ('livraison_point_relais', 'Point relais indépendant'),
      ('livraison_stockage', 'Stockage local'),
      ('livraison_transporteur', 'Transporteur'),
      ('livraison_autre', 'Autre activité logistique'),
    ]),
    'independants': _list('#E91E63', const [
      ('indep_agent_commercial', 'Agent commercial'),
      ('indep_agent_terrain', 'Agent de terrain / Inspecteur'),
      ('indep_amo', 'AMO / Coordinateur de projet'),
      ('indep_apporteur', 'Apporteur d’affaires'),
      ('indep_auditeur', 'Auditeur terrain'),
      ('indep_coach', 'Coach professionnel'),
      ('indep_consultant', 'Consultant indépendant'),
      ('indep_expert', 'Expert technique indépendant'),
      ('indep_formateur', 'Formateur indépendant'),
      ('indep_multi', 'Indépendant multi-activités'),
      ('indep_intervenant', 'Intervenant terrain ponctuel'),
      ('indep_mandataire', 'Mandataire commercial'),
      ('indep_representant', 'Représentant commercial'),
      ('indep_technicien', 'Technicien spécialisé'),
      ('indep_autre', 'Autre indépendant (à préciser)'),
    ]),
    // 'autres_pro' n'a volontairement pas de liste : son unique business
    // (« Autres activités ») n'apporterait aucune information — le wizard
    // saute l'étape (même comportement que l'ancien « other »).
  };
}
