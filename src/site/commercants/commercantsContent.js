/**
 * « Pour les commerçants » copy, figures and images. No JSX.
 * See docs/holy-books/DDD_HOLY_BOOK.md §3.
 *
 * Figures (10 à 15 %, +20 %, 0 €) are the ones stated on the live
 * /espace-commercant/ page. App visuals are real screenshots, see
 * src/site/appScreensContent.js.
 */

import { CONTACT, NETWORK } from '../../siteConfig.js'

export const PRO_HERO = {
  crumb: 'Commerçants',
  badge: 'Espace commerçants · Gratuit',
  titleLead: 'Vos clients,',
  titleAccent: 'dans votre poche.',
  titleEnd: 'Plus dans celle des plateformes.',
  intro:
    'Yuztoo connecte vos clients à votre commerce d’un simple geste en boutique. Ensuite, vous les retrouvez, vous les relancez et vous les fidélisez, sans commission ni intermédiaire.',
  primaryCta: { label: 'Démarrer gratuitement', href: '#demarrer' },
  secondaryCta: { label: 'Voir ce que ça change', href: '#constat' },
  checks: ['Sans compétence technique', 'Prêt en quelques minutes', 'Vos données restent à vous'],
  tag: { value: '0 €', label: 'Pour vous et vos clients' },
}

export const PRO_PAINS = {
  index: '01',
  eyebrow: 'Le constat',
  title: 'Vous payez cher une clientèle qui ne vous appartient pas.',
  lead: 'Sans base client à vous, chaque visite dépend d’un outil qui facture l’accès à vos propres clients.',
  items: [
    {
      id: 'lost',
      kicker: 'Visibilité',
      title: 'Vos clients partent vers les plateformes',
      text: 'Ils vous trouvent sur Google, Instagram ou Uber Eats, et c’est la plateforme qui garde le contact.',
      chips: ['Google', 'Instagram', 'Uber Eats'],
    },
    {
      id: 'rent',
      kicker: 'Abonnements',
      title: 'Vous louez votre propre clientèle',
      text: 'Réservation, annuaire, caisse, boutique en ligne : chaque outil prend sa part, et aucun ne vous rend vos clients.',
      chips: ['Planity', 'Pages Jaunes', 'SumUp', 'Shopify'],
    },
    {
      id: 'blind',
      kicker: 'Mesure',
      title: 'Vous ne savez pas qui revient',
      text: 'Gagnez-vous de nouveaux clients ? En perdez-vous ? Sans données à vous, impossible de le savoir.',
      chips: ['Aucune donnée'],
    },
  ],
}

export const PRO_IMPACT = {
  eyebrow: 'Ce que ça change',
  title: 'Augmentez la valeur de votre commerce.',
  stats: [
    { id: 'freq', value: '10 à 15 %', label: 'de fréquentation en plus', note: 'Les clients connectés reviennent plus souvent.' },
    { id: 'cost', value: '0 €', label: 'de frais de communication', note: 'Vos messages partent sans abonnement ni campagne payante.' },
    { id: 'margin', value: '+20 %', label: 'de marge', note: '100 % de vos clients en direct, sans commission.' },
  ],
}

export const PRO_SETUP = {
  index: '02',
  eyebrow: 'Simple. Gratuit. Unique.',
  title: 'Commencez en quelques minutes, sans compétence technique.',
  steps: [
    {
      id: 'vitrine',
      icon: 'store',
      title: 'Créez votre vitrine',
      text: 'En quelques minutes, votre commerce a sa page : horaires, photos, liens et actualités.',
    },
    {
      id: 'plaque',
      icon: 'nfc',
      title: 'Posez votre plaque',
      text: 'La plaque Yuztoo sur le comptoir, ou votre QR code affiché en vitrine.',
    },
    {
      id: 'scan',
      icon: 'scan',
      title: 'Le client scanne',
      text: 'Il pose son téléphone, et « hop » : il est connecté à votre établissement.',
    },
  ],
  quote: 'Un client connecté est un client que vous pouvez recontacter directement.',
  image: {
    src: '/images/yuztoo/yuztoo-commercants-boulangerie.webp',
    alt: 'Une boulangère sert un client au comptoir de sa boutique de quartier',
    width: 1200,
    height: 1200,
  },
  imageCaption: 'Sur votre comptoir · en boutique',
}

export const PRO_CLIENTS = {
  index: '03',
  eyebrow: 'Vos clients',
  title: 'Voyez qui vient, qui ne vient plus, et parlez-leur.',
  lead: 'Chaque passage est enregistré. Vous repérez vos habitués, vos VIP et vos nouveaux clients, puis vous les contactez en un clic.',
  board: {
    title: 'Vos clients',
    note: 'Aperçu illustratif',
    columns: ['Client', 'Passages', 'Statut'],
    rows: [
      { id: 'c1', name: 'Camille R.', visits: 24, status: 'vip', statusLabel: 'VIP' },
      { id: 'c2', name: 'Karim B.', visits: 11, status: 'regular', statusLabel: 'Habitué' },
      { id: 'c3', name: 'Léa M.', visits: 2, status: 'new', statusLabel: 'Nouveau' },
      { id: 'c4', name: 'Paul D.', visits: 8, status: 'away', statusLabel: 'Absent 3 sem.' },
    ],
    action: 'Envoyer une notification',
  },
  segments: [
    { id: 'vip', label: 'VIP', text: 'Remerciez ceux qui viennent le plus.' },
    { id: 'regular', label: 'Habitués', text: 'Gardez le lien au quotidien.' },
    { id: 'new', label: 'Nouveaux', text: 'Transformez un premier passage en habitude.' },
    { id: 'away', label: 'Inactifs', text: 'Relancez ceux qui ne viennent plus.' },
  ],
  ideasTitle: 'Quelques idées de messages',
  ideas: [
    'Ouverture exceptionnelle ce dimanche',
    '−20 % aujourd’hui sur les invendus',
    'Nouveau produit disponible dès 15 h',
    'Nouvelle carte à déguster',
  ],
  punchline: 'Ce ne sont plus des posts perdus dans les réseaux. Ce sont des actions mesurables : vous voyez qui ouvre et ce qui fonctionne.',
}

export const PRO_LOYALTY = {
  index: '04',
  eyebrow: 'Fidélité & réseau local',
  title: 'Une fidélité simple, et un quartier qui travaille pour vous.',

  columns: [
    {
      id: 'fidelite',
      title: 'Fidélité',
      items: [
        'Activable si vous le souhaitez',
        'X passages = une récompense',
        'Offres pour vos nouveaux clients, habitués ou VIP',
      ],
    },
    {
      id: 'auto',
      title: 'Automatisez',
      items: [
        'Souhaitez un bon anniversaire',
        'Relancez les clients qui ne viennent plus',
        'Offrez les récompenses sans y penser',
      ],
    },
    {
      id: 'reseau',
      title: 'Réseau local',
      items: [
        'Recommandez d’autres commerçants',
        'Soyez recommandé en retour',
        'Gagnez en visibilité dans le quartier',
      ],
    },
  ],
  punchline: 'Les clients du quartier deviennent tous vos clients.',
}

export const PRO_TOOLS = {
  index: '05',
  eyebrow: 'Un seul outil',
  title: 'Tout ce dont votre commerce a besoin, depuis votre téléphone.',
  features: [
    { id: 'talk', icon: 'message', title: 'Communiquez en direct', text: 'Infos, promos, actualités : publiez et mesurez l’impact.' },
    { id: 'track', icon: 'chart', title: 'Suivez la fréquentation', text: 'Qui vient, à quelle fréquence, et qui ne vient plus.' },
    { id: 'waste', icon: 'leaf', title: 'Écoulez vos invendus', text: 'Prévenez vos clients en fin de journée et limitez le gaspillage.' },
    { id: 'reviews', icon: 'star', title: 'Améliorez vos avis', text: 'Invitez vos clients à laisser un avis Google quand ils ont le temps.' },
    { id: 'links', icon: 'link', title: 'Gardez vos outils', text: 'Réservation, site, click & collect, fiche Google : ajoutez vos liens.' },
    { id: 'save', icon: 'wallet', title: 'Moins d’abonnements', text: 'Moins d’outils à payer, une seule application à ouvrir.' },
  ],
  tradesTitle: 'Pensé pour tous les métiers',
  trades: [
    { id: 'bouche', icon: 'croissant', label: 'Métiers de bouche' },
    { id: 'beaute', icon: 'sparkles', label: 'Beauté & bien-être' },
    { id: 'resto', icon: 'coffee', label: 'Restaurants & cafés' },
    { id: 'independants', icon: 'store', label: 'Commerces indépendants' },
    { id: 'artisans', icon: 'wrench', label: 'Services & artisans' },
    { id: 'sport', icon: 'dumbbell', label: 'Sport & loisirs' },
  ],
}

export const PRO_FAQ = {
  index: '06',
  eyebrow: 'Questions fréquentes',
  title: 'Ce que les commerçants nous demandent',
  items: [
    {
      id: 'prix',
      question: 'Combien coûte Yuztoo pour mon commerce ?',
      answer: 'Rien. Yuztoo est gratuit pour le commerçant comme pour ses clients : pas d’abonnement, pas de commission sur vos ventes, pas de publicité.',
    },
    {
      id: 'technique',
      question: 'Faut-il des compétences techniques ?',
      answer: 'Non. Vous créez votre vitrine en quelques minutes depuis votre téléphone, puis vous posez la plaque Yuztoo ou affichez votre QR code. Nous vous accompagnons pour l’installation.',
    },
    {
      id: 'donnees',
      question: 'À qui appartiennent les données de mes clients ?',
      answer: 'À vous. Vos clients se connectent à votre commerce, pas à une plateforme qui revendrait l’accès. Vous gardez la relation, même si vous changez d’outil.',
    },
    {
      id: 'fidelite',
      question: 'Le programme de fidélité est-il obligatoire ?',
      answer: 'Non. La fidélité s’active si vous le souhaitez. Vous choisissez le nombre de passages et la récompense.',
    },
    {
      id: 'outils',
      question: 'Puis-je garder mes outils actuels ?',
      answer: 'Oui. Ajoutez vos liens de réservation, votre site, votre click & collect ou votre fiche Google : vos clients les retrouvent sur votre vitrine Yuztoo.',
    },
    {
      id: 'metiers',
      question: 'Quels commerces peuvent utiliser Yuztoo ?',
      answer: 'Tous les commerces de proximité : métiers de bouche, beauté et bien-être, restaurants et cafés, commerces indépendants, services, artisans, sport et loisirs.',
    },
  ],
}

export const PRO_START = {
  eyebrow: 'Démarrer',
  title: 'Démarrez gratuitement',
  lead: `Laissez vos coordonnées : nous vous rappelons, nous installons la plaque sur votre comptoir à ${NETWORK.city} et nous vous accompagnons pour la prise en main.`,
  form: {
    kind: 'commercant',
    title: 'Être rappelé par l’équipe',
    orgLabel: 'Nom du commerce',
    orgAutoComplete: 'organization',
    messageLabel: 'Votre activité',
    messagePlaceholder: 'Boulangerie, coiffeur, restaurant…',
    submit: 'Être rappelé',
  },
  promise: [
    { id: 'free', value: '0 €', label: 'Abonnement' },
    { id: 'commission', value: '0 %', label: 'Commission' },
    { id: 'install', value: 'Offerte', label: 'Installation' },
  ],
}

export const PRO_CTA = {
  title: 'Prêt à garder le lien avec vos clients ?',
  text: 'Compte gratuit, plaque installée par notre équipe, sans engagement.',
  label: 'Être rappelé',
  href: '#demarrer',
}

/** Simulator: every figure comes from the merchant's own inputs. */
export const PRO_CALC = {
  eyebrow: 'Simulateur',
  title: 'Combien vous coûtent vraiment les plateformes ?',
  lead: 'Entrez vos propres chiffres. Le calcul se fait dans votre navigateur, rien n’est envoyé.',
  fields: [
    { id: 'basket', label: 'Panier moyen', unit: '€', min: 5, max: 80, step: 1, value: 18 },
    { id: 'orders', label: 'Commandes par mois via une plateforme', unit: '', min: 10, max: 1000, step: 10, value: 200 },
    { id: 'rate', label: 'Commission de la plateforme', unit: '%', min: 5, max: 40, step: 1, value: 30 },
  ],
  resultKicker: 'Versé aux plateformes chaque année',
  monthly: 'soit {value} par mois',
  yuztooKicker: 'Avec Yuztoo',
  yuztooValue: '0 €',
  yuztooNote: 'Aucune commission, aucun abonnement.',
  disclaimer: 'Simulation indicative, hors frais de livraison et de paiement.',
  cta: { label: 'Garder cet argent', href: '#demarrer' },
}
