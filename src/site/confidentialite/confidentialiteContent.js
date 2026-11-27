/**
 * Privacy policy. Sections 1–9 and 11–13 are migrated verbatim from the app repo's
 * public/confidentialite.html (develop, 7 May 2026); section 10 and the website
 * part of section 11 cover what this site collects. Keep both in sync.
 */

import { CONTACT } from '../../siteConfig.js'

export const PRIVACY_HERO = {
  crumb: 'Confidentialité',
  title: 'Politique de confidentialité',
  lead: 'Ce que YuzToo collecte, pourquoi, et comment vous gardez la main sur vos données.',
  updated: 'Dernière mise à jour : 14 novembre 2026',
  intro:
    'La présente politique décrit comment YuzToo collecte, utilise et protège vos données personnelles, conformément au Règlement Général sur la Protection des Données (RGPD) et à la loi Informatique et Libertés. Notre principe directeur est simple : vos clients vous appartiennent, sans publicité ni revente de données.',
}

export const PRIVACY_SECTIONS = [
  {
    id: 'responsable',
    title: '1. Responsable de traitement',
    paragraphs: [
      `YuzToo est le responsable du traitement de vos données personnelles. Pour toute question ou demande relative à vos données, vous pouvez nous écrire à ${CONTACT.email}.`,
    ],
  },
  {
    id: 'donnees',
    title: '2. Données collectées par l’application',
    paragraphs: ['YuzToo collecte uniquement les données nécessaires au fonctionnement du service :'],
    list: [
      'Données d’authentification : adresse e-mail, numéro de téléphone, mot de passe (stocké haché par Firebase Auth), identifiant Google ou Apple le cas échéant.',
      'Données de profil : pseudonyme, ville déclarée.',
      'Données techniques : jeton de notification (FCM), modèle d’appareil, langue, version de l’application.',
      'Données d’usage : commerces suivis, niveaux de cœur, commerces bloqués, notifications consultées, passages fidélité validés et historique correspondant.',
      'Données de signalement : motif et message libre saisis lors du signalement d’un Commerçant ou d’une promotion.',
    ],
    after:
      'Nous ne collectons aucune donnée bancaire, aucun contenu de messagerie tierce, aucune liste de contacts, aucun historique de navigation hors de l’application.',
  },
  {
    id: 'finalites',
    title: '3. Finalités et bases légales',
    paragraphs: ['Vos données sont traitées pour les finalités suivantes :'],
    list: [
      'Création et gestion de votre compte : exécution du contrat (article 6.1.b du RGPD).',
      'Programme de fidélité et notifications des Commerçants que vous suivez : exécution du contrat.',
      'Sécurité du service, prévention de la fraude et modération des signalements : intérêt légitime (article 6.1.f).',
      'Statistiques d’usage agrégées et anonymisées : intérêt légitime.',
      'Respect d’obligations légales (lutte contre la fraude, réquisitions judiciaires) : obligation légale (article 6.1.c).',
    ],
  },
  {
    id: 'destinataires',
    title: '4. Destinataires',
    paragraphs: [
      'Vos données sont accessibles aux seules personnes habilitées au sein de YuzToo. Elles peuvent être transmises à nos sous-traitants techniques :',
    ],
    list: [
      'Google Firebase (Authentication, Firestore, Cloud Functions, Cloud Messaging, Storage) en tant qu’hébergeur et fournisseur d’infrastructure.',
      'Apple Push Notification service et Google Firebase Cloud Messaging pour la délivrance des notifications.',
    ],
    after: 'Aucune donnée n’est cédée, louée ou vendue à des tiers à des fins publicitaires.',
  },
  {
    id: 'transferts',
    title: '5. Transferts hors Union européenne',
    paragraphs: [
      'Les serveurs Firebase sont hébergés dans la région « europe-west1 » (Belgique) lorsque cela est techniquement possible. Certains traitements résiduels peuvent impliquer un transfert vers les États-Unis (notamment Firebase Cloud Messaging). Ces transferts sont encadrés par le Data Privacy Framework (DPF) et les clauses contractuelles types adoptées par la Commission européenne.',
    ],
  },
  {
    id: 'conservation',
    title: '6. Durée de conservation',
    paragraphs: [
      'Vos données sont conservées tant que votre compte est actif. Elles sont supprimées automatiquement et de manière irréversible dès la suppression de votre compte (effacement en cascade : profil, jetons, notifications, suivis, blocages, progression fidélité chez chaque Commerçant). Les signalements sont conservés six (6) mois pour les besoins de la modération avant suppression.',
    ],
  },
  {
    id: 'droits',
    title: '7. Vos droits',
    paragraphs: ['Conformément aux articles 15 à 22 du RGPD, vous disposez des droits suivants :'],
    list: [
      'Droit d’accès : connaître les données que nous détenons sur vous.',
      'Droit de rectification : corriger une donnée inexacte.',
      'Droit à l’effacement (« droit à l’oubli ») : supprimer votre compte et toutes les données associées. Vous pouvez l’exercer directement depuis l’écran « Sécurité & Confidentialité » de l’application.',
      'Droit à la limitation et à l’opposition au traitement.',
      'Droit à la portabilité de vos données.',
      'Droit de définir des directives post mortem.',
    ],
    after: `Pour exercer ces droits, écrivez-nous à ${CONTACT.email}. Nous répondons dans un délai d’un (1) mois. Vous pouvez également introduire une réclamation auprès de la CNIL (www.cnil.fr).`,
  },
  {
    id: 'securite',
    title: '8. Sécurité',
    paragraphs: [
      'Vos données sont chiffrées en transit (HTTPS/TLS) et au repos (chiffrement Firebase). L’accès aux données est strictement limité par des règles de sécurité Firestore qui empêchent un utilisateur d’accéder aux données d’un autre. Les mots de passe ne sont jamais stockés en clair.',
    ],
  },
  {
    id: 'mineurs',
    title: '9. Mineurs',
    paragraphs: [
      'YuzToo s’adresse à un public majeur. Si vous avez moins de quinze (15) ans, l’inscription requiert le consentement conjoint d’un titulaire de l’autorité parentale. Tout compte signalé comme appartenant à un mineur de moins de quinze ans sans consentement parental sera supprimé.',
    ],
  },
  {
    id: 'formulaires',
    title: '10. Formulaires du site yuztoo.com',
    paragraphs: [
      'Les formulaires de contact du site (commerçants, habitants, collectivités, contact) recueillent :',
    ],
    list: [
      'Votre nom, votre adresse e-mail et, si vous les indiquez, votre téléphone, le nom de votre commerce ou de votre commune, et votre message.',
      'La page d’où vous écrivez, pour orienter votre demande vers la bonne personne.',
      'Une empreinte hachée et non réversible de votre adresse IP et de votre e-mail, conservée au plus vingt-quatre (24) heures, uniquement pour limiter les envois abusifs.',
    ],
    after:
      'Base légale : votre consentement (article 6.1.a du RGPD), que vous donnez en cochant la case du formulaire et que vous pouvez retirer à tout moment. Ces informations servent uniquement à vous répondre et à vous accompagner ; elles sont conservées trois (3) ans après notre dernier échange, puis supprimées.',
  },
  {
    id: 'cookies',
    title: '11. Cookies et identifiants techniques',
    paragraphs: [
      'L’application YuzToo n’utilise pas de cookies au sens du web. Elle s’appuie sur des identifiants techniques strictement nécessaires au fonctionnement (jeton de session Firebase Auth, jeton FCM pour les notifications push). Aucun identifiant publicitaire n’est exploité.',
      'Le site yuztoo.com ne dépose aucun cookie et n’utilise aucun outil de mesure d’audience. Votre choix de thème (clair ou sombre) est enregistré uniquement dans votre navigateur et ne nous est jamais transmis.',
    ],
  },
  {
    id: 'modifications',
    title: '12. Modifications',
    paragraphs: [
      'La présente politique peut être mise à jour pour refléter une évolution du service ou de la réglementation. Toute modification substantielle sera notifiée via l’application. La date de dernière mise à jour figure en tête de document.',
    ],
  },
  {
    id: 'contact',
    title: '13. Contact',
    paragraphs: [
      `Pour toute question relative à la protection de vos données, vous pouvez nous contacter à ${CONTACT.email}.`,
    ],
  },
]
