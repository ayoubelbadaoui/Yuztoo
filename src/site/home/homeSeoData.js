import { SITE, CONTACT, absoluteUrl } from '../../siteConfig.js'

const url = absoluteUrl('/')

const organization = {
  '@type': 'Organization',
  '@id': `${SITE.origin}/#organization`,
  name: 'Yuztoo',
  url: SITE.origin,
  email: CONTACT.email,
  telephone: CONTACT.phone,
  areaServed: {
    '@type': 'City',
    name: CONTACT.city,
    addressCountry: CONTACT.country,
  },
  description:
    'Yuztoo relie les commerces de proximité à leurs clients, sans commission ni dépendance aux plateformes.',
}

const softwareApplication = {
  '@type': 'SoftwareApplication',
  name: 'Yuztoo',
  applicationCategory: 'LifestyleApplication',
  operatingSystem: 'iOS, Android',
  offers: { '@type': 'Offer', price: '0', priceCurrency: 'EUR' },
  publisher: { '@id': `${SITE.origin}/#organization` },
}

const breadcrumb = {
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Accueil', item: url },
  ],
}

export const HOME_SEO = {
  path: '/',
  title: 'Yuztoo — Fidélisez vos clients sans commission ni plateforme',
  description:
    'Yuztoo relie les commerces de proximité à leurs clients grâce à une plaque à scanner en boutique. Sans publicité, sans commission, sans dépendance. Gratuit.',
  canonical: url,
  robots: 'index, follow, max-image-preview:large',
  og: {
    type: 'website',
    image: absoluteUrl('/images/og/yuztoo-accueil.jpg'),
    imageWidth: 1200,
    imageHeight: 630,
    imageAlt:
      'Une plaque Yuztoo posée sur le comptoir d’un commerce de proximité',
  },
  jsonLd: [
    {
      '@context': 'https://schema.org',
      '@graph': [
        organization,
        softwareApplication,
        breadcrumb,
        {
          '@type': 'WebPage',
          '@id': `${url}/#webpage`,
          url,
          name: 'Yuztoo — Fidélisez vos clients sans commission ni plateforme',
          inLanguage: SITE.lang,
          isPartOf: { '@id': `${SITE.origin}/#organization` },
        },
      ],
    },
  ],
}
