/**
 * « À propos » copy and images. No JSX.
 * Source: the live /a-propos-de-nous/ page.
 */

import { CONTACT, NETWORK } from '../../siteConfig.js'

export const ABOUT_HERO = {
  crumb: 'À propos',
  badge: `Né à ${NETWORK.city}`,
  titleLead: 'Redonner vie',
  titleAccent: 'au commerce local.',
  titleEnd: '',
  intro:
    'YuzToo est né d’un constat simple : le lien entre les commerçants et leurs clients a été capté par des plateformes globales, au détriment du local. Nous l’avons créé pour changer cela.',
  primaryCta: { label: 'Nous contacter', href: '#contact' },
  secondaryCta: { label: 'Notre fondateur', href: '#fondateur' },
  image: {
    src: '/images/yuztoo/yuztoo-mascotte-belfort.webp',
    alt: 'La mascotte YuzToo posée sur le panneau d’entrée de Belfort',
    width: 1000,
    height: 1500,
  },
  tag: { value: NETWORK.department, label: 'Territoire de Belfort' },
}

export const ABOUT_MISSION = {
  index: '01',
  eyebrow: 'Notre mission',
  title: 'Rendre aux commerçants leur relation client, et aux habitants leurs commerces.',
  paragraphs: [
    'Notre mission est de redonner aux commerçants la maîtrise de leur relation client, tout en permettant aux habitants de retrouver facilement leurs commerces de proximité.',
    'Un seul objectif : recréer un lien direct, durable et humain entre les commerces et les habitants.',
  ],
  quote: 'YuzToo n’est pas une plateforme de plus. C’est un outil local, pensé pour être simple, utile et accessible à tous.',
}

export const ABOUT_VISION = {
  index: '02',
  eyebrow: 'Notre vision',
  title: 'Nous croyons en un commerce',
  words: ['Plus proche', 'Plus humain', 'Plus juste'],
  whereTitle: 'Un commerce où',
  where: [
    { id: 'data', title: 'Les données restent locales' },
    { id: 'direct', title: 'Les échanges sont directs' },
    { id: 'value', title: 'La valeur profite au territoire' },
  ],
  punch: 'Une alternative concrète, loin des algorithmes et des commissions.',
}

export const ABOUT_FOUNDER = {
  index: '03',
  eyebrow: 'Le fondateur',
  name: 'Pascal Guyomar',
  role: 'Fondateur de YuzToo',
  paragraphs: [
    `YuzToo est né à ${NETWORK.city}, comme son fondateur, profondément attaché à son territoire. Enfant du FIMU, des rues animées et des commerces de proximité, il a grandi au cœur de cette vie locale qui fait l’âme d’une ville.`,
    'Après plus de 20 ans dans la gestion de projets industriels, il choisit de revenir à l’essentiel : redonner du sens et de la force à l’économie locale.',
    'Avec YuzToo, il porte une vision simple mais ambitieuse : recréer un lien direct entre les habitants et leurs commerçants, pour que la valeur, les échanges et la vie restent là où tout commence, dans nos villes et nos villages.',
  ],
  goal: `Son objectif : faire de ${NETWORK.city} un territoire pilote, et prouver qu’une autre manière de consommer est possible.`,
  facts: [
    { id: 'years', value: '20+ ans', label: 'Projets industriels' },
    { id: 'city', value: NETWORK.city, label: 'Territoire pilote' },
  ],
  image: {
    src: '/images/yuztoo/yuztoo-fondateur.webp',
    alt: 'Pascal Guyomar, fondateur de YuzToo',
    width: 760,
    height: 1140,
  },
}

export const ABOUT_AMBITION = {
  eyebrow: 'Notre ambition',
  title: 'Une infrastructure numérique locale, simple et durable.',
  items: [
    { id: 'lien', icon: 'link', title: 'Un lien direct', text: 'Entre commerçants et clients, sans intermédiaire.' },
    { id: 'base', icon: 'database', title: 'Une base client maîtrisée', text: 'Locale, qui appartient au commerce.' },
    { id: 'reseau', icon: 'network', title: 'Un réseau de confiance', text: 'Des commerces qui se recommandent entre eux.' },
    { id: 'alt', icon: 'compass', title: 'Une alternative', text: 'Aux plateformes globales et à leurs commissions.' },
  ],
  punch: 'Et prouver qu’un modèle plus humain, plus local et plus équilibré est possible.',
}

export const ABOUT_CONTACT = {
  eyebrow: 'Prendre contact',
  title: 'Parlons de votre commerce, ou de votre ville',
  lead: `Commerçant, habitant ou élu : laissez-nous un message ou appelez-nous. Nous répondons nous-mêmes, depuis ${NETWORK.city}.`,
  form: {
    kind: 'contact',
    title: 'Écrire à l’équipe',
    messageLabel: 'Votre message',
    submit: 'Envoyer le message',
  },
}
