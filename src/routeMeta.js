/**
 * Route metadata — pure data, no JSX, so build scripts can import it directly
 * with plain Node. `routes.js` joins this to the page components and SEO data.
 *
 * This is the single source of truth for which paths exist. Adding a page means
 * adding an entry here; the prerenderer, the sitemap and the SEO gate follow.
 */

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
    path: '/404',
    indexable: false,
  },
]
