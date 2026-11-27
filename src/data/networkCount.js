/**
 * Live partner count from the networkCount Cloud Function (functions-site).
 * Returns { data: number | null, error } and never throws. No endpoint
 * configured (VITE_COUNT_ENDPOINT unset and live counting off) = no request.
 */

const ENDPOINT =
  import.meta.env.VITE_COUNT_ENDPOINT ??
  'https://europe-west1-yuztoo.cloudfunctions.net/networkCount'

const TIMEOUT_MS = 6000

export async function fetchPartnerCount() {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS)
  try {
    const response = await fetch(ENDPOINT, { signal: controller.signal })
    if (!response.ok) return { data: null, error: 'server' }
    const body = await response.json()
    return Number.isInteger(body?.partners) ? { data: body.partners, error: null } : { data: null, error: 'invalid' }
  } catch {
    return { data: null, error: 'network' }
  } finally {
    clearTimeout(timer)
  }
}
