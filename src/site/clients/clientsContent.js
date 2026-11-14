/**
 * « Pour les clients » copy and images. No JSX.
 * Source: the live /espace-client/ page. Shop names, messages and loyalty
 * counts in the mocks are illustrative and labelled as such.
 */

import { CONTACT, NETWORK } from '../../siteConfig.js'

export const CLI_HERO = {
  crumb: 'Clients',
  badge: `Habitants · ${NETWORK.city}`,
  titleLead: 'Tous vos commerces de proximité,',
  titleAccent: 'dans votre poche.',
  titleEnd: '',
  intro:
    'Une seule application pour retrouver vos commerçants du quotidien, recevoir leurs vraies nouvelles et profiter de leur fidélité. Sans publicité, sans algorithme, sans revente de vos données.',
  primaryCta: { label: 'Comment ça marche', href: '#carnet' },
  checks: ['Gratuit', 'Sans publicité ni IA', 'Vos données restent à vous'],
  phone: {
    time: '9:41',
    title: 'Mon carnet',
    label: 'Aperçu illustratif',
    shops: [
      { id: 'boulangerie', name: 'Boulangerie du Lion', kind: 'Boulangerie', stamps: 7, total: 8 },
      { id: 'fromagerie', name: 'La Fromagerie', kind: 'Épicerie fine', stamps: 3, total: 10 },
      { id: 'the', name: 'Le Salon de thé', kind: 'Salon de thé', stamps: 5, total: 6 },
      { id: 'fleurs', name: 'Atelier Fleurs', kind: 'Fleuriste', stamps: 1, total: 5 },
    ],
  },
  tag: { value: '1 appli', label: 'Pour tous vos commerces' },
}

export const CLI_WHY = {
  index: '01',
  eyebrow: 'Pourquoi Yuztoo',
  title: 'Soutenez vos commerces de proximité. Et ce n’est pas tout.',
  items: [
    { id: 'produit', icon: 'shield', title: 'Ne soyez plus le produit', text: 'Pas de plateforme qui revend votre attention ou vos habitudes.' },
    { id: 'artisans', icon: 'heart', title: 'Rémunérez mieux vos artisans', text: 'Sans commission, ce que vous payez reste chez votre commerçant.' },
    { id: 'infos', icon: 'bell', title: 'Seulement les infos qui comptent', text: 'Des messages de vos commerces, sans publicité ni IA.' },
    { id: 'appli', icon: 'smartphone', title: 'Une seule appli', text: 'Tous vos commerces préférés au même endroit.' },
    { id: 'fidelite', icon: 'gift', title: 'Votre fidélité reconnue', text: 'Cumulez vos passages et faites des économies.' },
    { id: 'local', icon: 'map', title: 'Que du local', text: 'Les adresses du quartier, recommandées par des pros.' },
  ],
}

export const CLI_STEPS = {
  index: '02',
  eyebrow: 'Simple et immédiat',
  title: 'Tous vos commerces. Au même endroit.',
  steps: [
    { id: 'scan', icon: 'scan', title: 'Scannez en boutique', text: 'Approchez votre téléphone de la plaque Yuztoo, ou scannez le QR code.' },
    { id: 'add', icon: 'book', title: 'Ajoutez au carnet', text: 'Le commerce rejoint votre carnet Yuztoo en un geste.' },
    { id: 'access', icon: 'info', title: 'Tout en un clic', text: 'Horaires, nouveautés, offres et fidélité : tout est là.' },
  ],
  quote: 'Fini de chercher partout : vos commerces habituels et leurs offres, au même endroit.',
  image: {
    src: '/images/yuztoo/yuztoo-application-mobile.webp',
    alt: 'L’application Yuztoo ouverte sur un téléphone, avec le carnet des commerces de proximité',
    width: 900,
    height: 985,
  },
  imageCaption: 'Application Yuztoo · gratuite',
}

export const CLI_MESSAGES = {
  index: '03',
  eyebrow: 'Infos & fidélité',
  title: 'Les bonnes infos, au bon moment. Et votre fidélité récompensée.',
  lead: 'Des messages utiles de vos commerces, pas de publicité. Vos avantages suivis en temps réel.',
  shop: 'Vos commerces',
  columns: [
    {
      id: 'infos',
      title: 'Recevez les bonnes infos',
      points: ['Offres ciblées', 'Nouveautés', 'Infos importantes'],
      examples: [
        { id: 'a', emoji: '🥐', text: 'Votre boulanger sort les croissants.' },
        { id: 'b', emoji: '🏷️', text: '−20 % aujourd’hui sur les invendus.' },
        { id: 'c', emoji: '📅', text: 'Ouverture exceptionnelle ce dimanche.' },
      ],
      punch: 'Pas de publicité inutile. Juste ce qui vous concerne.',
    },
    {
      id: 'fidelite',
      title: 'Profitez de la fidélité',
      points: ['Avantages en temps réel', 'Récompenses accessibles', 'Offres personnalisées'],
      examples: [
        { id: 'a', emoji: '🎁', text: 'Plus qu’1 passage pour votre cadeau.' },
        { id: 'b', emoji: '✅', text: 'Votre récompense est disponible.' },
        { id: 'c', emoji: '⭐', text: 'Offre spéciale pour nos clients fidèles.' },
      ],
      punch: 'Vous êtes reconnu. Vous êtes récompensé.',
    },
  ],
}

export const CLI_LOCAL = {
  index: '04',
  eyebrow: 'Confiance & relation directe',
  title: 'Les bonnes adresses par confiance, et vos commerçants à portée de message.',
  recommend: {
    title: 'Découvrez par recommandation',
    text: 'Vos commerçants vous recommandent d’autres commerces de confiance.',
    points: ['Pas d’algorithme', 'Pas de pub intrusive', 'Que du local, validé par des pros'],
  },
  chat: {
    title: 'Parlez directement à vos commerçants',
    text: 'Une question, une réservation, une disponibilité : demandez directement.',
    label: 'Exemples de messages',
    bubbles: [
      { id: 'a', from: 'client', text: 'Il vous reste des éclairs ?' },
      { id: 'b', from: 'shop', text: 'Oui, encore 4 ! Je vous en mets de côté ?' },
      { id: 'c', from: 'client', text: 'Je peux passer à 18 h ?' },
    ],
    punch: 'Comme en boutique… mais en mieux.',
  },
}

export const CLI_DATA = {
  eyebrow: 'Vos données restent à vous',
  title: 'Vous choisissez vos commerces. Vous gardez le contrôle.',
  stats: [
    { id: 'resale', value: '0', label: 'Revente de données', note: 'Vos informations ne sont jamais vendues.' },
    { id: 'ads', value: '0', label: 'Publicité invasive', note: 'Seuls vos commerces vous écrivent.' },
    { id: 'platform', value: '0', label: 'Plateforme entre vous', note: 'Le lien est direct, de vous à votre commerçant.' },
  ],
}

export const CLI_FAQ = {
  index: '05',
  eyebrow: 'Questions fréquentes',
  title: 'Ce que les habitants nous demandent',
  items: [
    {
      id: 'prix',
      question: 'Yuztoo est-il gratuit pour les clients ?',
      answer: 'Oui. L’application est gratuite pour les clients, comme pour les commerçants. Aucun abonnement, aucune publicité.',
    },
    {
      id: 'ajout',
      question: 'Comment ajouter un commerce à mon carnet ?',
      answer: 'En boutique, approchez votre téléphone de la plaque Yuztoo ou scannez le QR code affiché. Le commerce rejoint votre carnet immédiatement.',
    },
    {
      id: 'donnees',
      question: 'Mes données sont-elles revendues ?',
      answer: 'Non. Yuztoo ne revend pas vos données et ne vous expose à aucune publicité. Seuls les commerces que vous avez choisis peuvent vous écrire.',
    },
    {
      id: 'messages',
      question: 'Vais-je recevoir beaucoup de notifications ?',
      answer: 'Vous ne recevez que les messages des commerces de votre carnet : offres, nouveautés, infos importantes. Pas de publicité, pas de contenu suggéré par un algorithme.',
    },
    {
      id: 'absent',
      question: 'Mon commerçant n’est pas sur Yuztoo, que faire ?',
      answer: `Parlez-lui de Yuztoo, ou écrivez-nous à ${CONTACT.email} : nous irons le rencontrer. C’est gratuit pour lui aussi.`,
    },
  ],
}

export const CLI_START = {
  eyebrow: 'Votre commerce préféré n’y est pas ?',
  title: 'Recommandez-le-nous',
  lead: 'Donnez-nous le nom de vos commerces préférés : nous allons les rencontrer et leur installer la plaque gratuitement.',
  mailCta: {
    label: 'Recommander un commerce',
    href: `mailto:${CONTACT.email}?subject=${encodeURIComponent('Je recommande un commerce à Yuztoo')}`,
  },
}
