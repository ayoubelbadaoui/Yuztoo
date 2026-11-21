import type {
  Channel,
  ChannelKind,
  ConnectionStatus,
} from '@/features/marketing/domain/channel'
import { supabase } from '@/lib/supabaseClient'

type Result<T> = { data: T | null; error: Error | null }

type ChannelRow = {
  id: string
  kind: ChannelKind
  name: string
  handle: string
  meta_page_id: string | null
  meta_ig_id: string | null
  status: ConnectionStatus
  token_expires_at: string | null
  followers: number
  picture_url: string | null
  owner: string
  subscribed: boolean
}

const SELECT =
  'id, kind, name, handle, meta_page_id, meta_ig_id, status, token_expires_at, followers, picture_url, owner, subscribed'

/** Un jeton qui expire sous une semaine doit alerter avant la panne nocturne. */
function resolveStatus(row: ChannelRow): ConnectionStatus {
  if (row.status === 'disconnected') return 'disconnected'
  if (!row.token_expires_at) return row.status
  const days =
    (new Date(row.token_expires_at).getTime() - Date.now()) / 86_400_000
  if (days <= 0) return 'disconnected'
  if (days <= 7) return 'expiring'
  return 'connected'
}

function toChannel(row: ChannelRow): Channel {
  return {
    id: row.id,
    kind: row.kind,
    name: row.name,
    handle: row.handle,
    metaId: (row.kind === 'instagram' ? row.meta_ig_id : row.meta_page_id) ?? '',
    pageMetaId: row.meta_page_id,
    owner: row.owner === 'merchant' ? 'merchant' : 'yuztoo',
    city: null,
    planName: null,
    followers: row.followers,
    pictureUrl: row.picture_url,
    subscribed: row.subscribed,
    status: resolveStatus(row),
    tokenExpiresAt: row.token_expires_at,
  }
}

export async function getChannels(
  workspaceId: string,
): Promise<Result<Channel[]>> {
  const { data, error } = await supabase
    .from('marketing_channels')
    .select(SELECT)
    .eq('workspace_id', workspaceId)
    .order('kind', { ascending: true })
    .order('name', { ascending: true })

  if (error) return { data: null, error: new Error(error.message) }
  return { data: (data as ChannelRow[]).map(toChannel), error: null }
}
