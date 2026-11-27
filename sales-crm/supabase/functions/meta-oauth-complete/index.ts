import { getConfig } from '../_shared/config.ts'
import { jsonResponse, withCors } from '../_shared/cors.ts'
import { createAdminClient } from '../_shared/supabase.ts'

const GRAPH_VERSION = 'v22.0'

/** Champs réclamés au Graph pour chaque page autorisée. */
const PAGE_FIELDS = [
  'id',
  'name',
  'username',
  'fan_count',
  'followers_count',
  'access_token',
  'picture{url}',
  'instagram_business_account{id,username,followers_count,profile_picture_url}',
].join(',')

/**
 * Sans abonnement explicite de la page à l'app, Meta valide le webhook mais
 * ne livre jamais aucun message : on le fait donc à chaque connexion.
 */
const SUBSCRIBED_FIELDS = 'messages,messaging_postbacks,message_reactions'

type GraphPage = {
  id: string
  name?: string
  username?: string
  fan_count?: number
  followers_count?: number
  access_token?: string
  picture?: { data?: { url?: string } }
  instagram_business_account?: {
    id: string
    username?: string
    followers_count?: number
    profile_picture_url?: string
  }
}

async function graphGet<T>(path: string, token: string): Promise<T> {
  const url = `https://graph.facebook.com/${GRAPH_VERSION}${path}`
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  })
  const json = await res.json()
  if (!res.ok) {
    throw new Error(json?.error?.message ?? 'Graph request failed')
  }
  return json as T
}

async function subscribePage(pageId: string, pageToken: string) {
  const url = new URL(
    `https://graph.facebook.com/${GRAPH_VERSION}/${pageId}/subscribed_apps`,
  )
  url.searchParams.set('subscribed_fields', SUBSCRIBED_FIELDS)
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { Authorization: `Bearer ${pageToken}` },
    })
    const json = await res.json()
    return res.ok && json?.success === true
  } catch {
    return false
  }
}

async function upsertChannel(input: {
  workspaceId: string
  kind: 'facebook-page' | 'instagram'
  name: string
  handle: string
  metaPageId: string | null
  metaIgId: string | null
  expiresAt: string | null
  userId: string
  accessToken: string
  /** App-scoped id of the person who connected (Meta deletion callbacks). */
  metaUserId: string | null
  followers: number
  pictureUrl: string | null
  subscribed: boolean
  /** Channel the user explicitly asked to reconnect (from its own card). */
  reconnectId: string | null
}) {
  const admin = createAdminClient()
  let existing: { id: string; status: string } | null = null

  if (input.kind === 'facebook-page' && input.metaPageId) {
    const { data } = await admin
      .from('marketing_channels')
      .select('id, status')
      .eq('workspace_id', input.workspaceId)
      .eq('kind', 'facebook-page')
      .eq('meta_page_id', input.metaPageId)
      .maybeSingle()
    existing = data ?? null
  } else if (input.kind === 'instagram' && input.metaIgId) {
    const { data } = await admin
      .from('marketing_channels')
      .select('id, status')
      .eq('workspace_id', input.workspaceId)
      .eq('kind', 'instagram')
      .eq('meta_ig_id', input.metaIgId)
      .maybeSingle()
    existing = data ?? null
  }

  // Meta returns every Page the person manages. A channel disconnected on
  // purpose stays disconnected unless this OAuth run targets it.
  if (existing?.status === 'disconnected' && existing.id !== input.reconnectId) {
    return null
  }
  const existingId = existing?.id ?? null

  const row = {
    workspace_id: input.workspaceId,
    kind: input.kind,
    name: input.name,
    handle: input.handle,
    meta_page_id: input.metaPageId,
    meta_ig_id: input.metaIgId,
    status: 'connected' as const,
    token_expires_at: input.expiresAt,
    connected_by: input.userId,
    followers: input.followers,
    picture_url: input.pictureUrl,
    owner: 'yuztoo',
    subscribed: input.subscribed,
    updated_at: new Date().toISOString(),
  }

  const { data: channel, error } = existingId
    ? await admin
        .from('marketing_channels')
        .update(row)
        .eq('id', existingId)
        .select('id')
        .single()
    : await admin.from('marketing_channels').insert(row).select('id').single()

  if (error || !channel) return null

  await admin.from('meta_channel_credentials').upsert({
    channel_id: channel.id,
    access_token: input.accessToken,
    meta_user_id: input.metaUserId,
    token_type: 'page',
    scopes: [],
    expires_at: input.expiresAt,
    updated_at: new Date().toISOString(),
  })

  return channel.id
}

const RECONNECT_PARAM = 'reconnect'

/** `/?page=channels&reconnect=<uuid>` → uuid (set by the channel card). */
function reconnectIdFrom(returnTo: string | null): string | null {
  if (!returnTo) return null
  try {
    const id = new URL(returnTo, 'https://crm.local').searchParams.get(RECONNECT_PARAM)
    return id && /^[0-9a-f-]{36}$/i.test(id) ? id : null
  } catch {
    return null
  }
}

function stripReconnect(returnTo: string): string {
  try {
    const url = new URL(returnTo, 'https://crm.local')
    url.searchParams.delete(RECONNECT_PARAM)
    return `${url.pathname}${url.search}`
  } catch {
    return '/?page=channels'
  }
}

async function handle(req: Request): Promise<Response> {
  try {
    if (req.method !== 'POST') {
      return jsonResponse({ ok: false, error: 'Method not allowed' }, 405)
    }

    const appId = await getConfig('META_APP_ID')
    const appSecret = await getConfig('META_APP_SECRET')
    const defaultRedirect = await getConfig('META_OAUTH_REDIRECT_URI')
    if (!appId || !appSecret || !defaultRedirect) {
      return jsonResponse({ ok: false, error: 'Meta OAuth is not configured' }, 500)
    }

    const body = (await req.json()) as { code?: string; state?: string }
    if (!body.code || !body.state) {
      return jsonResponse({ ok: false, error: 'Missing code or state' }, 400)
    }

    const admin = createAdminClient()
    const { data: stateRow } = await admin
      .from('meta_oauth_states')
      .select('id, workspace_id, user_id, return_to, expires_at, app_origin')
      .eq('id', body.state)
      .maybeSingle()

    if (!stateRow || new Date(stateRow.expires_at) < new Date()) {
      return jsonResponse({ ok: false, error: 'OAuth session expired' }, 400)
    }

    await admin.from('meta_oauth_states').delete().eq('id', body.state)

    // Must match the redirect_uri used in meta-oauth-start (prod or localhost).
    const redirectUri = stateRow.app_origin
      ? `${stateRow.app_origin}/meta-oauth`
      : defaultRedirect

    const tokenUrl = new URL(
      `https://graph.facebook.com/${GRAPH_VERSION}/oauth/access_token`,
    )
    tokenUrl.searchParams.set('client_id', appId)
    tokenUrl.searchParams.set('client_secret', appSecret)
    tokenUrl.searchParams.set('redirect_uri', redirectUri)
    tokenUrl.searchParams.set('code', body.code)

    const shortRes = await fetch(tokenUrl)
    const shortJson = await shortRes.json()
    if (!shortRes.ok || !shortJson.access_token) {
      return jsonResponse(
        { ok: false, error: 'Could not exchange authorization code' },
        400,
      )
    }

    const llUrl = new URL(
      `https://graph.facebook.com/${GRAPH_VERSION}/oauth/access_token`,
    )
    llUrl.searchParams.set('grant_type', 'fb_exchange_token')
    llUrl.searchParams.set('client_id', appId)
    llUrl.searchParams.set('client_secret', appSecret)
    llUrl.searchParams.set('fb_exchange_token', shortJson.access_token)

    const llRes = await fetch(llUrl)
    const llJson = await llRes.json()
    const userToken = llJson.access_token ?? shortJson.access_token
    const expiresIn = Number(llJson.expires_in ?? shortJson.expires_in ?? 0)
    const expiresAt =
      expiresIn > 0
        ? new Date(Date.now() + expiresIn * 1000).toISOString()
        : null

    // Meta's deletion / deauthorize callbacks only name this app-scoped id.
    const metaUserId = await graphGet<{ id?: string }>('/me?fields=id', userToken)
      .then((me) => me.id ?? null)
      .catch(() => null)

    const pagesPayload = await graphGet<{ data: GraphPage[] }>(
      `/me/accounts?fields=${PAGE_FIELDS}`,
      userToken,
    )
    const pages = pagesPayload.data ?? []
    if (pages.length === 0) {
      return jsonResponse(
        {
          ok: false,
          error: 'No Facebook Pages returned. Connect a Page to this account.',
        },
        400,
      )
    }

    const reconnectId = reconnectIdFrom(stateRow.return_to)

    for (const page of pages) {
      if (!page.access_token) continue
      const subscribed = await subscribePage(page.id, page.access_token)

      await upsertChannel({
        workspaceId: stateRow.workspace_id,
        kind: 'facebook-page',
        name: page.name ?? `Page ${page.id}`,
        handle: page.username ?? page.name ?? page.id,
        metaPageId: page.id,
        metaIgId: page.instagram_business_account?.id ?? null,
        expiresAt,
        userId: stateRow.user_id,
        accessToken: page.access_token,
        metaUserId,
        followers: page.followers_count ?? page.fan_count ?? 0,
        pictureUrl: page.picture?.data?.url ?? null,
        subscribed,
        reconnectId,
      })

      const ig = page.instagram_business_account
      if (ig?.id) {
        await upsertChannel({
          workspaceId: stateRow.workspace_id,
          kind: 'instagram',
          name: ig.username ? `@${ig.username}` : `IG ${ig.id}`,
          handle: ig.username ?? ig.id,
          metaPageId: page.id,
          metaIgId: ig.id,
          expiresAt,
          userId: stateRow.user_id,
          accessToken: page.access_token,
        metaUserId,
          followers: ig.followers_count ?? 0,
          pictureUrl: ig.profile_picture_url ?? null,
          subscribed,
          reconnectId,
        })
      }
    }

    return jsonResponse({
      ok: true,
      returnTo: stripReconnect(stateRow.return_to || '/?page=channels'),
    })
  } catch {
    return jsonResponse({ ok: false, error: 'OAuth complete failed' }, 500)
  }
}

Deno.serve(withCors(handle))
