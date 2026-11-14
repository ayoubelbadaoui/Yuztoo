/**
 * Page path -> lead source label. Every value must also be in SOURCES of
 * functions-site/index.js, or the Cloud Function rejects the lead.
 * Format: "Site web / " + 2–40 letters, digits, spaces or '. See SEO_HOLY_BOOK §11.
 */

export const LEAD_SOURCES = {
  '/': 'Site web / Accueil',
  '/pour-commercants': 'Site web / Commerçants',
  '/pour-clients': 'Site web / Clients',
  '/pour-collectivites': 'Site web / Collectivités',
  '/a-propos': 'Site web / A propos',
}

const FORMAT = /^Site web \/ [\p{L}\p{N} ']{2,40}$/u

export function leadSourceFor(path, explicit) {
  const value = explicit ?? LEAD_SOURCES[path] ?? 'Site web / Autre page'
  return FORMAT.test(value) ? value : 'Site web'
}
