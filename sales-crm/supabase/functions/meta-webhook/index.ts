import { getConfig } from '../_shared/config.ts'
import { createAdminClient } from '../_shared/supabase.ts'

const GRAPH_VERSION = 'v22.0'

async function verifySignature(
  rawBody: string,
  signatureHeader: string | null,
): Promise<boolean> {
  const appSecret = await getConfig('META_APP_SECRET')
  if (!appSecret || !signatureHeader?.startsWith('sha256=')) return false
  const expected = signatureHeader.slice('sha256='.length)
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(appSecret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const mac = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(rawBody),
  )
  const digest = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
  return digest === expected
}

type MessagingEvent = {
  sender?: { id?: string }
  recipient?: { id?: string }
  timestamp?: number
  message?: {
    mid?: string
    text?: string
    is_echo?: boolean
    attachments?: Array<{ type?: string; payload?: { url?: string } }>
  }
}

type Platform = 'messenger' | 'instagram'

type ChannelMatch = { id: string; workspace_id: string; status: string }

/**
 * Profile fields differ per platform: a Messenger PSID has no `username`, and
 * asking for it makes Graph reject the whole call — which is why names were
 * never filled for Facebook conversations.
 */
const PROFILE_FIELDS: Record<Platform, string> = {
  messenger: 'name,first_name,last_name',
  instagram: 'name,username',
}

/**
 * Le scoped ID ne dit rien à un commercial : on demande le nom au Graph avec
 * le jeton de page. Un échec ne doit pas faire perdre le message.
 */
async function fetchPeerName(
  platform: Platform,
  peerId: string,
  channelId: string,
): Promise<string | null> {
  const admin = createAdminClient()
  const { data: cred } = await admin
    .from('meta_channel_credentials')
    .select('access_token')
    .eq('channel_id', channelId)
    .maybeSingle()
  if (!cred?.access_token) return null

  try {
    const res = await fetch(
      `https://graph.facebook.com/${GRAPH_VERSION}/${peerId}?fields=${PROFILE_FIELDS[platform]}`,
      { headers: { Authorization: `Bearer ${cred.access_token}` } },
    )
    const json = await res.json()
    if (!res.ok) {
      console.warn('meta-webhook: profile lookup failed', {
        platform,
        code: json?.error?.code,
        subcode: json?.error?.error_subcode,
      })
      return null
    }
    const fullName =
      json?.name ??
      ([json?.first_name, json?.last_name].filter(Boolean).join(' ') || null)
    if (fullName) return fullName
    return json?.username ? `@${json.username}` : null
  } catch {
    return null
  }
}

/**
 * Every connected channel for this Page / IG account. The same account can be
 * connected in several workspaces; `maybeSingle()` used to error on 2 rows
 * and silently drop the message.
 */
async function findChannels(
  platform: Platform,
  ownerId: string,
): Promise<ChannelMatch[]> {
  const admin = createAdminClient()
  const query = admin
    .from('marketing_channels')
    .select('id, workspace_id, status')
    .eq('kind', platform === 'messenger' ? 'facebook-page' : 'instagram')
    .neq('status', 'disconnected')
    .order('created_at', { ascending: true })
    .limit(20)
  const { data, error } = await (platform === 'messenger'
    ? query.eq('meta_page_id', ownerId)
    : query.eq('meta_ig_id', ownerId))
  if (error) {
    console.error('meta-webhook: channel lookup failed', error.message)
    return []
  }
  return (data ?? []) as ChannelMatch[]
}

async function ingestIntoChannel(
  platform: Platform,
  channel: ChannelMatch,
  event: MessagingEvent,
  messageKey: string,
) {
  const peerId = event.sender!.id!
  const admin = createAdminClient()

  const mediaUrls =
    event.message?.attachments
      ?.map((a) => a.payload?.url)
      .filter((u): u is string => Boolean(u)) ?? []
  const now = new Date(event.timestamp ?? Date.now()).toISOString()

  // Create the conversation once; never overwrite its counters here.
  await admin.from('social_conversations').upsert(
    {
      workspace_id: channel.workspace_id,
      channel_id: channel.id,
      platform,
      peer_scoped_id: peerId,
      last_message_at: now,
      unread: 0,
    },
    { onConflict: 'channel_id,peer_scoped_id', ignoreDuplicates: true },
  )
  const { data: conversation } = await admin
    .from('social_conversations')
    .select('id, unread, peer_name')
    .eq('channel_id', channel.id)
    .eq('peer_scoped_id', peerId)
    .single()
  if (!conversation) {
    console.error('meta-webhook: conversation missing after upsert')
    return
  }

  // Message first: a Meta retry of the same mid must not bump the counter.
  const { data: inserted, error: insertError } = await admin
    .from('social_messages')
    .upsert(
      {
        conversation_id: conversation.id,
        workspace_id: channel.workspace_id,
        direction: 'in',
        body: event.message?.text ?? null,
        media_urls: mediaUrls,
        meta_message_id: messageKey,
        status: 'delivered',
        sent_at: now,
      },
      { onConflict: 'meta_message_id', ignoreDuplicates: true },
    )
    .select('id')
  if (insertError) {
    console.error('meta-webhook: message insert failed', insertError.message)
    return
  }
  if (!inserted || inserted.length === 0) return // duplicate delivery

  const peerName =
    conversation.peer_name ?? (await fetchPeerName(platform, peerId, channel.id))

  await admin
    .from('social_conversations')
    .update({
      last_inbound_at: now,
      last_message_at: now,
      unread: (conversation.unread ?? 0) + 1,
      ...(peerName ? { peer_name: peerName } : {}),
    })
    .eq('id', conversation.id)
}

async function ingestEvent(
  platform: Platform,
  ownerId: string,
  event: MessagingEvent,
) {
  const peerId = event.sender?.id
  const mid = event.message?.mid
  if (!peerId || !mid) return

  // Our own replies come back as echoes (IG always, FB when subscribed).
  if (event.message?.is_echo || peerId === ownerId) return

  const channels = await findChannels(platform, ownerId)
  if (channels.length === 0) {
    console.warn('meta-webhook: no connected channel for event', {
      platform,
      ownerId,
    })
    return
  }
  // `meta_message_id` is globally unique: extra workspace copies get a suffix.
  for (const [index, channel] of channels.entries()) {
    const key = index === 0 ? mid : `${mid}:${channel.id}`
    await ingestIntoChannel(platform, channel, event, key)
  }
}

Deno.serve(async (req) => {
  const url = new URL(req.url)

  // Meta webhook verification
  if (req.method === 'GET') {
    const mode = url.searchParams.get('hub.mode')
    const token = url.searchParams.get('hub.verify_token')
    const challenge = url.searchParams.get('hub.challenge')
    const verify = await getConfig('META_WEBHOOK_VERIFY_TOKEN')
    if (mode === 'subscribe' && token && verify && token === verify && challenge) {
      return new Response(challenge, { status: 200 })
    }
    return new Response('Forbidden', { status: 403 })
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const rawBody = await req.text()
  const ok = await verifySignature(rawBody, req.headers.get('x-hub-signature-256'))
  if (!ok) {
    return new Response('Invalid signature', { status: 401 })
  }

  try {
    const payload = JSON.parse(rawBody) as {
      object?: string
      entry?: Array<{
        id?: string
        messaging?: MessagingEvent[]
      }>
    }

    const platform =
      payload.object === 'instagram' ? 'instagram' : 'messenger'

    for (const entry of payload.entry ?? []) {
      const ownerId = entry.id
      if (!ownerId) continue
      for (const event of entry.messaging ?? []) {
        if (event.message) {
          await ingestEvent(platform, ownerId, event)
        }
      }
    }
  } catch (error) {
    // Always 200 after verify to avoid Meta retry storms on parse bugs.
    console.error('meta-webhook: payload handling failed', String(error))
  }

  return new Response('EVENT_RECEIVED', { status: 200 })
})
