import { jsonResponse, withCors } from '../_shared/cors.ts'
import { createAdminClient, createUserClient } from '../_shared/supabase.ts'

const GRAPH_VERSION = 'v22.0'
/** Conversations per call — keeps one invocation well under the Edge limit. */
const PAGE_SIZE = 10
/** Meta only returns details of the 20 most recent messages per thread. */
const MESSAGES_PER_THREAD = 20

type Platform = 'messenger' | 'instagram'

type GraphUser = { id: string; name?: string; username?: string }

type GraphMessage = {
  id: string
  created_time: string
  message?: string
  from?: GraphUser
  to?: { data?: GraphUser[] }
}

type GraphConversation = {
  id: string
  updated_time: string
  participants?: { data?: GraphUser[] }
  messages?: { data?: GraphMessage[] }
}

type GraphPage = {
  data?: GraphConversation[]
  paging?: { cursors?: { after?: string }; next?: string }
  error?: { message?: string; code?: number }
}

/**
 * Imports past Messenger / Instagram conversations of ONE channel, one page
 * of conversations per call. The CRM loops on `nextCursor` until null.
 * Idempotent: messages are keyed by Meta's message id (same as webhook mid).
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
    const body = (await req.json().catch(() => ({}))) as {
      channelId?: string
      cursor?: string | null
    }
    if (!body.channelId) return jsonResponse({ error: 'channelId required' }, 400)

    const userClient = createUserClient(authHeader)
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()
    if (userError || !user) return jsonResponse({ error: 'Unauthorized' }, 401)

    // RLS: the row only comes back for members of its workspace.
    const { data: channel } = await userClient
      .from('marketing_channels')
      .select('id, workspace_id, kind, meta_page_id, meta_ig_id, status')
      .eq('id', body.channelId)
      .maybeSingle()
    if (!channel) return jsonResponse({ error: 'Channel not found' }, 404)
    if (channel.status === 'disconnected') {
      return jsonResponse({ error: 'Channel is disconnected' }, 409)
    }

    const { data: membership } = await userClient
      .from('workspace_members')
      .select('role')
      .eq('workspace_id', channel.workspace_id)
      .eq('user_id', user.id)
      .maybeSingle()
    if (!membership || !['owner', 'admin'].includes(membership.role)) {
      return jsonResponse({ error: 'Forbidden' }, 403)
    }

    const platform: Platform =
      channel.kind === 'instagram' ? 'instagram' : 'messenger'
    const ownerId =
      platform === 'instagram' ? channel.meta_ig_id : channel.meta_page_id
    if (!channel.meta_page_id || !ownerId) {
      return jsonResponse({ error: 'Channel has no Meta ids' }, 409)
    }

    const admin = createAdminClient()
    const { data: cred } = await admin
      .from('meta_channel_credentials')
      .select('access_token')
      .eq('channel_id', channel.id)
      .maybeSingle()
    if (!cred?.access_token) {
      return jsonResponse({ error: 'Channel is not connected' }, 409)
    }

    const url = new URL(
      `https://graph.facebook.com/${GRAPH_VERSION}/${channel.meta_page_id}/conversations`,
    )
    url.searchParams.set('platform', platform)
    url.searchParams.set('limit', String(PAGE_SIZE))
    url.searchParams.set(
      'fields',
      // No `participants`: the contact is read from each message's from / to,
      // which both Messenger and Instagram return.
      `updated_time,messages.limit(${MESSAGES_PER_THREAD}){id,created_time,message,from,to}`,
    )
    if (body.cursor) url.searchParams.set('after', body.cursor)

    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${cred.access_token}` },
    })
    const page = (await res.json()) as GraphPage
    if (!res.ok || page.error) {
      console.error('meta-import-history: graph error', {
        platform,
        code: page.error?.code,
      })
      const code = page.error?.code ? ` (code Meta ${page.error.code})` : ''
      return jsonResponse(
        {
          error: `${page.error?.message ?? 'Meta a refusé la lecture de l’historique.'}${code}`,
        },
        502,
      )
    }

    let conversations = 0
    let imported = 0
    for (const thread of page.data ?? []) {
      const result = await importThread(admin, {
        thread,
        platform,
        ownerId,
        channelId: channel.id,
        workspaceId: channel.workspace_id,
      })
      if (result >= 0) conversations += 1
      imported += Math.max(0, result)
    }

    const nextCursor = page.paging?.next ? (page.paging.cursors?.after ?? null) : null
    return jsonResponse({ ok: true, conversations, imported, nextCursor })
  } catch (error) {
    console.error('meta-import-history', String(error))
    return jsonResponse({ error: 'Request failed' }, 500)
  }
}

/** Returns the number of new messages stored, or -1 when skipped. */
async function importThread(
  admin: ReturnType<typeof createAdminClient>,
  input: {
    thread: GraphConversation
    platform: Platform
    ownerId: string
    channelId: string
    workspaceId: string
  },
): Promise<number> {
  const { thread, platform, ownerId } = input
  const messages = thread.messages?.data ?? []
  const peer = peerOf(thread, messages, ownerId)
  if (!peer?.id) return -1

  const peerName =
    peer.name ?? (peer.username ? `@${peer.username}` : null)
  const lastInbound = messages
    .filter((m) => m.from?.id && m.from.id !== ownerId)
    .map((m) => toIso(m.created_time))
    .sort()
    .at(-1)

  await admin.from('social_conversations').upsert(
    {
      workspace_id: input.workspaceId,
      channel_id: input.channelId,
      platform,
      peer_scoped_id: peer.id,
      peer_name: peerName,
      last_message_at: toIso(thread.updated_time),
      last_inbound_at: lastInbound ? toIso(lastInbound) : null,
      unread: 0,
    },
    { onConflict: 'channel_id,peer_scoped_id', ignoreDuplicates: true },
  )
  const { data: conversation } = await admin
    .from('social_conversations')
    .select('id, peer_name, last_message_at, last_inbound_at')
    .eq('channel_id', input.channelId)
    .eq('peer_scoped_id', peer.id)
    .single()
  if (!conversation) return -1

  // Never move timestamps backwards; only fill a missing name.
  const patch: Record<string, string> = {}
  if (!conversation.peer_name && peerName) patch.peer_name = peerName
  const updated = toIso(thread.updated_time)
  if (isAfter(updated, conversation.last_message_at)) patch.last_message_at = updated
  if (lastInbound) {
    const inbound = toIso(lastInbound)
    if (!conversation.last_inbound_at || isAfter(inbound, conversation.last_inbound_at)) {
      patch.last_inbound_at = inbound
    }
  }
  if (Object.keys(patch).length > 0) {
    await admin.from('social_conversations').update(patch).eq('id', conversation.id)
  }

  const rows = messages.map((m) => {
    const outbound = m.from?.id === ownerId
    return {
      conversation_id: conversation.id,
      workspace_id: input.workspaceId,
      direction: outbound ? 'out' : 'in',
      body: m.message ?? null,
      media_urls: [] as string[],
      meta_message_id: m.id,
      status: outbound ? 'sent' : 'delivered',
      sent_at: toIso(m.created_time),
    }
  })
  if (rows.length === 0) return 0

  const { data: inserted, error } = await admin
    .from('social_messages')
    .upsert(rows, { onConflict: 'meta_message_id', ignoreDuplicates: true })
    .select('id')
  if (error) {
    console.error('meta-import-history: insert failed', error.message)
    return 0
  }
  return inserted?.length ?? 0
}

/** The other person: sender of an inbound message, else recipient of ours. */
function peerOf(
  thread: GraphConversation,
  messages: GraphMessage[],
  ownerId: string,
): GraphUser | null {
  const fromPeer = messages.find((m) => m.from?.id && m.from.id !== ownerId)?.from
  if (fromPeer) return fromPeer
  for (const m of messages) {
    const to = m.to?.data?.find((u) => u.id !== ownerId)
    if (to) return to
  }
  return thread.participants?.data?.find((p) => p.id !== ownerId) ?? null
}

function isAfter(a: string, b: string): boolean {
  return new Date(a).getTime() > new Date(b).getTime()
}

/** Graph returns `2026-11-21T10:00:00+0000`; normalise for comparisons. */
function toIso(value: string): string {
  const date = new Date(value.replace(/\+0000$/, 'Z'))
  return Number.isNaN(date.getTime()) ? new Date().toISOString() : date.toISOString()
}

Deno.serve(withCors(handle))
