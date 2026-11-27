import { absoluteUrl } from '../siteConfig.js'

export const NOT_FOUND_SEO = {
  path: '/404',
  title: 'Page introuvable — YuzToo',
  description:
    'Cette page n’existe pas ou a été déplacée. Retrouvez YuzToo et vos commerces de proximité depuis l’accueil.',
  canonical: absoluteUrl('/404'),
  robots: 'noindex, follow',
  og: { type: 'website' },
  jsonLd: [],
}
