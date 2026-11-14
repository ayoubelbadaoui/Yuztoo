import { SITE } from '../siteConfig.js'

const escapeHtml = (value) =>
  String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')

const meta = (attr, key, content) =>
  `<meta ${attr}="${key}" content="${escapeHtml(content)}">`

/**
 * Build the <head> tags for one page. Used by the prerenderer at build time and
 * by usePageSeo in the browser, so both read the same source.
 */
export function renderHeadTags(seo, { gscVerification } = {}) {
  const og = seo.og ?? {}
  const tags = [
    `<title>${escapeHtml(seo.title)}</title>`,
    meta('name', 'description', seo.description),
    `<link rel="canonical" href="${escapeHtml(seo.canonical)}">`,
    meta('name', 'robots', seo.robots),
    meta('property', 'og:site_name', SITE.name),
    meta('property', 'og:locale', SITE.locale),
    meta('property', 'og:type', og.type ?? 'website'),
    meta('property', 'og:title', seo.title),
    meta('property', 'og:description', seo.description),
    meta('property', 'og:url', seo.canonical),
    meta('name', 'twitter:card', 'summary_large_image'),
    meta('name', 'twitter:title', seo.title),
    meta('name', 'twitter:description', seo.description),
  ]

  if (og.image) {
    tags.push(
      meta('property', 'og:image', og.image),
      meta('property', 'og:image:width', og.imageWidth ?? 1200),
      meta('property', 'og:image:height', og.imageHeight ?? 630),
      meta('property', 'og:image:alt', og.imageAlt ?? seo.title),
      meta('name', 'twitter:image', og.image),
    )
  }

  if (gscVerification) {
    tags.push(meta('name', 'google-site-verification', gscVerification))
  }

  for (const block of seo.jsonLd ?? []) {
    tags.push(
      `<script type="application/ld+json">${JSON.stringify(block)}</script>`,
    )
  }

  return tags.join('\n    ')
}
