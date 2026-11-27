/** Seules ces origines peuvent appeler les fonctions depuis un navigateur. */
export const ALLOWED_ORIGINS = new Set([
  'https://yuztoo-msg.radnatech.it',
  'http://localhost:5173',
  'http://localhost:5174',
  'http://localhost:4173',
  'http://127.0.0.1:5173',
  'http://127.0.0.1:5174',
])

function corsHeadersFor(origin: string | null): Record<string, string> {
  const allowed = origin && ALLOWED_ORIGINS.has(origin) ? origin : null
  return {
    ...(allowed ? { 'Access-Control-Allow-Origin': allowed } : {}),
    Vary: 'Origin',
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type, x-cron-secret',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  }
}

export function jsonResponse(
  body: unknown,
  status = 200,
  extra: Record<string, string> = {},
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...extra },
  })
}

/**
 * Répond au préflight et recolle les en-têtes CORS sur la réponse : les
 * fonctions n'ont ainsi jamais à décider elles-mêmes quelles origines passent.
 */
export function withCors(
  handler: (req: Request) => Promise<Response>,
): (req: Request) => Promise<Response> {
  return async (req) => {
    const origin = req.headers.get('origin')
    const headers = corsHeadersFor(origin)
    if (req.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers })
    }
    const res = await handler(req)
    for (const [k, v] of Object.entries(headers)) res.headers.set(k, v)
    return res
  }
}
