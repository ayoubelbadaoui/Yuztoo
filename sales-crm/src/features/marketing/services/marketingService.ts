import type {
  Post,
  PostFormat,
  PostRun,
  PostRunStatus,
  PostStatus,
} from '@/features/marketing/domain/post'
import { captionLimits, resolveStatus } from '@/features/marketing/domain/post'
import type { RecurrenceRule } from '@/features/marketing/domain/recurrence'
import { expandOccurrences } from '@/features/marketing/domain/recurrence'
import { getChannels } from '@/features/marketing/services/channelService'
import { mapPost, type PostRow } from '@/features/marketing/services/postData'
import { callEdgeFunction } from '@/lib/callEdgeFunction'
import { supabase } from '@/lib/supabaseClient'

type Result<T> = { data: T | null; error: Error | null }

export type PostFilter = PostStatus | 'all'

export type PostDraft = {
  format: PostFormat
  caption: string
  mediaId: string | null
  mediaLabel: string | null
  linkUrl: string | null
  channelIds: string[]
  scheduledAt: string | null
  author: string
  recurrence: RecurrenceRule
}

const POST_SELECT = `
  id, format, caption, link_url, media_id, status, author_label,
  scheduled_at, published_at,
  recurrence_freq, recurrence_interval, recurrence_by_weekday,
  recurrence_time_of_day, recurrence_timezone, recurrence_starts_on,
  recurrence_ends_on, recurrence_max_occurrences, recurrence_active,
  marketing_media ( original_name, public_url ),
  marketing_post_targets ( channel_id, status, error, permalink, meta_post_id )
`

async function validate(draft: PostDraft) {
  if (draft.caption.trim().length < 3) throw new Error('Le texte est vide')
  if (draft.caption.length > captionLimits[draft.format]) {
    throw new Error(
      `Le texte dépasse ${captionLimits[draft.format]} caractères pour ce format`,
    )
  }
  if (draft.channelIds.length === 0) {
    throw new Error('Choisissez au moins un compte de destination')
  }
  if (draft.format !== 'post' && !draft.mediaId) {
    throw new Error('Une story ou un reel demande un visuel')
  }
  if (draft.scheduledAt && new Date(draft.scheduledAt) < new Date()) {
    throw new Error('La date de programmation est déjà passée')
  }
  if (draft.recurrence.freq === 'weekly' && draft.recurrence.byWeekday.length === 0) {
    throw new Error('Choisissez au moins un jour de la semaine')
  }

  // IG (alone or with FB): Graph refuses an IG publish without public media.
  const { data: kinds, error } = await supabase
    .from('marketing_channels')
    .select('kind')
    .in('id', draft.channelIds)
  if (error) throw new Error(error.message)
  const hasIg = (kinds ?? []).some((row) => row.kind === 'instagram')
  if (hasIg && !draft.mediaId) {
    throw new Error(
      'Instagram exige un visuel — ajoutez une image ou une vidéo (ou retirez IG)',
    )
  }
}

async function loadPost(id: string): Promise<Post> {
  const { data, error } = await supabase
    .from('marketing_posts')
    .select(POST_SELECT)
    .eq('id', id)
    .single()
  if (error || !data) throw new Error(error?.message ?? `Publication ${id} introuvable`)
  return mapPost(data as PostRow)
}

export async function getPosts(
  workspaceId: string,
  filter: PostFilter = 'all',
): Promise<Result<Post[]>> {
  try {
    let query = supabase
      .from('marketing_posts')
      .select(POST_SELECT)
      .eq('workspace_id', workspaceId)
      .order('created_at', { ascending: false })

    if (filter !== 'all') query = query.eq('status', filter)

    const { data, error } = await query
    if (error) throw new Error(error.message)
    return {
      data: (data as PostRow[]).map(mapPost),
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getPostCounts(
  workspaceId: string,
): Promise<Result<Record<PostFilter, number>>> {
  try {
    const { data, error } = await supabase
      .from('marketing_posts')
      .select('status')
      .eq('workspace_id', workspaceId)
    if (error) throw new Error(error.message)
    const rows = data ?? []
    const count = (status: PostStatus) =>
      rows.filter((row) => row.status === status).length
    return {
      data: {
        all: rows.length,
        draft: count('draft'),
        scheduled: count('scheduled'),
        publishing: count('publishing'),
        published: count('published'),
        partial: count('partial'),
        failed: count('failed'),
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export type MarketingSummary = {
  reach30d: number
  engagementRate: number
  scheduledCount: number
  connectedCount: number
  expiringCount: number
}

export async function getMarketingSummary(
  workspaceId: string,
): Promise<Result<MarketingSummary>> {
  try {
    const [{ data: channels, error: channelError }, counts] = await Promise.all([
      getChannels(workspaceId),
      getPostCounts(workspaceId),
    ])
    if (channelError) throw channelError
    if (counts.error) throw counts.error
    const list = channels ?? []

    return {
      data: {
        reach30d: 0,
        engagementRate: 0,
        scheduledCount: counts.data?.scheduled ?? 0,
        connectedCount: list.filter((channel) => channel.status !== 'disconnected')
          .length,
        expiringCount: list.filter((channel) => channel.status === 'expiring')
          .length,
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

async function enqueueJobs(input: {
  workspaceId: string
  postId: string
  runId: string
  channelIds: string[]
  runAt: Date
}) {
  const rows = input.channelIds.map((channelId) => ({
    workspace_id: input.workspaceId,
    post_id: input.postId,
    run_id: input.runId,
    channel_id: channelId,
    status: 'pending' as const,
    next_attempt_at: input.runAt.toISOString(),
  }))
  const { error } = await supabase.from('marketing_publish_jobs').insert(rows)
  if (error) throw new Error(error.message)
}

export async function createPost(
  workspaceId: string,
  draft: PostDraft,
): Promise<Result<Post>> {
  try {
    await validate(draft)
    const isRecurring = draft.recurrence.freq !== 'once'
    const firstAt = draft.scheduledAt
      ? new Date(draft.scheduledAt)
      : new Date()

    const { data: postRow, error: postError } = await supabase
      .from('marketing_posts')
      .insert({
        workspace_id: workspaceId,
        format: draft.format,
        caption: draft.caption.trim(),
        link_url: draft.linkUrl,
        media_id: draft.mediaId,
        status: draft.scheduledAt || isRecurring ? 'scheduled' : 'publishing',
        author_label: draft.author,
        scheduled_at: firstAt.toISOString(),
        recurrence_freq: draft.recurrence.freq,
        recurrence_interval: draft.recurrence.interval,
        recurrence_by_weekday: draft.recurrence.byWeekday,
        recurrence_time_of_day: draft.recurrence.timeOfDay,
        recurrence_timezone: draft.recurrence.timezone,
        recurrence_starts_on: draft.recurrence.startsOn,
        recurrence_ends_on: draft.recurrence.endsOn,
        recurrence_max_occurrences: draft.recurrence.maxOccurrences,
        recurrence_active: isRecurring,
      })
      .select('id')
      .single()

    if (postError || !postRow) {
      throw new Error(postError?.message ?? 'Création impossible')
    }

    const { error: targetError } = await supabase
      .from('marketing_post_targets')
      .insert(
        draft.channelIds.map((channelId) => ({
          post_id: postRow.id,
          workspace_id: workspaceId,
          channel_id: channelId,
          status: 'pending',
        })),
      )
    if (targetError) throw new Error(targetError.message)

    const occurrences = expandOccurrences(draft.recurrence, firstAt)
    const runRows = occurrences.map((when, index) => ({
      post_id: postRow.id,
      workspace_id: workspaceId,
      occurrence_index: index + 1,
      run_at: when.toISOString(),
      status: 'pending' as const,
    }))
    const { data: runs, error: runError } = await supabase
      .from('marketing_post_runs')
      .insert(runRows)
      .select('id, occurrence_index, run_at')
    if (runError || !runs?.length) {
      throw new Error(runError?.message ?? 'Planification impossible')
    }

    for (const run of runs) {
      await enqueueJobs({
        workspaceId,
        postId: postRow.id,
        runId: run.id,
        channelIds: draft.channelIds,
        runAt: new Date(run.run_at),
      })
    }

    // Immediate first run: invoke Edge now (local/prod worker later).
    const firstRun = runs.find((run) => run.occurrence_index === 1)
    if (firstRun && new Date(firstRun.run_at).getTime() <= Date.now() + 15_000) {
      await publishNow(workspaceId, postRow.id)
    }

    const post = await loadPost(postRow.id)
    return { data: post, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function publishNow(
  workspaceId: string,
  id: string,
): Promise<Result<Post>> {
  try {
    const { data, error } = await callEdgeFunction<{
      ok?: boolean
      error?: string
    }>('meta-publish-post', { workspaceId, postId: id })
    if (error) throw error
    if (data && data.ok === false) {
      throw new Error(data.error ?? 'Publication refusée')
    }
    const post = await loadPost(id)
    return { data: { ...post, status: resolveStatus(post) }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function retryFailedTargets(
  workspaceId: string,
  id: string,
): Promise<Result<Post>> {
  return publishNow(workspaceId, id)
}

export async function getPostRuns(
  postId: string,
): Promise<Result<PostRun[]>> {
  try {
    const { data, error } = await supabase
      .from('marketing_post_runs')
      .select('id, occurrence_index, run_at, status')
      .eq('post_id', postId)
      .order('occurrence_index', { ascending: true })
    if (error) throw new Error(error.message)
    return {
      data: (data ?? []).map((row) => ({
        id: row.id as string,
        occurrenceIndex: row.occurrence_index as number,
        runAt: row.run_at as string,
        status: row.status as PostRunStatus,
      })),
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function cancelPost(id: string): Promise<Result<Post>> {
  try {
    const post = await loadPost(id)
    if (post.status === 'published' || post.status === 'partial') {
      throw new Error(
        'Une publication déjà partie ne s’annule pas ici — seuls les runs futurs restent annulables côté file',
      )
    }
    const { error } = await supabase
      .from('marketing_posts')
      .update({
        status: 'draft',
        scheduled_at: null,
        recurrence_active: false,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
    if (error) throw new Error(error.message)

    await supabase
      .from('marketing_post_runs')
      .update({ status: 'cancelled' })
      .eq('post_id', id)
      .eq('status', 'pending')

    await supabase
      .from('marketing_publish_jobs')
      .update({ status: 'cancelled' })
      .eq('post_id', id)
      .eq('status', 'pending')

    return { data: await loadPost(id), error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
