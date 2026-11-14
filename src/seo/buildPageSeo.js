/**
 * Builds the SEO object for an inner page: canonical, Open Graph, and a
 * JSON-LD graph with WebPage + BreadcrumbList (+ FAQPage when `faq` is given).
 * Extra schema.org nodes go in `graph`.
 */

import { SITE, absoluteUrl } from '../siteConfig.js'

const DEFAULT_OG = {
  image: absoluteUrl('/images/og/yuztoo-accueil.jpg'),
  imageWidth: 1200,
  imageHeight: 630,
  imageAlt: 'Une plaque Yuztoo posée sur le comptoir d’un commerce de proximité',
}

export function buildPageSeo({ path, title, description, crumb, faq, audience, graph = [] }) {
  const url = absoluteUrl(path)

  const nodes = [
    {
      '@type': 'WebPage',
      '@id': `${url}/#webpage`,
      url,
      name: title,
      inLanguage: SITE.lang,
      isPartOf: { '@id': `${SITE.origin}/#organization` },
      ...(audience ? { audience } : {}),
    },
    {
      '@type': 'BreadcrumbList',
      itemListElement: [
        { '@type': 'ListItem', position: 1, name: 'Accueil', item: absoluteUrl('/') },
        { '@type': 'ListItem', position: 2, name: crumb, item: url },
      ],
    },
    ...graph,
  ]

  if (faq) {
    nodes.push({
      '@type': 'FAQPage',
      mainEntity: faq.map((item) => ({
        '@type': 'Question',
        name: item.question,
        acceptedAnswer: { '@type': 'Answer', text: item.answer },
      })),
    })
  }

  return {
    path,
    title,
    description,
    canonical: url,
    robots: 'index, follow, max-image-preview:large',
    og: { type: 'website', ...DEFAULT_OG },
    jsonLd: [{ '@context': 'https://schema.org', '@graph': nodes }],
  }
}
