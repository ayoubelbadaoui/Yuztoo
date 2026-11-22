import type { SocialPlatform } from '@/features/social/domain/conversation'
import { callEdgeFunction } from '@/lib/callEdgeFunction'
import { supabase } from '@/lib/supabaseClient'

type Result<T> = { data: T | null; error: Error | null }

export type InboxChannel = {
  id: string
  name: string
  platform: SocialPlatform
}

type ImportPage = {
  conversations: number
  imported: number
  nextCursor: string | null
}

/** Connected FB Pages / IG accounts of the workspace (disconnected excluded). */
export async function listInboxChannels(
  workspaceId: string,
): Promise<Result<InboxChannel[]>> {
  const { data, error } = await supabase
    .from('marketing_channels')
    .select('id, name, kind, status')
    .eq('workspace_id', workspaceId)
    .neq('status', 'disconnected')
    .order('kind', { ascending: true })
  if (error) return { data: null, error: new Error(error.message) }
  return {
    data: (data ?? []).map((row) => ({
      id: row.id as string,
      name: row.name as string,
      platform: row.kind === 'instagram' ? 'instagram' : 'messenger',
    })),
    error: null,
  }
}

/** One batch (10 conversations) of Meta history for a channel. */
export async function importHistoryPage(
  channelId: string,
  cursor: string | null,
): Promise<Result<ImportPage>> {
  const { data, error } = await callEdgeFunction<ImportPage>(
    'meta-import-history',
    { channelId, cursor },
  )
  if (error || !data) return { data: null, error: error ?? new Error('Import impossible') }
  return { data, error: null }
}
