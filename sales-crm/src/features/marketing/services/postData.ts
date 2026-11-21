import type { Post, PostFormat, PostStatus, PostTarget } from '@/features/marketing/domain/post'
import type { RecurrenceFreq } from '@/features/marketing/domain/recurrence'
import { defaultRecurrence } from '@/features/marketing/domain/recurrence'

export type PostRow = {
  id: string
  format: PostFormat
  caption: string
  link_url: string | null
  media_id: string | null
  status: PostStatus
  author_label: string
  scheduled_at: string | null
  published_at: string | null
  recurrence_freq: RecurrenceFreq
  recurrence_interval: number
  recurrence_by_weekday: number[]
  recurrence_time_of_day: string
  recurrence_timezone: string
  recurrence_starts_on: string | null
  recurrence_ends_on: string | null
  recurrence_max_occurrences: number | null
  recurrence_active: boolean
  marketing_media?: {
    original_name: string | null
    public_url: string | null
  } | null
  marketing_post_targets?: Array<{
    channel_id: string
    status: PostTarget['status']
    error: string | null
    permalink: string | null
    meta_post_id: string | null
  }>
}

export function mapPost(row: PostRow): Post {
  const recurrence = defaultRecurrence()
  recurrence.freq = row.recurrence_freq
  recurrence.interval = row.recurrence_interval
  recurrence.byWeekday = row.recurrence_by_weekday ?? []
  recurrence.timeOfDay = String(row.recurrence_time_of_day).slice(0, 5)
  recurrence.timezone = row.recurrence_timezone
  recurrence.startsOn = row.recurrence_starts_on
  recurrence.endsOn = row.recurrence_ends_on
  recurrence.maxOccurrences = row.recurrence_max_occurrences

  return {
    id: row.id,
    format: row.format,
    caption: row.caption,
    mediaId: row.media_id,
    mediaLabel: row.marketing_media?.original_name ?? null,
    mediaUrl: row.marketing_media?.public_url ?? null,
    linkUrl: row.link_url,
    status: row.status,
    scheduledAt: row.scheduled_at,
    publishedAt: row.published_at,
    author: row.author_label,
    targets: (row.marketing_post_targets ?? []).map((target) => ({
      channelId: target.channel_id,
      status: target.status,
      error: target.error,
      permalink: target.permalink,
      metaPostId: target.meta_post_id,
    })),
    metrics: null,
    recurrence,
  }
}
