import { jsonResponse, withCors } from '../_shared/cors.ts'
import { createAdminClient, createUserClient } from '../_shared/supabase.ts'

const GRAPH_VERSION = 'v22.0'
const WINDOW_MS = 24 * 60 * 60 * 1000
const MAX_BODY_LENGTH = 2000

/**
 * Hors de la fenêtre de 24 h après le dernier message entrant, Meta refuse
 * l'envoi : on bloque avant l'appel pour ne pas écrire un message fantôme.
 */
function windowIsOpen(lastInboundAt: string | null): boolean {
  if (!lastInboundAt) return false
  return Date.now() - new Date(lastInboundAt).getTime() < WINDOW_MS
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

    const body = (await req.json()) as {
      conversationId?: string
      text?: string
    }
    const text = body.text?.trim()
    if (!body.conversationId || !text) {
      return jsonResponse({ error: 'conversationId and text required' }, 400)
    }
    if (text.length > MAX_BODY_LENGTH) {
      return jsonResponse({ error: 'Message too long' }, 400)
    }

    const userClient = createUserClient(authHeader)
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()
    if (userError || !user) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    // La RLS de social_conversations fait l'autorisation : si la ligne revient,
    // l'utilisateur est bien membre de l'espace de travail.
    const { data: conversation } = await userClient
      .from('social_conversations')
      .select('id, workspace_id, channel_id, platform, peer_scoped_id, last_inbound_at')
      .eq('id', body.conversationId)
      .maybeSingle()

    if (!conversation) {
      return jsonResponse({ error: 'Conversation not found' }, 404)
    }

    if (!windowIsOpen(conversation.last_inbound_at)) {
      return jsonResponse(
        {
          error:
            'La fenêtre de 24 h est fermée : attendez un nouveau message du contact.',
          code: 'window_closed',
        },
        409,
      )
    }

    const admin = createAdminClient()
    const { data: channel } = await admin
      .from('marketing_channels')
      .select('meta_page_id')
      .eq('id', conversation.channel_id)
      .maybeSingle()

    const { data: cred } = await admin
      .from('meta_channel_credentials')
      .select('access_token')
      .eq('channel_id', conversation.channel_id)
      .maybeSingle()

    if (!channel?.meta_page_id || !cred?.access_token) {
      return jsonResponse({ error: 'Channel is not connected' }, 409)
    }

    const sentAt = new Date().toISOString()
    const { data: row } = await admin
      .from('social_messages')
      .insert({
        conversation_id: conversation.id,
        workspace_id: conversation.workspace_id,
        direction: 'out',
        body: text,
        media_urls: [],
        status: 'queued',
        sent_at: sentAt,
      })
      .select('id')
      .single()

    const res = await fetch(
      `https://graph.facebook.com/${GRAPH_VERSION}/${channel.meta_page_id}/messages`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${cred.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          recipient: { id: conversation.peer_scoped_id },
          message: { text },
          messaging_type: 'RESPONSE',
        }),
      },
    )
    const json = await res.json()

    if (!res.ok) {
      // Le détail Graph reste côté serveur ; le client ne voit qu'un libellé.
      console.error('meta-send-message graph error', json?.error?.code)
      if (row) {
        await admin
          .from('social_messages')
          .update({ status: 'failed', error: json?.error?.message ?? 'send failed' })
          .eq('id', row.id)
      }
      return jsonResponse({ error: "L'envoi a été refusé par Meta." }, 502)
    }

    if (row) {
      await admin
        .from('social_messages')
        .update({ status: 'sent', meta_message_id: json?.message_id ?? null })
        .eq('id', row.id)
    }

    await admin
      .from('social_conversations')
      .update({ last_message_at: sentAt })
      .eq('id', conversation.id)

    return jsonResponse({ ok: true, messageId: row?.id ?? null })
  } catch {
    return jsonResponse({ error: 'Request failed' }, 500)
  }
}

Deno.serve(withCors(handle))
