/// In-app legal documents shown by [LegalDocumentScreen]. Bundled as Dart
/// constants on purpose:
///   * the text rarely changes between releases, so an asset round-trip
///     would buy us nothing;
///   * the App Store reviewer needs a fully working privacy view even
///     when the device is offline at first launch (`url_launcher` to a
///     web page would fail — review machines run with no network);
///   * keeping the text in source means it ships with the binary and
///     doesn't depend on a hosting provider being up at any future date.
///
/// When the canonical text changes, bump [LegalDocumentMeta.lastUpdated]
/// so any future "you must re-accept the updated terms" gate has a
/// version it can pin to.
enum LegalDocument {
  termsOfService,
  privacyPolicy,
}

/// Static metadata + body for each [LegalDocument]. Read via
/// [LegalDocument.meta].
class LegalDocumentMeta {
  const LegalDocumentMeta({
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  final String title;

  /// Human-readable date in `JJ mois AAAA` form (French). Bump on any
  /// material change so a future re-acceptance flow has a concrete value
  /// to compare against.
  final String lastUpdated;

  /// Short paragraph rendered above the section list.
  final String intro;

  final List<LegalSection> sections;
}

class LegalSection {
  const LegalSection({required this.heading, required this.body});

  final String heading;
  final String body;
}

extension LegalDocumentX on LegalDocument {
  LegalDocumentMeta get meta {
    switch (this) {
      case LegalDocument.termsOfService:
        return _termsOfService;
      case LegalDocument.privacyPolicy:
        return _privacyPolicy;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conditions Générales d'Utilisation
// ─────────────────────────────────────────────────────────────────────────────

const _termsOfService = LegalDocumentMeta(
  title: 'Conditions Générales d\'Utilisation',
  lastUpdated: '7 mai 2026',
  intro:
      'Bienvenue sur Yuztoo. Les présentes conditions générales d\'utilisation '
      '(« CGU ») encadrent votre utilisation de l\'application mobile Yuztoo et '
      'des services associés. En créant un compte ou en utilisant l\'application, '
      'vous reconnaissez les avoir lues et acceptées.',
  sections: [
    LegalSection(
      heading: '1. Objet',
      body:
          'Yuztoo est une application mobile mettant en relation des '
          'commerçants de proximité (« Commerçants ») et des particuliers '
          '(« Clients ») afin de favoriser une consommation locale, sans '
          'publicité tierce et sans revente de données. Yuztoo permet aux '
          'Clients de suivre leurs commerces préférés, de bénéficier d\'un '
          'programme de fidélité et de recevoir des notifications de la part '
          'des Commerçants qu\'ils ont choisis de suivre.',
    ),
    LegalSection(
      heading: '2. Création de compte',
      body:
          'L\'utilisation de Yuztoo nécessite la création d\'un compte. Vous '
          'vous engagez à fournir des informations exactes et à les tenir à '
          'jour. Vous êtes seul responsable de la confidentialité de vos '
          'identifiants. Toute opération réalisée depuis votre compte est '
          'présumée effectuée par vous. En cas d\'utilisation frauduleuse, '
          'vous devez nous en informer sans délai.',
    ),
    LegalSection(
      heading: '3. Usage acceptable',
      body:
          'Vous vous engagez à utiliser Yuztoo de bonne foi et à respecter la '
          'législation française. Sont notamment interdits : (a) l\'usurpation '
          'd\'identité d\'un Commerçant ou d\'un autre Client ; (b) la '
          'publication de contenus illégaux, diffamatoires, haineux ou '
          'pornographiques ; (c) la collecte automatisée de données ; '
          '(d) toute tentative d\'altérer le fonctionnement du service ou '
          'd\'en contourner les protections de sécurité.',
    ),
    LegalSection(
      heading: '4. Contenus publiés par les Commerçants',
      body:
          'Les Commerçants restent seuls responsables des contenus qu\'ils '
          'publient (description, photos, promotions, notifications). Yuztoo '
          'agit en qualité d\'hébergeur au sens de l\'article 6 de la LCEN. '
          'Tout contenu manifestement illicite peut être signalé via la '
          'fonction « Signaler » disponible depuis chaque vitrine. Les '
          'signalements sont traités dans un délai raisonnable et peuvent '
          'donner lieu au retrait du contenu et/ou à la suspension du compte '
          'concerné.',
    ),
    LegalSection(
      heading: '5. Programme de fidélité',
      body:
          'Le programme de fidélité Yuztoo permet aux Clients d\'accumuler '
          'des passages validés chez un Commerçant et, le cas échéant, de '
          'bénéficier d\'avantages (bon de bienvenue, bon fidélité). Les '
          'avantages sont définis et financés par chaque Commerçant. Yuztoo '
          'fournit l\'infrastructure technique mais n\'est pas partie '
          'prenante au contrat commercial entre le Client et le Commerçant. '
          'Tout litige relatif à l\'octroi ou à la valorisation d\'un '
          'avantage doit être traité directement avec le Commerçant.',
    ),
    LegalSection(
      heading: '6. Notifications',
      body:
          'Vous pouvez recevoir des notifications push de la part des '
          'Commerçants que vous suivez. Vous pouvez à tout moment couper le '
          'son d\'un Commerçant, le bloquer ou retirer le suivi depuis '
          'l\'application. Vous pouvez également désactiver toutes les '
          'notifications Yuztoo dans les réglages de votre téléphone.',
    ),
    LegalSection(
      heading: '7. Propriété intellectuelle',
      body:
          'L\'application Yuztoo, ses marques, sa charte graphique et son '
          'code source sont protégés par le droit d\'auteur et le droit des '
          'marques. Toute reproduction, extraction ou utilisation non '
          'autorisée est interdite. Les Commerçants conservent la propriété '
          'des contenus qu\'ils publient et concèdent à Yuztoo une licence '
          'non exclusive d\'utilisation strictement limitée à l\'exploitation '
          'du service.',
    ),
    LegalSection(
      heading: '8. Disponibilité du service',
      body:
          'Yuztoo s\'efforce d\'assurer une disponibilité optimale du '
          'service mais ne peut garantir une absence totale d\'interruption. '
          'Des opérations de maintenance peuvent être réalisées sans préavis. '
          'Yuztoo ne saurait être tenu responsable d\'une indisponibilité '
          'temporaire ni des conséquences indirectes d\'une telle '
          'indisponibilité (perte de chiffre d\'affaires, perte d\'opportunité, '
          'etc.).',
    ),
    LegalSection(
      heading: '9. Responsabilité',
      body:
          'Yuztoo agit comme intermédiaire technique. La responsabilité de '
          'Yuztoo est strictement limitée aux dommages directs et prévisibles '
          'résultant d\'un manquement à ses obligations. Yuztoo n\'est en '
          'aucun cas responsable des relations commerciales entre Clients et '
          'Commerçants, ni des contenus publiés par les Commerçants.',
    ),
    LegalSection(
      heading: '10. Suspension et clôture du compte',
      body:
          'Vous pouvez supprimer votre compte à tout moment depuis l\'écran '
          '« Sécurité & Confidentialité ». La suppression entraîne '
          'l\'effacement irréversible de vos données conformément à l\'article '
          '17 du RGPD (voir Politique de confidentialité). Yuztoo se réserve '
          'le droit de suspendre ou supprimer un compte en cas de violation '
          'des présentes CGU, après notification quand cela est possible.',
    ),
    LegalSection(
      heading: '11. Modification des CGU',
      body:
          'Yuztoo peut modifier les présentes CGU pour refléter une évolution '
          'du service ou de la réglementation. Les utilisateurs sont '
          'informés des modifications substantielles via l\'application. La '
          'poursuite de l\'utilisation du service après notification vaut '
          'acceptation des CGU mises à jour.',
    ),
    LegalSection(
      heading: '12. Droit applicable et juridiction',
      body:
          'Les présentes CGU sont soumises au droit français. À défaut de '
          'résolution amiable, tout litige sera porté devant les tribunaux '
          'compétents du ressort du siège social de Yuztoo. Les Clients '
          'consommateurs au sens du Code de la consommation conservent leurs '
          'droits de saisir la juridiction de leur lieu de domicile.',
    ),
    LegalSection(
      heading: '13. Contact',
      body:
          'Pour toute question relative aux présentes CGU, vous pouvez nous '
          'contacter à l\'adresse contact@yuztoo.app.',
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Politique de Confidentialité
// ─────────────────────────────────────────────────────────────────────────────

const _privacyPolicy = LegalDocumentMeta(
  title: 'Politique de Confidentialité',
  lastUpdated: '7 mai 2026',
  intro:
      'La présente politique décrit comment Yuztoo collecte, utilise et '
      'protège vos données personnelles, conformément au Règlement Général '
      'sur la Protection des Données (RGPD) et à la loi Informatique et '
      'Libertés. Notre principe directeur est simple : vos clients vous '
      'appartiennent, sans publicité ni revente de données.',
  sections: [
    LegalSection(
      heading: '1. Responsable de traitement',
      body:
          'Yuztoo est le responsable du traitement de vos données '
          'personnelles. Pour toute question ou demande relative à vos '
          'données, vous pouvez nous écrire à privacy@yuztoo.app.',
    ),
    LegalSection(
      heading: '2. Données collectées',
      body:
          'Yuztoo collecte uniquement les données nécessaires au '
          'fonctionnement du service :\n\n'
          '• Données d\'authentification : adresse e-mail, numéro de '
          'téléphone, mot de passe (stocké haché par Firebase Auth), '
          'identifiant Google ou Apple le cas échéant.\n'
          '• Données de profil : pseudonyme, ville déclarée.\n'
          '• Données techniques : jeton de notification (FCM), modèle '
          'd\'appareil, langue, version de l\'application.\n'
          '• Données d\'usage : commerces suivis, niveaux de cœur, '
          'commerces bloqués, notifications consultées, passages '
          'fidélité validés et historique correspondant.\n'
          '• Données de signalement : motif et message libre saisis lors '
          'du signalement d\'un Commerçant ou d\'une promotion.\n\n'
          'Nous ne collectons aucune donnée bancaire, aucun contenu de '
          'messagerie tierce, aucune liste de contacts, aucun historique '
          'de navigation hors de l\'application.',
    ),
    LegalSection(
      heading: '3. Finalités et bases légales',
      body:
          'Vos données sont traitées pour les finalités suivantes :\n\n'
          '• Création et gestion de votre compte : exécution du contrat '
          '(article 6.1.b du RGPD).\n'
          '• Programme de fidélité et notifications des Commerçants que '
          'vous suivez : exécution du contrat.\n'
          '• Sécurité du service, prévention de la fraude et modération '
          'des signalements : intérêt légitime (article 6.1.f).\n'
          '• Statistiques d\'usage agrégées et anonymisées : intérêt '
          'légitime.\n'
          '• Respect d\'obligations légales (lutte contre la fraude, '
          'réquisitions judiciaires) : obligation légale '
          '(article 6.1.c).',
    ),
    LegalSection(
      heading: '4. Destinataires',
      body:
          'Vos données sont accessibles aux seules personnes habilitées '
          'au sein de Yuztoo. Elles peuvent être transmises à nos '
          'sous-traitants techniques :\n\n'
          '• Google Firebase (Authentication, Firestore, Cloud Functions, '
          'Cloud Messaging, Storage) en tant qu\'hébergeur et fournisseur '
          'd\'infrastructure.\n'
          '• Apple Push Notification service et Google Firebase Cloud '
          'Messaging pour la délivrance des notifications.\n\n'
          'Aucune donnée n\'est cédée, louée ou vendue à des tiers à des '
          'fins publicitaires.',
    ),
    LegalSection(
      heading: '5. Transferts hors Union Européenne',
      body:
          'Les serveurs Firebase sont hébergés dans la région '
          '« europe-west1 » (Belgique) lorsque cela est techniquement '
          'possible. Certains traitements résiduels peuvent impliquer un '
          'transfert vers les États-Unis (notamment Firebase Cloud '
          'Messaging). Ces transferts sont encadrés par le Data Privacy '
          'Framework (DPF) et les clauses contractuelles types adoptées '
          'par la Commission européenne.',
    ),
    LegalSection(
      heading: '6. Durée de conservation',
      body:
          'Vos données sont conservées tant que votre compte est actif. '
          'Elles sont supprimées automatiquement et de manière '
          'irréversible dès la suppression de votre compte (effacement '
          'en cascade : profil, jetons, notifications, suivis, blocages, '
          'progression fidélité chez chaque Commerçant). Les '
          'signalements sont conservés six (6) mois pour les besoins de '
          'la modération avant suppression.',
    ),
    LegalSection(
      heading: '7. Vos droits',
      body:
          'Conformément aux articles 15 à 22 du RGPD, vous disposez des '
          'droits suivants :\n\n'
          '• Droit d\'accès : connaître les données que nous détenons '
          'sur vous.\n'
          '• Droit de rectification : corriger une donnée inexacte.\n'
          '• Droit à l\'effacement (« droit à l\'oubli ») : supprimer '
          'votre compte et toutes les données associées. Vous pouvez '
          'l\'exercer directement depuis l\'écran « Sécurité & '
          'Confidentialité » de l\'application.\n'
          '• Droit à la limitation et à l\'opposition au traitement.\n'
          '• Droit à la portabilité de vos données.\n'
          '• Droit de définir des directives post mortem.\n\n'
          'Pour exercer ces droits, écrivez-nous à privacy@yuztoo.app. '
          'Nous répondons dans un délai d\'un (1) mois. Vous pouvez '
          'également introduire une réclamation auprès de la CNIL '
          '(www.cnil.fr).',
    ),
    LegalSection(
      heading: '8. Sécurité',
      body:
          'Vos données sont chiffrées en transit (HTTPS/TLS) et au repos '
          '(chiffrement Firebase). L\'accès aux données est strictement '
          'limité par des règles de sécurité Firestore qui empêchent un '
          'utilisateur d\'accéder aux données d\'un autre. Les mots de '
          'passe ne sont jamais stockés en clair.',
    ),
    LegalSection(
      heading: '9. Mineurs',
      body:
          'Yuztoo s\'adresse à un public majeur. Si vous avez moins de '
          'quinze (15) ans, l\'inscription requiert le consentement '
          'conjoint d\'un titulaire de l\'autorité parentale. Tout '
          'compte signalé comme appartenant à un mineur de moins de '
          'quinze ans sans consentement parental sera supprimé.',
    ),
    LegalSection(
      heading: '10. Cookies et identifiants techniques',
      body:
          'L\'application Yuztoo n\'utilise pas de cookies au sens du '
          'web. Elle s\'appuie sur des identifiants techniques '
          'strictement nécessaires au fonctionnement (jeton de session '
          'Firebase Auth, jeton FCM pour les notifications push). Aucun '
          'identifiant publicitaire n\'est exploité.',
    ),
    LegalSection(
      heading: '11. Modifications',
      body:
          'La présente politique peut être mise à jour pour refléter '
          'une évolution du service ou de la réglementation. Toute '
          'modification substantielle sera notifiée via l\'application. '
          'La date de dernière mise à jour figure en tête de document.',
    ),
    LegalSection(
      heading: '12. Contact',
      body:
          'Pour toute question relative à la protection de vos données, '
          'vous pouvez nous contacter à privacy@yuztoo.app.',
    ),
  ],
);
