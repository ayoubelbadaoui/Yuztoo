/**
 * The SEO gate. Runs last in the build and fails it if any page breaks
 * docs/holy-books/SEO_HOLY_BOOK.md §1. Fix the page — never loosen the gate.
 */

import { existsSync, readFileSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { ROUTE_META } from '../src/routeMeta.js'
import { SITE } from '../src/siteConfig.js'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const errors = []
const seenTitles = new Map()
const seenDescriptions = new Map()

const fail = (path, message) => errors.push(`${path}: ${message}`)
const count = (html, pattern) => (html.match(pattern) ?? []).length

const htmlFor = (routePath) =>
  routePath === '/'
    ? resolve(root, 'dist/index.html')
    : resolve(root, `dist${routePath}/index.html`)

for (const route of ROUTE_META) {
  const file = htmlFor(route.path)
  if (!existsSync(file)) {
    fail(route.path, 'not prerendered')
    continue
  }

  const html = readFileSync(file, 'utf8')
  const title = html.match(/<title>([^<]*)<\/title>/)?.[1] ?? ''
  const description =
    html.match(/<meta name="description" content="([^"]*)"/)?.[1] ?? ''
  const canonical =
    html.match(/<link rel="canonical" href="([^"]*)"/)?.[1] ?? ''

  // Rules that apply to every page, indexable or not.
  if (count(html, /<h1[\s>]/g) !== 1) {
    fail(route.path, `expected exactly 1 <h1>, found ${count(html, /<h1[\s>]/g)}`)
  }
  if (!html.includes(`lang="${SITE.lang}"`)) {
    fail(route.path, `missing lang="${SITE.lang}"`)
  }
  if (/fonts\.googleapis\.com/.test(html)) {
    fail(route.path, 'loads Google Fonts — fonts must be self-hosted')
  }
  if (!html.includes('data-ssr="true"')) {
    fail(route.path, 'shipped without server-rendered markup')
  }

  // Images must have alt text (empty alt is allowed for decorative images).
  const imagesWithoutAlt = count(html, /<img(?![^>]*\balt=)[^>]*>/g)
  if (imagesWithoutAlt > 0) {
    fail(route.path, `${imagesWithoutAlt} <img> without an alt attribute`)
  }

  if (!route.indexable) {
    if (!/<meta name="robots" content="noindex/.test(html)) {
      fail(route.path, 'non-indexable page is missing noindex')
    }
    continue
  }

  if (title.length < 30 || title.length > 65) {
    fail(route.path, `title is ${title.length} chars, expected 30-65`)
  }
  if (description.length < 110 || description.length > 160) {
    fail(
      route.path,
      `description is ${description.length} chars, expected 110-160`,
    )
  }

  const expectedCanonical = `${SITE.origin}${route.path === '/' ? '' : route.path}`
  if (canonical !== expectedCanonical) {
    fail(route.path, `canonical is "${canonical}", expected "${expectedCanonical}"`)
  }

  if (seenTitles.has(title)) {
    fail(route.path, `duplicate title, already used by ${seenTitles.get(title)}`)
  }
  seenTitles.set(title, route.path)

  if (seenDescriptions.has(description)) {
    fail(
      route.path,
      `duplicate description, already used by ${seenDescriptions.get(description)}`,
    )
  }
  seenDescriptions.set(description, route.path)

  for (const tag of [
    'og:title',
    'og:description',
    'og:url',
    'og:image',
    'og:type',
    'og:locale',
    'og:site_name',
  ]) {
    if (!html.includes(`"${tag}"`)) fail(route.path, `missing ${tag}`)
  }
  if (!html.includes('name="twitter:card"')) {
    fail(route.path, 'missing twitter:card')
  }

  const ogImage = html.match(/<meta property="og:image" content="([^"]*)"/)?.[1]
  if (ogImage) {
    if (!ogImage.startsWith(SITE.origin)) {
      fail(route.path, 'og:image must be absolute and on the canonical host')
    }
    const localPath = resolve(root, `dist${ogImage.replace(SITE.origin, '')}`)
    if (!existsSync(localPath)) {
      fail(route.path, `og:image file is missing: ${ogImage}`)
    }
  }

  const jsonLdBlocks = html.match(
    /<script type="application\/ld\+json">([\s\S]*?)<\/script>/g,
  )
  if (!jsonLdBlocks || jsonLdBlocks.length === 0) {
    fail(route.path, 'no JSON-LD')
  } else {
    for (const block of jsonLdBlocks) {
      const json = block
        .replace(/<script type="application\/ld\+json">/, '')
        .replace(/<\/script>/, '')
      try {
        JSON.parse(json)
      } catch {
        fail(route.path, 'invalid JSON-LD')
      }
    }
  }
}

// The sitemap must match the indexable routes exactly.
const sitemapPath = resolve(root, 'dist/sitemap.xml')
if (!existsSync(sitemapPath)) {
  errors.push('sitemap.xml: missing from the build output')
} else {
  const sitemap = readFileSync(sitemapPath, 'utf8')
  const locs = [...sitemap.matchAll(/<loc>([^<]*)<\/loc>/g)].map((m) => m[1])
  const expected = ROUTE_META.filter((r) => r.indexable).map(
    (r) => `${SITE.origin}${r.path === '/' ? '/' : r.path}`,
  )

  for (const url of expected) {
    if (!locs.includes(url)) errors.push(`sitemap.xml: missing ${url}`)
  }
  for (const url of locs) {
    if (!expected.includes(url)) {
      errors.push(`sitemap.xml: lists ${url}, which is not an indexable route`)
    }
  }
}

const robotsPath = resolve(root, 'dist/robots.txt')
if (!existsSync(robotsPath)) {
  errors.push('robots.txt: missing from the build output')
} else if (!readFileSync(robotsPath, 'utf8').includes('Sitemap:')) {
  errors.push('robots.txt: no Sitemap line')
}

if (errors.length > 0) {
  console.error('✗ SEO gate failed:')
  for (const error of errors) console.error(`  - ${error}`)
  process.exit(1)
}

const indexableCount = ROUTE_META.filter((r) => r.indexable).length
console.log(
  `✓ SEO gate: ${indexableCount} indexable page(s), all checks passed`,
)
