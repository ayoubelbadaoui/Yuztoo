/**
 * Route metadata — pure data, no JSX, so build scripts can import it directly
 * with plain Node. `routes.js` joins this to the page components and SEO data.
 *
 * This is the single source of truth for which paths exist. Adding a page means
 * adding an entry here; the prerenderer, the sitemap and the SEO gate follow.
 */

import { TUTORIALS } from './site/tutoriels/tutorielsContent.js'

export const ROUTE_META = [
  {
    path: '/',
    indexable: true,
    lastmod: '2026-11-14',
    changefreq: 'weekly',
    priority: '1.0',
  },
  {
    path: '/pour-commercants',
    indexable: true,
    lastmod: '2026-11-14',
    changefreq: 'monthly',
    priority: '0.9',
  },
  {
    path: '/pour-clients',
    indexable: true,
    lastmod: '2026-11-14',
    changefreq: 'monthly',
    priority: '0.8',
  },
  {
    path: '/pour-collectivites',
    indexable: true,
    lastmod: '2026-11-14',
    changefreq: 'monthly',
    priority: '0.8',
  },
  {
    path: '/a-propos',
    indexable: true,
    lastmod: '2026-11-14',
    changefreq: 'yearly',
    priority: '0.6',
  },
  {
    path: '/tutoriels',
    indexable: true,
    lastmod: '2026-11-28',
    changefreq: 'monthly',
    priority: '0.8',
  },
  ...TUTORIALS.map((t) => ({
    path: `/tutoriels/${t.slug}`,
    indexable: true,
    lastmod: '2026-11-28',
    changefreq: 'monthly',
    priority: '0.7',
  })),
  {
    path: '/confidentialite',
    indexable: true,
    lastmod: '2026-11-14',
    changefreq: 'yearly',
    priority: '0.3',
  },
  {
    path: '/merci',
    indexable: false,
  },
  {
    path: '/404',
    indexable: false,
  },
]
