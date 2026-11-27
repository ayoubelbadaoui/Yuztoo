/** Header and footer copy. No JSX. */

import { CONTACT, NETWORK } from '../../siteConfig.js'

export const NAV_LINKS = [
  { href: '/', label: 'Accueil' },
  { href: '/pour-commercants', label: 'Commerçants' },
  { href: '/pour-clients', label: 'Clients' },
  { href: '/pour-collectivites', label: 'Collectivités' },
  { href: '/a-propos', label: 'À propos' },
]

export const NAV_CTA = { href: '#telecharger', label: 'Tester gratuitement' }

export const THEME = { label: 'Mode sombre' }

export const UTILITY = {
  location: `${CONTACT.city}, France`,
  promise: 'Sans commission · Sans publicité',
  networkLabel: 'commerces partenaires',
}

export const LOGO = {
  src: '/images/yuztoo/yuztoo-mascotte-logo.webp',
  width: 84,
  height: 96,
}

export const FOOTER = {
  tagline:
    'YuzToo relie les commerces de proximité à leurs clients. Sans publicité, sans commission, sans dépendance.',
  columns: [
    {
      id: 'produit',
      title: 'Produit',
      links: [
        { href: '/pour-commercants', label: 'Pour les commerçants' },
        { href: '/pour-clients', label: 'Pour les clients' },
        { href: '/pour-collectivites', label: 'Pour les collectivités' },
        { href: '/telecharger', label: 'Télécharger l’app' },
      ],
    },
    {
      id: 'entreprise',
      title: 'Entreprise',
      links: [
        { href: '/a-propos', label: 'À propos' },
        { href: `mailto:${CONTACT.email}`, label: 'Contact' },
        { href: '/aide', label: 'Centre d’aide' },
      ],
    },
    {
      id: 'legal',
      title: 'Légal',
      links: [
        { href: '/cgu', label: 'Conditions d’utilisation' },
        { href: '/confidentialite', label: 'Politique de confidentialité' },
        { href: '/supprimer-compte', label: 'Supprimer mon compte' },
      ],
    },
  ],
  legal: '© 2026 YuzToo. Tous droits réservés.',
  madeIn: `Conçu à ${NETWORK.city} · ${NETWORK.department}`,
  status: `Actif à ${NETWORK.city} · ${NETWORK.partners} commerces`,
  soon: 'Bientôt',
  contact: [
    { id: 'mail', label: 'Écrire', kind: 'mail' },
    { id: 'phone', label: 'Appeler', kind: 'phone' },
    { id: 'city', label: 'Où', kind: 'city' },
  ],
  app: {
    title: 'L’application',
    stores: [
      { id: 'ios', label: 'App Store' },
      { id: 'android', label: 'Google Play' },
    ],
  },
  backToTop: 'Haut de page',
  wordmark: 'YuzToo',
}

/** « Téléchargez YuzToo » band shown above the footer on every page. */
export const DOWNLOAD = {
  id: 'telecharger',
  eyebrow: 'L’application',
  title: 'Téléchargez YuzToo, c’est gratuit',
  lead: 'L’application est déjà disponible. Commerçants, créez votre vitrine en quelques minutes. Clients, retrouvez tous vos commerces au même endroit.',
  audiences: [
    { id: 'pro', title: 'Commerçants', text: `Gratuit pour les ${NETWORK.pioneers} premiers commerçants*` },
    { id: 'client', title: 'Clients', text: 'Gratuit, sans publicité' },
  ],
  qrHint: 'Scannez avec votre téléphone',
  footnote: `*Offre pionniers réservée aux ${NETWORK.pioneers} premiers commerçants inscrits.`,
}
