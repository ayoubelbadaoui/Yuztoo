import { getConfig } from '../_shared/config.ts'
import { createAdminClient } from '../_shared/supabase.ts'

const GRAPH_VERSION = 'v22.0'

type GraphPage = {
  id: string
  name?: string
  access_token?: string
  instagram_business_account?: { id: string; username?: string }
}

function html(title: string, body: string) {
  return new Response(
    `<!doctype html><html><head><meta charset="utf-8"><title>${title}</title></head><body style="font-family:system-ui;padding:2rem">${body}</body></html>`,
    { headers: { 'Content-Type': 'text/html; charset=utf-8' } },
  )
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
}) {
  const admin = createAdminClient()
  let existingId: string | null = null

  if (input.kind === 'facebook-page' && input.metaPageId) {
    const { data } = await admin
      .from('marketing_channels')
      .select('id')
      .eq('workspace_id', input.workspaceId)
      .eq('kind', 'facebook-page')
      .eq('meta_page_id', input.metaPageId)
      .maybeSingle()
    existingId = data?.id ?? null
  } else if (input.kind === 'instagram' && input.metaIgId) {
    const { data } = await admin
      .from('marketing_channels')
      .select('id')
      .eq('workspace_id', input.workspaceId)
      .eq('kind', 'instagram')
      .eq('meta_ig_id', input.metaIgId)
      .maybeSingle()
    existingId = data?.id ?? null
  }

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
    token_type: 'page',
    scopes: [],
    expires_at: input.expiresAt,
    updated_at: new Date().toISOString(),
  })

  return channel.id
}

Deno.serve(async (req) => {
  try {
    const appId = await getConfig('META_APP_ID')
    const appSecret = await getConfig('META_APP_SECRET')
    const redirectUri = await getConfig('META_OAUTH_REDIRECT_URI')
    const appOrigin =
      (await getConfig('CRM_APP_ORIGIN')) ?? 'http://localhost:5173'

    if (!appId || !appSecret || !redirectUri) {
      return html('Config', '<p>Meta OAuth is not configured.</p>')
    }

    const incoming = new URL(req.url)
    const code = incoming.searchParams.get('code')
    const state = incoming.searchParams.get('state')
    const oauthError = incoming.searchParams.get('error')

    if (oauthError) {
      return html(
        'Cancelled',
        `<p>Meta authorization was cancelled.</p><p><a href="${appOrigin}">Back to CRM</a></p>`,
      )
    }
    if (!code || !state) {
      return html('Invalid', '<p>Missing OAuth code or state.</p>')
    }

    const admin = createAdminClient()
    const { data: stateRow } = await admin
      .from('meta_oauth_states')
      .select('id, workspace_id, user_id, return_to, expires_at')
      .eq('id', state)
      .maybeSingle()

    if (!stateRow || new Date(stateRow.expires_at) < new Date()) {
      return html(
        'Expired',
        '<p>OAuth session expired. Try again from the CRM.</p>',
      )
    }

    await admin.from('meta_oauth_states').delete().eq('id', state)

    const tokenUrl = new URL(
      `https://graph.facebook.com/${GRAPH_VERSION}/oauth/access_token`,
    )
    tokenUrl.searchParams.set('client_id', appId)
    tokenUrl.searchParams.set('client_secret', appSecret)
    tokenUrl.searchParams.set('redirect_uri', redirectUri)
    tokenUrl.searchParams.set('code', code)

    const shortRes = await fetch(tokenUrl)
    const shortJson = await shortRes.json()
    if (!shortRes.ok || !shortJson.access_token) {
      return html('Token error', '<p>Could not exchange authorization code.</p>')
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

    const pagesPayload = await graphGet<{ data: GraphPage[] }>(
      `/me/accounts?fields=id,name,access_token,instagram_business_account{id,username}`,
      userToken,
    )

    const pages = pagesPayload.data ?? []
    if (pages.length === 0) {
      return html(
        'No pages',
        '<p>No Facebook Pages were returned. Connect a Page to this Facebook account, then retry.</p>',
      )
    }

    for (const page of pages) {
      if (!page.access_token) continue

      await upsertChannel({
        workspaceId: stateRow.workspace_id,
        kind: 'facebook-page',
        name: page.name ?? `Page ${page.id}`,
        handle: page.name ?? page.id,
        metaPageId: page.id,
        metaIgId: page.instagram_business_account?.id ?? null,
        expiresAt,
        userId: stateRow.user_id,
        accessToken: page.access_token,
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
        })
      }
    }

    const returnPath = stateRow.return_to || '/?page=channels'
    const dest = new URL(returnPath, appOrigin)
    dest.searchParams.set('meta_connected', '1')
    return Response.redirect(dest.toString(), 302)
  } catch {
    return html('Error', '<p>OAuth callback failed.</p>')
  }
})
