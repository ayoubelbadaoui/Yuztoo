import { buildPageSeo } from '../../seo/buildPageSeo.js'
import { COL_FAQ } from './collectivitesContent.js'

export const COLLECTIVITES_SEO = buildPageSeo({
  path: '/pour-collectivites',
  title: 'YuzToo pour les collectivités — Commerce local et territoire',
  description:
    'Déployez YuzToo sur votre commune : 40 % de valeur ajoutée conservée, commerces digitalisés sans plateforme, RGPD et reporting mensuel d’impact.',
  crumb: 'Collectivités',
  faq: COL_FAQ.items,
  audience: { '@type': 'Audience', audienceType: 'Collectivités territoriales' },
})
