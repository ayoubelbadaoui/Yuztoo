/**
 * Writes public/sitemap.xml from the route table. Indexable routes only.
 * `lastmod` comes from the route entry, never from the build date.
 */

import { writeFileSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { ROUTE_META } from '../src/routeMeta.js'
import { SITE } from '../src/siteConfig.js'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const indexable = ROUTE_META.filter((route) => route.indexable)

for (const route of indexable) {
  if (!route.lastmod) {
    console.error(`✗ Route ${route.path} is indexable but has no lastmod.`)
    process.exit(1)
  }
}

const urls = indexable
  .map((route) =>
    [
      '  <url>',
      `    <loc>${SITE.origin}${route.path === '/' ? '/' : route.path}</loc>`,
      `    <lastmod>${route.lastmod}</lastmod>`,
      route.changefreq ? `    <changefreq>${route.changefreq}</changefreq>` : null,
      route.priority ? `    <priority>${route.priority}</priority>` : null,
      '  </url>',
    ]
      .filter(Boolean)
      .join('\n'),
  )
  .join('\n')

writeFileSync(
  resolve(root, 'public/sitemap.xml'),
  `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls}
</urlset>
`,
  'utf8',
)

console.log(`✓ sitemap.xml: ${indexable.length} indexable URL(s)`)
