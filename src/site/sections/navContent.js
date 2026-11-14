/** Header and footer copy. No JSX. */

import { CONTACT, NETWORK } from '../../siteConfig.js'

export const NAV_LINKS = [
  { href: '/', label: 'Accueil' },
  { href: '/pour-commercants', label: 'Commerçants' },
  { href: '/pour-clients', label: 'Clients' },
  { href: '/pour-collectivites', label: 'Collectivités' },
  { href: '/a-propos', label: 'À propos' },
]

export const NAV_CTA = { href: '/contact', label: 'Tester gratuitement' }

export const UTILITY = {
  location: `${CONTACT.city}, France`,
  promise: 'Sans commission · Sans publicité',
  network: `${NETWORK.partners} commerces partenaires`,
}

export const LOGO = {
  src: '/images/yuztoo/yuztoo-mascotte-logo.webp',
  width: 84,
  height: 96,
}

export const FOOTER = {
  tagline:
    'Yuztoo relie les commerces de proximité à leurs clients. Sans publicité, sans commission, sans dépendance.',
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
        { href: '/contact', label: 'Contact' },
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
  legal: '© 2026 Yuztoo. Tous droits réservés.',
  madeIn: `Conçu à ${NETWORK.city} · ${NETWORK.department}`,
}
