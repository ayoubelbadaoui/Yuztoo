/**
 * « Pour les collectivités » copy. No JSX.
 * Source: the live /espace-collectivites/ page. The report mock in the hero is
 * illustrative (no real municipal figures) and labelled as such.
 */

import { CONTACT, NETWORK } from '../../siteConfig.js'

export const COL_HERO = {
  crumb: 'Collectivités',
  badge: 'Communes · Intercommunalités',
  titleLead: 'Un réseau local',
  titleAccent: 'au service de votre territoire.',
  titleEnd: '',
  intro:
    'Yuztoo renforce le lien entre habitants et commerces de proximité, sans dépendance aux plateformes globales. Un outil de politique publique pilotable, mesurable et souverain.',
  primaryCta: { label: 'Déployer sur ma commune', href: '#deployer' },
  secondaryCta: { label: 'Le constat', href: '#constat' },
  checks: ['Conforme RGPD', 'Données locales, non revendues', 'Reporting mensuel'],
  report: {
    title: 'Rapport mensuel',
    period: 'Aperçu illustratif',
    kpis: [
      { id: 'shops', label: 'Commerçants activés', icon: 'store' },
      { id: 'users', label: 'Habitants inscrits', icon: 'users' },
      { id: 'visits', label: 'Fréquence de visite', icon: 'repeat' },
      { id: 'districts', label: 'Adoption par quartier', icon: 'map' },
    ],
    chartLabel: 'Vitalité du centre-ville',
    bars: [38, 46, 44, 55, 61, 58, 70, 76],
  },
  tag: { value: '40 %', label: 'De valeur gardée sur le territoire' },
}

export const COL_PROBLEM = {
  index: '01',
  eyebrow: 'Le constat',
  title: 'Un commerce local fragilisé, par dépendance plus que par manque de qualité.',
  lead: 'Le lien entre commerçants et habitants a été progressivement capté par des plateformes internationales.',
  platforms: ['Google', 'Meta', 'Uber', 'Amazon'],
  items: [
    { id: 'pay', kicker: 'Visibilité', title: 'Payer pour être visible', text: 'Les commerçants paient pour apparaître et pour recevoir des commandes en ligne.' },
    { id: 'relation', kicker: 'Relation', title: 'Une relation client confisquée', text: 'Le contact avec le client appartient à la plateforme, plus au commerce.' },
    { id: 'value', kicker: 'Valeur', title: 'La valeur quitte le territoire', text: 'Données et millions d’euros de valeur ajoutée partent hors de la ville.' },
    { id: 'centre', kicker: 'Centre-ville', title: 'Des centres-villes qui s’érodent', text: 'Malgré les politiques publiques, la fréquentation recule.' },
  ],
}

export const COL_IMPACT = {
  eyebrow: 'Déployer Yuztoo',
  title: 'Ce que votre commune y gagne.',
  stats: [
    { id: 'value', value: '40 %', label: 'De valeur ajoutée conservée', note: 'Ce qui partait en commissions reste dans l’économie locale.' },
    { id: 'commission', value: '0 %', label: 'Commission', note: 'Aucune logique de commission ni d’algorithme de mise en concurrence.' },
    { id: 'rgpd', value: 'RGPD', label: 'Strictement respecté', note: 'Les données de vos concitoyens restent protégées et locales.' },
  ],
}

export const COL_ANSWER = {
  index: '02',
  eyebrow: 'Une réponse souveraine',
  title: 'Yuztoo, un outil de politique publique territoriale.',
  points: [
    'Reconnecter les commerçants et les habitants',
    'Digitaliser sans dépendance aux plateformes globales',
    'Redynamiser les centres-villes de manière concrète',
    'Respecter strictement le RGPD',
    'Supprimer les logiques de commission et d’algorithme',
  ],
  highlight:
    'Chaque commerçant accède à un niveau de digitalisation équivalent à celui d’une franchise nationale, sans dépendance ni surcoût.',
  quote: 'Yuztoo ne crée pas de concurrence. Il renforce l’écosystème local existant.',
}

export const COL_PROMISE = {
  index: '03',
  eyebrow: 'La promesse',
  title: 'Trois engagements pour la collectivité.',
  columns: [
    {
      id: 'controle',
      title: 'Reprendre le contrôle',
      items: ['Relation client maîtrisée par les commerçants', 'Données locales, non revendues', 'Aucun algorithme de mise en concurrence'],
    },
    {
      id: 'centre',
      title: 'Redynamiser le centre-ville',
      items: ['Fréquentation en hausse', 'Habitants fidélisés', 'Indépendants plus visibles'],
    },
    {
      id: 'confiance',
      title: 'Un cercle de confiance',
      items: ['Accès fondé sur les usages réels', 'Recommandations entre commerçants', 'Un bouche-à-oreille numérique sain'],
    },
  ],
}

export const COL_BENEFITS = {
  index: '04',
  eyebrow: 'Bénéfices',
  title: 'Pour les habitants, la mairie et les commerçants.',
  columns: [
    {
      id: 'habitants',
      title: 'Habitants',
      items: [
        'Un carnet numérique de leurs commerces',
        'Des informations utiles en temps réel',
        'Une fidélité valorisée localement',
        'Moins de dépendance aux moteurs de recherche',
      ],
    },
    {
      id: 'mairie',
      title: 'Mairie',
      items: [
        'Engagement : commerçants activés et utilisateurs',
        'Fréquence de visite et adoption par quartier',
        'Activité commerciale et dynamique du réseau',
        'Vitalité du centre-ville',
      ],
      note: 'Reporting mensuel des indicateurs d’impact.',
    },
    {
      id: 'commercants',
      title: 'Commerçants',
      items: [
        'Une relation directe avec leurs clients',
        'Une base client qui leur appartient',
        'Un outil simple de fidélisation',
        'Une alternative aux plateformes globales',
      ],
    },
  ],
}

export const COL_INVEST = {
  eyebrow: 'Yuztoo n’est pas une dépense',
  title: 'C’est une infrastructure numérique locale, humaine et durable.',
  items: [
    { id: 'souverainete', icon: 'shield', title: 'Souveraineté numérique', text: 'Un investissement qui garde le lien et les données sur le territoire.' },
    { id: 'levier', icon: 'trending', title: 'Redynamisation commerciale', text: 'Un levier concret pour la fréquentation des commerces.' },
    { id: 'durable', icon: 'building', title: 'Infrastructure durable', text: 'Un réseau local qui reste, quelle que soit la plateforme du moment.' },
    { id: 'cout', icon: 'eye', title: 'Sans coûts cachés', text: 'Sans dépendance ni commission sur l’activité des commerces.' },
  ],
}

export const COL_FAQ = {
  index: '05',
  eyebrow: 'Questions fréquentes',
  title: 'Ce que les élus et les services nous demandent',
  items: [
    {
      id: 'mesure',
      question: 'Que mesure le reporting fourni à la mairie ?',
      answer: 'Un reporting mensuel : nombre de commerçants activés et d’utilisateurs, fréquence de visite et adoption par quartier, activité commerciale et dynamique du réseau, vitalité du centre-ville.',
    },
    {
      id: 'rgpd',
      question: 'Comment sont protégées les données des habitants ?',
      answer: 'Yuztoo respecte strictement le RGPD. Les données restent locales, ne sont jamais revendues, et aucune publicité n’est diffusée aux habitants.',
    },
    {
      id: 'concurrence',
      question: 'Yuztoo met-il les commerces en concurrence ?',
      answer: 'Non. Yuztoo ne crée pas de concurrence : il renforce l’écosystème local existant, sans algorithme de mise en concurrence entre commerçants.',
    },
    {
      id: 'deploiement',
      question: 'Comment déployer Yuztoo sur notre commune ?',
      answer: `Écrivez-nous ou appelez-nous pour une présentation à vos élus et à vos services. ${NETWORK.city} est notre territoire pilote.`,
    },
  ],
}

export const COL_START = {
  eyebrow: 'Déployer Yuztoo',
  title: 'Parlons de votre territoire',
  lead: `${NETWORK.city} est notre territoire pilote. Présentons le dispositif à vos élus et à vos services, et construisons ensemble le réseau de votre commune.`,
  mailCta: {
    label: 'Demander une présentation',
    href: `mailto:${CONTACT.email}?subject=${encodeURIComponent('Déployer Yuztoo sur notre commune')}`,
  },
  promise: [
    { id: 'pilot', value: NETWORK.city, label: 'Territoire pilote' },
    { id: 'shops', value: String(NETWORK.partners), label: 'Commerces partenaires' },
    { id: 'rgpd', value: 'RGPD', label: 'Conformité stricte' },
  ],
}
