import { buildPageSeo } from '../../seo/buildPageSeo.js'
import { CLI_FAQ } from './clientsContent.js'

export const CLIENTS_SEO = buildPageSeo({
  path: '/pour-clients',
  title: 'YuzToo pour les clients — Vos commerces dans votre poche',
  description:
    'Retrouvez vos commerces de proximité dans une seule appli : vraies nouvelles, fidélité récompensée, sans publicité ni revente de données. Gratuit.',
  crumb: 'Clients',
  faq: CLI_FAQ.items,
  audience: { '@type': 'PeopleAudience', name: 'Habitants et clients des commerces de proximité' },
})
