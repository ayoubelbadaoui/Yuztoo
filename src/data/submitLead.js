/**
 * The one door to the websiteLead Cloud Function (DDD_HOLY_BOOK §4, SEO_HOLY_BOOK §11).
 * Returns { data, error } and never throws.
 */

const ENDPOINT =
  import.meta.env.VITE_LEAD_ENDPOINT ??
  'https://europe-west1-yuztoo.cloudfunctions.net/websiteLead'

const TIMEOUT_MS = 12000

export async function submitLead({ source, kind, fields }) {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS)

  try {
    const response = await fetch(ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ source, kind, ...fields }),
      signal: controller.signal,
    })
    if (response.status === 429) return { data: null, error: 'rate_limited' }
    if (response.status === 400) return { data: null, error: 'invalid' }
    if (!response.ok) return { data: null, error: 'server' }
    return { data: { ok: true }, error: null }
  } catch {
    return { data: null, error: 'network' }
  } finally {
    clearTimeout(timer)
  }
}
