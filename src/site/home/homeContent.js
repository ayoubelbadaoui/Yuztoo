/**
 * Homepage copy, figures and images. No JSX, no imports from components.
 * See docs/holy-books/DDD_HOLY_BOOK.md §3.
 *
 * Figures come from the business and are stated on the current site.
 * Network figures live in siteConfig.NETWORK so the header strip and this
 * page never disagree.
 */

import { NETWORK } from '../../siteConfig.js'

export const HOME_HERO = {
  badge: `Né à ${NETWORK.city} · Phase de test`,
  titleLead: 'Vos clients reviennent',
  titleAccent: 'pour vous,',
  titleEnd: 'pas pour une plateforme.',
  intro:
    'Une plaque YuzToo sur votre comptoir. Vos clients la scannent, votre commerce entre dans leur téléphone, et la relation vous appartient. Sans commission, sans publicité.',
  primaryCta: { label: 'Tester gratuitement', href: '#telecharger' },
  secondaryCta: { label: 'Comment ça marche', href: '#fonctionnement' },
  storesLabel: 'Déjà disponible sur',
  /** Test phase + pioneer offer, right under the call to action. */
  pilot: {
    kicker: 'Phase de test',
    /** Owner wording: « YuzToo démarre en phase de test sur Belfort, Héricourt et Montbéliard ». */
    lead: 'YuzToo démarre en phase de test sur',
    cities: NETWORK.pilotCities,
    offer: `Gratuit pour les ${NETWORK.pioneers} premiers commerçants`,
    elsewhere: 'Vous souhaitez lancer YuzToo près de chez vous ?',
    elsewhereCta: { label: 'Contactez-nous !', href: '/a-propos#contact' },
  },
  proof: [
    { id: 'commission', icon: 'percent', value: '0 %', label: 'Commission' },
    { id: 'pub', icon: 'megaphone', value: '0 €', label: 'Publicité' },
    { id: 'network', icon: 'store', value: String(NETWORK.partners), label: 'Commerces partenaires' },
  ],
  image: {
    src: '/images/yuztoo/yuztoo-mascotte.webp',
    alt: 'La mascotte YuzToo, un oiseau bleu et jaune portant le badge YuzToo',
    width: 768,
    height: 880,
  },
  scanLabel: 'Scan en cours',
  plate: {
    /** TODO(owner): real plaque photo, e.g. '/images/yuztoo/yuztoo-plaque.webp'
        (square, ≥ 160 px). When set, it replaces the NFC icon in the card. */
    photo: null,
    kicker: 'Plaque YuzToo',
    name: 'Votre commerce',
    hint: 'Approchez votre téléphone',
  },
  commission: { value: '0 %', label: 'Prélevé sur vos ventes' },
}

export const HOME_PIZZA = {
  index: '01',
  eyebrow: 'Le problème',
  title: 'Une pizza à 18 €, commandée en ligne',
  lead: 'La commande passe par une plateforme de livraison. Voilà ce qu’il reste à chacun une fois le ticket refermé.',
  facts: [
    { id: 'client', value: '+30 %', label: 'payés en plus par le client' },
    { id: 'territoire', value: '40 %', label: 'de la valeur quitte le territoire' },
    { id: 'artisan', value: '≃ 10 €/h', label: 'pour l’artisan, charges déduites' },
  ],
  punchlineLead: 'Tout le monde y perd,',
  punchlineAccent: 'sauf la plateforme.',
  receipt: {
    header: 'Ticket de démonstration',
    number: 'N° 0018',
    item: { label: '1 × Pizza margherita', note: 'commandée via une plateforme', amount: '18,00 €' },
    lines: [
      { id: 'commission', label: 'Commission plateforme', amount: '− 6,50 €', tone: 'loss' },
      { id: 'reste', label: 'Reste à la pizzeria', amount: '11,50 €' },
    ],
    total: { label: 'Revenu de l’artisan', amount: '≃ 10 € / h' },
    footer: 'Merci de votre commande',
    stamp: { top: 'Sur YuzToo', value: '0 %', bottom: 'de commission' },
  },
}

export const HOME_STEPS = {
  index: '02',
  eyebrow: 'Comment ça marche',
  title: 'Trois gestes, et le lien est à vous',
  lead: 'Pas de commission, pas de contrat, pas de formation. Une plaque sur le comptoir suffit. Cliquez sur une étape pour la voir dans l’application.',
  videoCta: 'Voir la vidéo',
  videoKicker: 'Étape',
  image: {
    src: '/images/yuztoo/yuztoo-application-mobile.webp',
    alt: 'L’application YuzToo ouverte sur un téléphone, avec la mascotte à l’écran',
    width: 900,
    height: 985,
  },
  imageCaption: 'Application YuzToo · gratuite pour vos clients',
  steps: [
    {
      id: 'scan',
      video: { src: '/videos/yuztoo-scan.mp4', poster: '/videos/yuztoo-scan.webp', label: 'Chaque scan de votre plaque ajoute un client à votre liste.' },
      icon: 'scan',
      title: 'Le client scanne',
      text: 'Il approche son téléphone de la plaque posée sur votre comptoir. Votre commerce entre dans son carnet.',
      tag: 'Sur votre comptoir',
    },
    {
      id: 'suit',
      video: { src: '/videos/yuztoo-notification.mp4', poster: '/videos/yuztoo-notification.webp', label: 'Écrivez un message, il arrive dans la poche de vos clients.' },
      icon: 'bell',
      title: 'Il vous suit',
      text: 'Vous lui parlez directement : nouveautés, horaires, promotions. Sans intermédiaire.',
      tag: 'En direct',
    },
    {
      id: 'revient',
      video: { src: '/videos/yuztoo-fidelite.mp4', poster: '/videos/yuztoo-fidelite.webp', label: 'Activez la fidélité : chaque passage validé le rapproche de sa récompense.' },
      icon: 'repeat',
      title: 'Il revient pour vous',
      text: 'Votre fidélité vit dans son téléphone. Il revient pour votre commerce, pas pour une plateforme.',
      tag: 'Dans son carnet',
    },
  ],
}

export const HOME_BENEFITS = {
  index: '04',
  eyebrow: 'Ce que ça change',
  title: 'Pour votre commerce',
  lead: 'Les chiffres constatés chez nos commerçants partenaires.',
  featured: {
    kicker: 'Constaté chez nos partenaires',
    figure: '+20 %',
    label: 'de marge sur vos ventes en direct',
    note: 'Chaque vente qui passe par vous plutôt que par une plateforme reste entière dans votre caisse.',
    facts: [
      { label: 'Fréquentation', value: '+10 à 15 %' },
      { label: 'Commission', value: '0 €' },
      { label: 'Communication', value: '0 €' },
      { label: 'Engagement', value: 'Sans engagement' },
    ],
  },
  photo: {
    src: '/images/yuztoo/yuztoo-commercants-boulangerie.webp',
    alt: 'Un boulanger et sa collègue montrant l’application YuzToo à un client au comptoir',
    width: 1200,
    height: 1200,
    caption: 'Au comptoir, à Belfort',
  },
  items: [
    {
      id: 'relation',
      icon: 'users',
      title: 'Vos clients restent les vôtres',
      text: 'Le lien passe par votre commerce, pas par un intermédiaire qui revend l’accès à vos propres clients.',
      metric: 'Relation directe',
    },
    {
      id: 'simple',
      icon: 'graduation',
      title: 'Rien à apprendre',
      text: 'Nous installons la plaque et nous vous accompagnons. Vous continuez votre métier.',
      metric: 'Installation offerte',
    },
  ],
  strip: {
    text: 'Envie de voir ce que ça donne sur votre commerce ? Nous installons la plaque gratuitement.',
    cta: 'Tester gratuitement',
    href: '#telecharger',
  },
}

export const HOME_COVERAGE = {
  index: '05',
  eyebrow: 'Sur le terrain',
  title: 'YuzToo commence à Belfort',
  lead: `YuzToo démarre en phase de test sur ${NETWORK.pilotCities.join(', ').replace(/, ([^,]*)$/, ' et $1')}. Nous construisons le réseau commerce par commerce, rue par rue.`,
  image: {
    src: '/images/yuztoo/yuztoo-mascotte-belfort.webp',
    alt: 'La mascotte YuzToo posée sur le panneau d’entrée de ville de Belfort',
    width: 1000,
    height: 1500,
  },
  imageBadge: { value: NETWORK.department, label: 'Territoire de Belfort' },
  meter: {
    kicker: 'Réseau YuzToo',
    current: NETWORK.partners,
    target: NETWORK.target,
    currentLabel: 'commerces présents',
    targetLabel: 'commerces visés',
    segments: 30,
  },
  points: [
    { id: 'villes', value: `${NETWORK.pilotCities.length} villes`, label: NETWORK.pilotCities.join(' · ') },
    { id: 'valeur', value: '40 %', label: 'de valeur conservée sur le territoire' },
  ],
  elsewhere: {
    text: 'Vous souhaitez lancer YuzToo près de chez vous ?',
    cta: { label: 'Contactez-nous !', href: '/a-propos#contact' },
  },
}

export const HOME_TESTIMONIALS = {
  index: '06',
  eyebrow: 'La parole aux commerçants',
  title: 'Ils font vivre nos quartiers',
  lead: 'Chaque jour, ils créent du lien, conseillent, rendent service. Nous leur avons posé une seule question.',
  question: 'Pourquoi tu fais ça ?',
  quotes: [
    {
      id: 'salon-de-the',
      icon: 'coffee',
      quote: 'Je fais ça pour le lien, et parce que manger des gâteaux ça rassemble, tout simplement.',
      author: 'Mon salon de thé',
      role: 'Belfort',
    },
    {
      id: 'pisciniste',
      icon: 'waves',
      quote: 'Je fais ça parce que j’aime ce métier, et j’aime beaucoup les gens.',
      author: 'Mon pisciniste',
      role: 'Belfort',
    },
    {
      id: 'epicier',
      icon: 'basket',
      quote: 'Je fais ça parce que ça me plaît, pour voir des amis, et parce que j’aime le fromage surtout.',
      author: 'Mon épicier',
      role: 'Belfort',
    },
  ],
}

export const HOME_FOUNDER = {
  index: '07',
  eyebrow: 'Notre ambition',
  quote:
    'Les commerçants paient pour recevoir des commandes, et leurs clients ne leur appartiennent plus. Nous voulons remettre la relation là où elle a toujours eu sa place : dans la boutique.',
  author: 'L’équipe YuzToo',
  role: 'Belfort',
  image: {
    src: '/images/yuztoo/yuztoo-fondateur.webp',
    alt: 'Portrait en noir et blanc de Pascal Guyomar, fondateur de YuzToo, la mascotte posée sur son épaule',
    width: 760,
    height: 1140,
  },
  imageBadge: { value: 'Pascal Guyomar', label: 'Fondateur · Belfort' },
}

export const HOME_AUDIENCES = {
  index: '08',
  eyebrow: 'Par où commencer',
  title: 'YuzToo, pour qui ?',
  cards: [
    {
      id: 'commercants',
      icon: 'store',
      title: 'Vous êtes commerçant',
      text: 'Reprenez la main sur votre relation client et faites revenir les gens pour vous.',
      cta: 'L’offre commerçant',
      href: '/pour-commercants',
    },
    {
      id: 'clients',
      icon: 'phone',
      title: 'Vous êtes client',
      text: 'Gardez tous vos commerces de proximité dans votre poche, et profitez de leurs avantages.',
      cta: 'Découvrir l’app',
      href: '/pour-clients',
    },
    {
      id: 'collectivites',
      icon: 'landmark',
      title: 'Vous représentez une collectivité',
      text: 'Conservez 40 % de la valeur ajoutée sur votre territoire et soutenez vos commerces.',
      cta: 'Déployer sur ma commune',
      href: '/pour-collectivites',
    },
  ],
}

export const HOME_CLOSING = {
  eyebrow: 'Prochaine étape',
  title: 'Testez YuzToo sur votre commerce',
  lead: `Gratuit pour les ${NETWORK.pioneers} premiers commerçants, et toujours gratuit pour vos clients. Nous installons la plaque et nous vous accompagnons.`,
  primaryCta: { label: 'Nous contacter', href: '/pour-commercants#demarrer' },
  image: {
    src: '/images/yuztoo/yuztoo-mascotte.webp',
    alt: '',
    width: 768,
    height: 880,
  },
  plate: { kicker: 'Installation', value: 'Offerte', note: 'Plaque posée par notre équipe' },
}

export const HOME_SHOWCASE = {
  index: '03',
  eyebrow: 'L’application',
  title: 'Tout votre commerce, dans une seule app',
  lead: 'Ce que vous voyez ici, ce sont les vrais écrans de YuzToo.',
  chapters: [
    {
      id: 'vitrine',
      kicker: 'Vitrine',
      title: 'Votre commerce, en ligne en quelques minutes',
      text: 'Horaires, adresse, actualité : tout ce que vos clients cherchent, à jour depuis votre téléphone.',
    },
    {
      id: 'badge',
      kicker: 'Plaque NFC',
      title: 'Un geste au comptoir',
      text: 'Programmez la plaque une fois. Vos clients n’ont qu’à approcher leur téléphone pour vous retrouver.',
    },
    {
      id: 'fidelite',
      kicker: 'Fidélité',
      title: 'Une carte de fidélité, sans carton',
      text: 'Vous fixez la règle et la récompense. Chaque passage est validé en boutique, rien ne se perd.',
    },
    {
      id: 'promotions',
      kicker: 'Promotions',
      title: 'Vos offres, publiées en un geste',
      text: 'Une offre du jour, des invendus à écouler, un happy hour programmé : c’est en ligne tout de suite.',
    },
    {
      id: 'notification',
      kicker: 'Notifications',
      title: 'Un message, droit dans leur poche',
      text: 'Pas d’algorithme entre vous et vos clients : ce que vous envoyez, ils le reçoivent.',
    },
  ],
}
