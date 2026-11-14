import { buildPageSeo } from '../../seo/buildPageSeo.js'
import { PRO_FAQ } from './commercantsContent.js'

export const COMMERCANTS_SEO = buildPageSeo({
  path: '/pour-commercants',
  title: 'Yuztoo pour les commerçants — Fidélisation client gratuite',
  description:
    'Connectez vos clients à votre commerce d’un geste en boutique, relancez-les et fidélisez-les. Gratuit, sans commission ni plateforme. Belfort.',
  crumb: 'Commerçants',
  faq: PRO_FAQ.items,
  audience: { '@type': 'BusinessAudience', name: 'Commerces de proximité' },
})
