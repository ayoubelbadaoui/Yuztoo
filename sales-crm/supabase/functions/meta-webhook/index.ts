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
    attachments?: Array<{ type?: string; payload?: { url?: string } }>
  }
}

/**
 * Le scoped ID ne dit rien à un commercial : on demande le nom au Graph avec
 * le jeton de page. Un échec ne doit pas faire perdre le message.
 */
async function fetchPeerName(
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
      `https://graph.facebook.com/${GRAPH_VERSION}/${peerId}?fields=name,username`,
      { headers: { Authorization: `Bearer ${cred.access_token}` } },
    )
    if (!res.ok) return null
    const json = await res.json()
    return json?.name ?? json?.username ?? null
  } catch {
    return null
  }
}

async function ingestEvent(
  platform: 'messenger' | 'instagram',
  pageOrIgId: string,
  event: MessagingEvent,
) {
  const peerId = event.sender?.id
  const mid = event.message?.mid
  if (!peerId || !mid) return

  const admin = createAdminClient()
  const { data: channel } = await admin
    .from('marketing_channels')
    .select('id, workspace_id')
    .or(
      platform === 'messenger'
        ? `meta_page_id.eq.${pageOrIgId}`
        : `meta_ig_id.eq.${pageOrIgId},meta_page_id.eq.${pageOrIgId}`,
    )
    .eq('kind', platform === 'messenger' ? 'facebook-page' : 'instagram')
    .maybeSingle()

  if (!channel) return

  const mediaUrls =
    event.message?.attachments
      ?.map((a) => a.payload?.url)
      .filter((u): u is string => Boolean(u)) ?? []

  const now = new Date(
    event.timestamp ? event.timestamp : Date.now(),
  ).toISOString()

  const { data: conversation } = await admin
    .from('social_conversations')
    .upsert(
      {
        workspace_id: channel.workspace_id,
        channel_id: channel.id,
        platform,
        peer_scoped_id: peerId,
        last_inbound_at: now,
        last_message_at: now,
        unread: 1,
      },
      { onConflict: 'channel_id,peer_scoped_id' },
    )
    .select('id, unread, peer_name')
    .single()

  if (!conversation) return

  const peerName =
    conversation.peer_name ?? (await fetchPeerName(peerId, channel.id))

  await admin
    .from('social_conversations')
    .update({
      last_inbound_at: now,
      last_message_at: now,
      unread: (conversation.unread ?? 0) + 1,
      peer_name: peerName,
    })
    .eq('id', conversation.id)

  await admin.from('social_messages').upsert(
    {
      conversation_id: conversation.id,
      workspace_id: channel.workspace_id,
      direction: 'in',
      body: event.message?.text ?? null,
      media_urls: mediaUrls,
      meta_message_id: mid,
      status: 'delivered',
      sent_at: now,
    },
    { onConflict: 'meta_message_id', ignoreDuplicates: true },
  )
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
  } catch {
    // Always 200 quickly after verify to avoid Meta retries storms on parse bugs
  }

  return new Response('EVENT_RECEIVED', { status: 200 })
})
