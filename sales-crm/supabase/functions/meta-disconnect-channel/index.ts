import { jsonResponse, withCors } from '../_shared/cors.ts'
import { createAdminClient, createUserClient } from '../_shared/supabase.ts'

const GRAPH_VERSION = 'v22.0'

/**
 * Disconnects one FB Page / IG channel from a workspace (owner/admin):
 *   1. status → disconnected (webhook + publish + send all skip it)
 *   2. page token deleted
 *   3. when no connected channel anywhere still uses that Page, the Page is
 *      unsubscribed from the app so Meta stops sending its events.
 * A later "Connecter" for the whole account does NOT revive it — only a
 * reconnect started from this channel's own card does (meta-oauth-complete).
 */
async function handle(req: Request): Promise<Response> {
  try {
    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405)
    }
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }
    const body = (await req.json().catch(() => ({}))) as { channelId?: string }
    if (!body.channelId) {
      return jsonResponse({ error: 'channelId required' }, 400)
    }

    const userClient = createUserClient(authHeader)
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()
    if (userError || !user) return jsonResponse({ error: 'Unauthorized' }, 401)

    // RLS: the row only comes back for members of its workspace.
    const { data: channel } = await userClient
      .from('marketing_channels')
      .select('id, workspace_id, meta_page_id')
      .eq('id', body.channelId)
      .maybeSingle()
    if (!channel) return jsonResponse({ error: 'Channel not found' }, 404)

    const { data: membership } = await userClient
      .from('workspace_members')
      .select('role')
      .eq('workspace_id', channel.workspace_id)
      .eq('user_id', user.id)
      .maybeSingle()
    if (!membership || !['owner', 'admin'].includes(membership.role)) {
      return jsonResponse({ error: 'Forbidden' }, 403)
    }

    const admin = createAdminClient()
    const { data: cred } = await admin
      .from('meta_channel_credentials')
      .select('access_token')
      .eq('channel_id', channel.id)
      .maybeSingle()

    const { error: updateError } = await admin
      .from('marketing_channels')
      .update({
        status: 'disconnected',
        subscribed: false,
        updated_at: new Date().toISOString(),
      })
      .eq('id', channel.id)
    if (updateError) {
      console.error('meta-disconnect-channel: update failed', updateError.message)
      return jsonResponse({ error: 'Disconnect failed' }, 500)
    }
    await admin.from('meta_channel_credentials').delete().eq('channel_id', channel.id)

    let unsubscribed = false
    if (channel.meta_page_id && cred?.access_token) {
      const { count } = await admin
        .from('marketing_channels')
        .select('id', { count: 'exact', head: true })
        .eq('meta_page_id', channel.meta_page_id)
        .neq('status', 'disconnected')
      if ((count ?? 0) === 0) {
        const res = await fetch(
          `https://graph.facebook.com/${GRAPH_VERSION}/${channel.meta_page_id}/subscribed_apps`,
          {
            method: 'DELETE',
            headers: { Authorization: `Bearer ${cred.access_token}` },
          },
        )
        unsubscribed = res.ok
        if (!res.ok) {
          const json = await res.json().catch(() => ({}))
          console.warn('meta-disconnect-channel: unsubscribe failed', json?.error?.code)
        }
      }
    }

    return jsonResponse({ ok: true, unsubscribed })
  } catch (error) {
    console.error('meta-disconnect-channel', String(error))
    return jsonResponse({ error: 'Request failed' }, 500)
  }
}

Deno.serve(withCors(handle))
