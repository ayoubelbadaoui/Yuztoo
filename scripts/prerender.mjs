/**
 * Renders every route to static HTML in dist/<path>/index.html.
 *
 * AI crawlers do not run JavaScript, so an indexable page must ship real markup
 * and real meta tags. See docs/holy-books/SEO_HOLY_BOOK.md §2.
 */

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { renderHeadTags } from '../src/seo/pageSeoRender.js'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const template = readFileSync(resolve(root, 'dist/index.html'), 'utf8')
const { render, ROUTES } = await import(
  resolve(root, 'dist-ssr/entry-server.js')
)

const gscVerification = process.env.VITE_GSC_VERIFICATION ?? ''

for (const route of ROUTES) {
  const body = render(route.path)
  const head = renderHeadTags(route.seo, { gscVerification })

  const html = template
    .replace('<!--seo-head-->', head)
    .replace('<div id="root">', '<div id="root" data-ssr="true">')
    .replace('<!--ssr-outlet-->', body)

  const outDir =
    route.path === '/' ? resolve(root, 'dist') : resolve(root, `dist${route.path}`)
  mkdirSync(outDir, { recursive: true })
  writeFileSync(resolve(outDir, 'index.html'), html, 'utf8')
}

// Firebase Hosting serves this for unknown URLs; it must be a real 404 page.
writeFileSync(
  resolve(root, 'dist/404.html'),
  readFileSync(resolve(root, 'dist/404/index.html'), 'utf8'),
  'utf8',
)

console.log(`✓ Prerendered ${ROUTES.length} route(s)`)
