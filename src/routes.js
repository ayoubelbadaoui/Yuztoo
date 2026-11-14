/**
 * The route table — joins the pure metadata in routeMeta.js to page components
 * and SEO data. Used by the router, the prerenderer and the SEO gate.
 *
 * A page that is not in routeMeta.js is not prerendered and fails the SEO gate.
 * See docs/holy-books/DDD_HOLY_BOOK.md §5.
 */

import { ROUTE_META } from './routeMeta.js'
import HomePage from './site/home/HomePage.jsx'
import { HOME_SEO } from './site/home/homeSeoData.js'
import CommercantsPage from './site/commercants/CommercantsPage.jsx'
import { COMMERCANTS_SEO } from './site/commercants/commercantsSeoData.js'
import ClientsPage from './site/clients/ClientsPage.jsx'
import { CLIENTS_SEO } from './site/clients/clientsSeoData.js'
import CollectivitesPage from './site/collectivites/CollectivitesPage.jsx'
import { COLLECTIVITES_SEO } from './site/collectivites/collectivitesSeoData.js'
import AproposPage from './site/apropos/AproposPage.jsx'
import { APROPOS_SEO } from './site/apropos/aproposSeoData.js'
import ConfidentialitePage from './site/confidentialite/ConfidentialitePage.jsx'
import { CONFIDENTIALITE_SEO } from './site/confidentialite/confidentialiteSeoData.js'
import MerciPage from './site/merci/MerciPage.jsx'
import { MERCI_SEO } from './site/merci/merciSeoData.js'
import NotFoundPage from './site/NotFoundPage.jsx'
import { NOT_FOUND_SEO } from './site/notFoundSeoData.js'

const PAGES = {
  '/': { Component: HomePage, seo: HOME_SEO },
  '/pour-commercants': { Component: CommercantsPage, seo: COMMERCANTS_SEO },
  '/pour-clients': { Component: ClientsPage, seo: CLIENTS_SEO },
  '/pour-collectivites': { Component: CollectivitesPage, seo: COLLECTIVITES_SEO },
  '/a-propos': { Component: AproposPage, seo: APROPOS_SEO },
  '/confidentialite': { Component: ConfidentialitePage, seo: CONFIDENTIALITE_SEO },
  '/merci': { Component: MerciPage, seo: MERCI_SEO },
  '/404': { Component: NotFoundPage, seo: NOT_FOUND_SEO },
}

export const ROUTES = ROUTE_META.map((meta) => {
  const page = PAGES[meta.path]
  if (!page) throw new Error(`No page registered for route ${meta.path}`)
  return { ...meta, ...page }
})

export const INDEXABLE_ROUTES = ROUTES.filter((route) => route.indexable)

export function findRoute(pathname) {
  const clean =
    pathname.length > 1 && pathname.endsWith('/')
      ? pathname.slice(0, -1)
      : pathname
  return ROUTES.find((route) => route.path === clean) ?? null
}
