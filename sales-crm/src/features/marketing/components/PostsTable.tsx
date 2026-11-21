import { Badge } from '@/components/ui/Badge'
import type { BadgeTone } from '@/components/ui/Badge'
import type { Post, PostStatus } from '@/features/marketing/domain/post'
import {
  engagementRate,
  failedCount,
  formatCount,
  formatSchedule,
  postFormatLabels,
  postStatusLabels,
  publishedCount,
} from '@/features/marketing/domain/post'
import { recurrenceFreqLabels } from '@/features/marketing/domain/recurrence'

const tones: Record<PostStatus, BadgeTone> = {
  draft: 'neutral',
  scheduled: 'primary',
  publishing: 'warning',
  published: 'success',
  partial: 'warning',
  failed: 'danger',
}

type Props = {
  posts: Post[]
  onSelect: (post: Post) => void
}

export function PostsTable({ posts, onSelect }: Props) {
  if (posts.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-card p-10 text-center">
        <p className="text-[13px] text-muted-foreground">
          Aucune publication pour ce filtre.
        </p>
      </div>
    )
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-card">
      <table className="w-full min-w-[820px] border-collapse">
        <thead>
          <tr className="border-b border-border text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
            <th className="px-4 py-2.5 text-left">Publication</th>
            <th className="w-28 px-4 py-2.5 text-left">Format</th>
            <th className="w-28 px-4 py-2.5 text-left">Comptes</th>
            <th className="w-36 px-4 py-2.5 text-left">Date</th>
            <th className="w-32 px-4 py-2.5 text-left">Statut</th>
            <th className="hidden w-32 px-4 py-2.5 text-right lg:table-cell">
              Portée
            </th>
            <th className="hidden w-28 px-4 py-2.5 text-right lg:table-cell">
              Engagement
            </th>
          </tr>
        </thead>

        <tbody>
          {posts.map((post) => {
            const rate = engagementRate(post)
            const failed = failedCount(post)

            return (
              <tr
                key={post.id}
                tabIndex={0}
                onClick={() => onSelect(post)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter') onSelect(post)
                }}
                className="cursor-pointer border-b border-border transition-colors last:border-0 hover:bg-accent focus:bg-accent focus:outline-none"
              >
                <td className="max-w-0 px-4 py-2.5">
                  <p className="truncate text-[13px] font-medium text-card-foreground">
                    {post.caption}
                  </p>
                  <p className="truncate text-[12px] text-muted-foreground">
                    {post.mediaLabel ?? 'sans visuel'} · {post.author}
                    {post.recurrence.freq !== 'once'
                      ? ` · ${recurrenceFreqLabels[post.recurrence.freq]}`
                      : ''}
                  </p>
                </td>

                <td className="px-4 py-2.5 text-[13px] text-card-foreground">
                  {postFormatLabels[post.format]}
                </td>

                <td className="px-4 py-2.5 text-[12px] text-muted-foreground">
                  {`${publishedCount(post)}/${post.targets.length}`}
                  {failed > 0 && (
                    <span className="text-destructive">{` · ${failed} échec${failed > 1 ? 's' : ''}`}</span>
                  )}
                </td>

                <td className="px-4 py-2.5 text-[12px] text-muted-foreground">
                  {post.publishedAt
                    ? formatSchedule(post.publishedAt)
                    : post.scheduledAt
                      ? formatSchedule(post.scheduledAt)
                      : '—'}
                </td>

                <td className="px-4 py-2.5">
                  <Badge tone={tones[post.status]}>
                    {postStatusLabels[post.status]}
                  </Badge>
                </td>

                <td className="hidden px-4 py-2.5 text-right text-[13px] tabular-nums text-card-foreground lg:table-cell">
                  {post.metrics ? formatCount(post.metrics.reach) : '—'}
                </td>

                <td className="hidden px-4 py-2.5 text-right text-[13px] tabular-nums text-muted-foreground lg:table-cell">
                  {rate === null ? '—' : `${rate.toFixed(1).replace('.', ',')} %`}
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
