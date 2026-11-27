import { getConfig } from '../_shared/config.ts'
import { jsonResponse, withCors } from '../_shared/cors.ts'
import { createAdminClient } from '../_shared/supabase.ts'

/**
 * Meta App Review callbacks (both receive a `signed_request` form field):
 *
 *   POST  …/meta-data-deletion                 Data Deletion Request callback
 *         → deletes every channel the person connected (cascade: page token,
 *           conversations, messages) and answers { url, confirmation_code }.
 *   POST  …/meta-data-deletion?type=deauthorize  Deauthorize callback
 *         → disconnects those channels and blanks their tokens (data kept until
 *           a deletion request arrives).
 *   GET   …/meta-data-deletion?code=XXXX        Status for the public page
 *         → { status, created_at, completed_at } — no personal data.
 */

const STATUS_PAGE = 'https://yuztoo-msg.radnatech.it/suppression-donnees/statut/'

type SignedPayload = { algorithm?: string; user_id?: string; issued_at?: number }

function b64urlToBytes(s: string): Uint8Array {
  const b64 = s.replace(/-/g, '+').replace(/_/g, '/')
  const padded = b64 + '='.repeat((4 - (b64.length % 4)) % 4)
  const bin = atob(padded)
  return Uint8Array.from(bin, (c) => c.charCodeAt(0))
}

function timingSafeEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false
  let diff = 0
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i]
  return diff === 0
}

/** Verifies HMAC-SHA256(payload, app secret) and returns the payload. */
async function parseSignedRequest(signed: string): Promise<SignedPayload | null> {
  const appSecret = await getConfig('META_APP_SECRET')
  const [sigPart, payloadPart] = signed.split('.', 2)
  if (!appSecret || !sigPart || !payloadPart) return null
  try {
    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(appSecret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign'],
    )
    const mac = new Uint8Array(
      await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payloadPart)),
    )
    if (!timingSafeEqual(mac, b64urlToBytes(sigPart))) return null
    const payload = JSON.parse(
      new TextDecoder().decode(b64urlToBytes(payloadPart)),
    ) as SignedPayload
    if (payload.algorithm?.toUpperCase() !== 'HMAC-SHA256' || !payload.user_id) {
      return null
    }
    return payload
  } catch {
    return null
  }
}

function newConfirmationCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(9))
  return Array.from(bytes, (b) => b.toString(36).padStart(2, '0'))
    .join('')
    .slice(0, 12)
    .toUpperCase()
}

async function channelIdsFor(metaUserId: string): Promise<string[]> {
  const admin = createAdminClient()
  const { data } = await admin
    .from('meta_channel_credentials')
    .select('channel_id')
    .eq('meta_user_id', metaUserId)
  return (data ?? []).map((r) => r.channel_id as string)
}

async function handleStatus(code: string): Promise<Response> {
  if (!/^[A-Z0-9]{6,16}$/.test(code)) return jsonResponse({ error: 'Invalid code' }, 400)
  const { data } = await createAdminClient()
    .from('meta_data_deletion_requests')
    .select('status, created_at, completed_at')
    .eq('confirmation_code', code)
    .eq('kind', 'deletion')
    .maybeSingle()
  if (!data) return jsonResponse({ error: 'Not found' }, 404)
  return jsonResponse(data)
}

async function handle(req: Request): Promise<Response> {
  const url = new URL(req.url)
  if (req.method === 'GET') return handleStatus(url.searchParams.get('code') ?? '')
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405)

  const form = await req.formData().catch(() => null)
  const signed = form?.get('signed_request')
  const payload = typeof signed === 'string' ? await parseSignedRequest(signed) : null
  if (!payload?.user_id) return jsonResponse({ error: 'Invalid signed_request' }, 400)

  const kind = url.searchParams.get('type') === 'deauthorize' ? 'deauthorize' : 'deletion'
  const admin = createAdminClient()
  const code = newConfirmationCode()
  const channelIds = await channelIdsFor(payload.user_id)

  let status: 'completed' | 'no_data' | 'failed' = channelIds.length ? 'completed' : 'no_data'
  if (channelIds.length) {
    if (kind === 'deletion') {
      // Cascades to meta_channel_credentials, social_conversations, social_messages.
      const { error } = await admin.from('marketing_channels').delete().in('id', channelIds)
      if (error) status = 'failed'
    } else {
      const { error } = await admin
        .from('marketing_channels')
        .update({ status: 'disconnected', updated_at: new Date().toISOString() })
        .in('id', channelIds)
      // Blank the token but keep the row: it holds meta_user_id, which a later
      // deletion request needs to find these channels.
      const { error: credError } = await admin
        .from('meta_channel_credentials')
        .update({ access_token: '', expires_at: new Date().toISOString() })
        .in('channel_id', channelIds)
      if (error || credError) status = 'failed'
    }
  }

  await admin.from('meta_data_deletion_requests').insert({
    confirmation_code: code,
    meta_user_id: payload.user_id,
    kind,
    status,
    channels_affected: channelIds.length,
    completed_at: status === 'failed' ? null : new Date().toISOString(),
  })
  if (status === 'failed') console.error('meta-data-deletion: cleanup failed', { kind, code })

  if (kind === 'deauthorize') return jsonResponse({ ok: true })
  return jsonResponse({ url: `${STATUS_PAGE}?code=${code}`, confirmation_code: code })
}

Deno.serve(withCors(handle))
