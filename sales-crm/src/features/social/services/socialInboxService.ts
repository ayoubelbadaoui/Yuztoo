import type {
  SocialConversation,
  SocialMessage,
  SocialMessageStatus,
  SocialPlatform,
} from '@/features/social/domain/conversation'
import { supabase } from '@/lib/supabaseClient'

type Result<T> = { data: T | null; error: Error | null }

type ConversationRow = {
  id: string
  channel_id: string
  platform: string
  peer_name: string | null
  peer_scoped_id: string
  unread: number
  last_message_at: string
  last_inbound_at: string | null
  marketing_channels: { name: string } | null
}

type MessageRow = {
  id: string
  direction: 'in' | 'out'
  body: string | null
  status: SocialMessageStatus
  sent_at: string
}

function toConversation(row: ConversationRow): SocialConversation {
  return {
    id: row.id,
    channelId: row.channel_id,
    channelName: row.marketing_channels?.name ?? 'Compte inconnu',
    platform: row.platform === 'instagram' ? 'instagram' : 'messenger',
    peerName: row.peer_name ?? `Contact ${row.peer_scoped_id.slice(-6)}`,
    unread: row.unread,
    lastMessageAt: row.last_message_at,
    lastInboundAt: row.last_inbound_at,
  }
}

export async function getConversations(
  workspaceId: string,
): Promise<Result<SocialConversation[]>> {
  const { data, error } = await supabase
    .from('social_conversations')
    .select(
      'id, channel_id, platform, peer_name, peer_scoped_id, unread, last_message_at, last_inbound_at, marketing_channels(name)',
    )
    .eq('workspace_id', workspaceId)
    .order('last_message_at', { ascending: false })
    // History import can bring hundreds of threads; IG/FB tabs count these.
    .limit(300)

  if (error) return { data: null, error: new Error(error.message) }
  return {
    data: (data as unknown as ConversationRow[]).map(toConversation),
    error: null,
  }
}

export async function getMessages(
  conversationId: string,
): Promise<Result<SocialMessage[]>> {
  const { data, error } = await supabase
    .from('social_messages')
    .select('id, direction, body, status, sent_at')
    .eq('conversation_id', conversationId)
    .order('sent_at', { ascending: true })
    .limit(200)

  if (error) return { data: null, error: new Error(error.message) }
  return {
    data: (data as MessageRow[]).map((row) => ({
      id: row.id,
      direction: row.direction,
      body: row.body ?? '',
      status: row.status,
      sentAt: row.sent_at,
    })),
    error: null,
  }
}

/**
 * `functions.invoke` masque le corps des réponses d'erreur : on lit la réponse
 * brute pour remonter le message métier (fenêtre fermée, compte déconnecté).
 */
export async function sendMessage(
  conversationId: string,
  text: string,
): Promise<Result<true>> {
  const { data, error } = await supabase.functions.invoke('meta-send-message', {
    body: { conversationId, text },
  })

  if (!error) return { data: true, error: null }

  const response = (error as { context?: Response }).context
  if (response && typeof response.json === 'function') {
    try {
      const payload = await response.json()
      if (payload?.error) return { data: null, error: new Error(payload.error) }
    } catch {
      // On retombe sur le message générique ci-dessous.
    }
  }
  return { data: null, error: new Error(data?.error ?? "L'envoi a échoué.") }
}

export async function markRead(conversationId: string): Promise<void> {
  await supabase
    .from('social_conversations')
    .update({ unread: 0 })
    .eq('id', conversationId)
}

/** L'abonnement temps réel vit ici pour garder les hooks sans Supabase. */
export function subscribeToWorkspaceMessages(
  workspaceId: string,
  onChange: () => void,
): () => void {
  const channel = supabase
    .channel(`social-${workspaceId}`)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'social_messages',
        filter: `workspace_id=eq.${workspaceId}`,
      },
      onChange,
    )
    .subscribe()

  return () => {
    void supabase.removeChannel(channel)
  }
}

export type { SocialPlatform }
