import { jsonResponse, withCors } from '../_shared/cors.ts'
import { getConfig } from '../_shared/config.ts'
import { createUserClient } from '../_shared/supabase.ts'

const ACTIONS = new Set([
  'list',
  'upsert',
  'setActive',
  'setRelease',
  'delete',
  // Read-only lookups for the editor (test client, button shop).
  'findClient',
  'searchMerchants',
])

function bridgeUrl(projectId: string): string {
  return `https://europe-west1-${projectId}.cloudfunctions.net/crmBridgeYuztooNews`
}

async function handle(req: Request): Promise<Response> {
  try {
    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405)
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    const userClient = createUserClient(authHeader)
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()
    if (userError || !user) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    const body = (await req.json().catch(() => ({}))) as Record<
      string,
      unknown
    >
    const action = String(body.action ?? '').trim()
    if (!ACTIONS.has(action)) {
      return jsonResponse({ error: 'Unknown action' }, 400)
    }

    const secret = await getConfig('CRM_BRIDGE_SECRET')
    if (!secret) {
      console.error('cms-yuztoo-news: missing CRM_BRIDGE_SECRET')
      return jsonResponse({ error: 'Bridge not configured' }, 503)
    }

    const projectId =
      (await getConfig('FIREBASE_PROJECT_ID'))?.trim() || 'yuztoo'
    const configuredUrl = (await getConfig('CRM_BRIDGE_YUZTOO_NEWS_URL'))?.trim()
    const url = configuredUrl || bridgeUrl(projectId)

    const payload = {
      ...body,
      action,
      actor_uid: user.id,
      actor_email: user.email ?? null,
    }

    const upstream = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CRM-Bridge-Secret': secret,
      },
      body: JSON.stringify(payload),
    })

    const text = await upstream.text()
    let parsed: unknown = null
    try {
      parsed = text ? JSON.parse(text) : null
    } catch {
      console.error('cms-yuztoo-news: non-JSON upstream', upstream.status)
      return jsonResponse({ error: 'Request failed' }, 502)
    }

    if (!upstream.ok) {
      const message =
        parsed &&
        typeof parsed === 'object' &&
        'error' in parsed &&
        typeof (parsed as { error: unknown }).error === 'string'
          ? (parsed as { error: string }).error
          : 'Request failed'
      return jsonResponse(
        {
          error: message,
          code:
            parsed &&
            typeof parsed === 'object' &&
            'code' in parsed &&
            typeof (parsed as { code: unknown }).code === 'string'
              ? (parsed as { code: string }).code
              : undefined,
        },
        upstream.status >= 400 && upstream.status < 600
          ? upstream.status
          : 502,
      )
    }

    const data =
      parsed &&
      typeof parsed === 'object' &&
      'data' in parsed
        ? (parsed as { data: unknown }).data
        : parsed

    return jsonResponse(data)
  } catch (error) {
    console.error('cms-yuztoo-news', error)
    return jsonResponse({ error: 'Request failed' }, 500)
  }
}

Deno.serve(withCors(handle))
