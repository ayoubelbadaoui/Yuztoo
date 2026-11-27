import { SITE, absoluteUrl } from '../../siteConfig.js'
import { buildPageSeo } from '../../seo/buildPageSeo.js'
import { ABOUT_FOUNDER } from './aproposContent.js'

export const APROPOS_SEO = buildPageSeo({
  path: '/a-propos',
  title: 'À propos de YuzToo — Redonner vie au commerce local',
  description:
    'YuzToo est né à Belfort pour rendre aux commerçants leur relation client. Notre mission, notre vision et notre fondateur, Pascal Guyomar.',
  crumb: 'À propos',
  graph: [
    {
      '@type': 'Person',
      '@id': `${SITE.origin}/#fondateur`,
      name: ABOUT_FOUNDER.name,
      jobTitle: ABOUT_FOUNDER.role,
      image: absoluteUrl(ABOUT_FOUNDER.image.src),
      worksFor: { '@id': `${SITE.origin}/#organization` },
    },
  ],
})
