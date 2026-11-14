import { SITE, absoluteUrl } from '../../siteConfig.js'
import { PRO_FAQ } from './commercantsContent.js'

const path = '/pour-commercants'
const url = absoluteUrl(path)
const title = 'Yuztoo pour les commerçants — Fidélisation client gratuite'

export const COMMERCANTS_SEO = {
  path,
  title,
  description:
    'Connectez vos clients à votre commerce d’un geste en boutique, relancez-les et fidélisez-les. Gratuit, sans commission ni plateforme. Belfort.',
  canonical: url,
  robots: 'index, follow, max-image-preview:large',
  og: {
    type: 'website',
    image: absoluteUrl('/images/og/yuztoo-accueil.jpg'),
    imageWidth: 1200,
    imageHeight: 630,
    imageAlt: 'Une plaque Yuztoo posée sur le comptoir d’un commerce de proximité',
  },
  jsonLd: [
    {
      '@context': 'https://schema.org',
      '@graph': [
        {
          '@type': 'WebPage',
          '@id': `${url}/#webpage`,
          url,
          name: title,
          inLanguage: SITE.lang,
          isPartOf: { '@id': `${SITE.origin}/#organization` },
          about: { '@id': `${SITE.origin}/#organization` },
          audience: { '@type': 'BusinessAudience', name: 'Commerces de proximité' },
        },
        {
          '@type': 'BreadcrumbList',
          itemListElement: [
            { '@type': 'ListItem', position: 1, name: 'Accueil', item: absoluteUrl('/') },
            { '@type': 'ListItem', position: 2, name: 'Commerçants', item: url },
          ],
        },
        {
          '@type': 'FAQPage',
          mainEntity: PRO_FAQ.items.map((item) => ({
            '@type': 'Question',
            name: item.question,
            acceptedAnswer: { '@type': 'Answer', text: item.answer },
          })),
        },
      ],
    },
  ],
}
