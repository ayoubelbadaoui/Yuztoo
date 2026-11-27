import { buildPageSeo } from '../../seo/buildPageSeo.js'
import { PRO_FAQ } from './commercantsContent.js'

export const COMMERCANTS_SEO = buildPageSeo({
  path: '/pour-commercants',
  title: 'YuzToo pour les commerçants — Fidélisation client sans commission',
  description:
    'Connectez vos clients à votre commerce d’un geste en boutique, relancez-les et fidélisez-les. Offre pionniers, sans commission ni plateforme. Belfort.',
  crumb: 'Commerçants',
  faq: PRO_FAQ.items,
  audience: { '@type': 'BusinessAudience', name: 'Commerces de proximité' },
})
