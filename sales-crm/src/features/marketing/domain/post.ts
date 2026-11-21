import type { RecurrenceRule } from '@/features/marketing/domain/recurrence'
import { defaultRecurrence } from '@/features/marketing/domain/recurrence'

export type PostFormat = 'post' | 'story' | 'reel'

export const postFormatLabels: Record<PostFormat, string> = {
  post: 'Publication',
  story: 'Story',
  reel: 'Reel',
}

/** Limites Meta, vérifiées avant l'envoi pour ne pas se faire refuser le lot. */
export const captionLimits: Record<PostFormat, number> = {
  post: 2200,
  story: 2200,
  reel: 2200,
}

export type PostStatus =
  | 'draft'
  | 'scheduled'
  | 'publishing'
  | 'published'
  | 'partial'
  | 'failed'

export const postStatusLabels: Record<PostStatus, string> = {
  draft: 'Brouillon',
  scheduled: 'Programmée',
  publishing: 'En cours',
  published: 'Publiée',
  partial: 'Partiellement publiée',
  failed: 'Échouée',
}

export type TargetStatus = 'pending' | 'published' | 'failed'

/** Une publication part vers plusieurs comptes : chacun réussit ou échoue seul. */
export type PostTarget = {
  channelId: string
  status: TargetStatus
  error: string | null
  permalink: string | null
  metaPostId?: string | null
}

export type PostRunStatus =
  | 'pending'
  | 'publishing'
  | 'published'
  | 'partial'
  | 'failed'
  | 'cancelled'
  | 'skipped'

export const postRunStatusLabels: Record<PostRunStatus, string> = {
  pending: 'À venir',
  publishing: 'En cours',
  published: 'Publiée',
  partial: 'Partielle',
  failed: 'Échouée',
  cancelled: 'Annulée',
  skipped: 'Ignorée',
}

/** Une occurrence d’une série (récurrence) ou le run unique d’un one-shot. */
export type PostRun = {
  id: string
  occurrenceIndex: number
  runAt: string
  status: PostRunStatus
}

export type PostMetrics = {
  reach: number
  engagements: number
  clicks: number
}

export type Post = {
  id: string
  format: PostFormat
  caption: string
  mediaId: string | null
  mediaLabel: string | null
  mediaUrl: string | null
  linkUrl: string | null
  status: PostStatus
  scheduledAt: string | null
  publishedAt: string | null
  author: string
  targets: PostTarget[]
  metrics: PostMetrics | null
  recurrence: RecurrenceRule
}

export function emptyPostDraft(): Pick<
  Post,
  'format' | 'caption' | 'mediaId' | 'mediaLabel' | 'mediaUrl' | 'linkUrl' | 'recurrence'
> {
  return {
    format: 'post',
    caption: '',
    mediaId: null,
    mediaLabel: null,
    mediaUrl: null,
    linkUrl: null,
    recurrence: defaultRecurrence(),
  }
}

export function publishedCount(post: Post): number {
  return post.targets.filter((target) => target.status === 'published').length
}

export function failedCount(post: Post): number {
  return post.targets.filter((target) => target.status === 'failed').length
}

/** Statut global déduit des cibles : un lot à moitié parti doit se voir. */
export function resolveStatus(post: Post): PostStatus {
  const published = publishedCount(post)
  const failed = failedCount(post)
  if (published === 0 && failed > 0) return 'failed'
  if (failed > 0) return 'partial'
  if (published === post.targets.length && published > 0) return 'published'
  return post.status
}

export function engagementRate(post: Post): number | null {
  if (!post.metrics || post.metrics.reach === 0) return null
  return (post.metrics.engagements / post.metrics.reach) * 100
}

export function formatCount(value: number): string {
  return new Intl.NumberFormat('fr-FR').format(value)
}

export function formatSchedule(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(iso))
}
