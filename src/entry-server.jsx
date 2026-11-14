import { renderToString } from 'react-dom/server'
import { findRoute } from './routes.js'

/** Render one route to HTML. Called by scripts/prerender.mjs at build time. */
export function render(pathname) {
  const route = findRoute(pathname)
  if (!route) throw new Error(`No route registered for ${pathname}`)
  const { Component } = route
  return renderToString(<Component />)
}

export { ROUTES, INDEXABLE_ROUTES } from './routes.js'
