import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useMemo, useState } from 'react'

import { networkMixLabel } from '@/features/marketing/domain/channel'
import type { Post } from '@/features/marketing/domain/post'
import {
  formatSchedule,
  postFormatLabels,
} from '@/features/marketing/domain/post'
import { recurrenceFreqLabels } from '@/features/marketing/domain/recurrence'
import { PostDetailPanel } from '@/features/marketing/components/PostDetailPanel'
import {
  useChannels,
  useMarketing,
} from '@/features/marketing/hooks/useMarketing'
import {
  formatMonthLabel,
  isSameDay,
  monthGridDays,
  weekdayLabels,
} from '@/lib/dates'

export function ContentCalendarPage() {
  const { posts, reload } = useMarketing()
  const { channels } = useChannels()
  const [anchor, setAnchor] = useState(() => new Date())
  const [selected, setSelected] = useState<Post | null>(null)

  const days = useMemo(() => monthGridDays(anchor), [anchor])
  const today = new Date()

  const shiftMonth = (offset: number) => {
    setAnchor((current) => {
      const next = new Date(current)
      next.setMonth(next.getMonth() + offset)
      return next
    })
  }

  const postsOn = (day: Date) =>
    posts.filter((post) => {
      const when = post.scheduledAt ?? post.publishedAt
      return when ? isSameDay(new Date(when), day) : false
    })

  return (
    <div className="flex h-full min-h-0 flex-col gap-4">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold tracking-tight text-foreground">
            Calendrier éditorial
          </h1>
          <p className="text-[13px] text-muted-foreground">
            Ce qui part, quand, et sur combien de comptes.
          </p>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            type="button"
            onClick={() => shiftMonth(-1)}
            aria-label="Mois précédent"
            className="rounded-md border border-border p-1.5 text-muted-foreground transition-colors hover:bg-muted"
          >
            <ChevronLeft className="size-4" />
          </button>
          <span className="min-w-36 text-center text-[13px] font-medium text-foreground">
            {formatMonthLabel(anchor)}
          </span>
          <button
            type="button"
            onClick={() => shiftMonth(1)}
            aria-label="Mois suivant"
            className="rounded-md border border-border p-1.5 text-muted-foreground transition-colors hover:bg-muted"
          >
            <ChevronRight className="size-4" />
          </button>
          <button
            type="button"
            onClick={() => setAnchor(new Date())}
            className="h-8 rounded-lg border border-border px-2.5 text-[12px] text-foreground transition-colors hover:bg-muted"
          >
            Ce mois
          </button>
        </div>
      </header>

      <div className="flex min-h-[32rem] flex-1 flex-col overflow-hidden rounded-xl border border-border bg-card">
        <div className="grid shrink-0 grid-cols-7 border-b border-border">
          {weekdayLabels.map((label) => (
            <span
              key={label}
              className="px-2 py-1.5 text-center text-[11px] font-semibold uppercase tracking-wide text-muted-foreground"
            >
              {label}
            </span>
          ))}
        </div>

        <div className="grid min-h-0 flex-1 grid-cols-7 grid-rows-6">
          {days.map((day) => {
            const dayPosts = postsOn(day)
            const isCurrentMonth = day.getMonth() === anchor.getMonth()

            return (
              <div
                key={day.toISOString()}
                className={`scrollbar-none flex min-h-0 flex-col gap-1 overflow-y-auto border-b border-r border-border p-1 last:border-r-0 ${
                  isCurrentMonth ? '' : 'bg-muted/30'
                }`}
              >
                <span
                  className={`text-[11px] tabular-nums ${
                    isSameDay(day, today)
                      ? 'font-semibold text-primary'
                      : isCurrentMonth
                        ? 'text-muted-foreground'
                        : 'text-muted-foreground/50'
                  }`}
                >
                  {day.getDate()}
                </span>

                {dayPosts.map((post) => {
                  const targets = post.targets
                    .map((target) =>
                      channels.find(
                        (channel) => channel.id === target.channelId,
                      ),
                    )
                    .filter((channel): channel is NonNullable<typeof channel> =>
                      Boolean(channel),
                    )
                  return (
                    <button
                      key={post.id}
                      type="button"
                      onClick={() => setSelected(post)}
                      title={`${postFormatLabels[post.format]} · ${networkMixLabel(targets)}`}
                      className={`flex w-full flex-col gap-0.5 rounded-md px-1.5 py-1 text-left transition-colors ${
                        post.status === 'published'
                          ? 'bg-success/10 hover:bg-success/20'
                          : post.status === 'failed' ||
                              post.status === 'partial'
                            ? 'bg-destructive/10 hover:bg-destructive/20'
                            : 'bg-primary/10 hover:bg-primary/20'
                      }`}
                    >
                      <span className="truncate text-[10px] font-medium text-foreground">
                        {postFormatLabels[post.format]}
                        {post.recurrence.freq !== 'once'
                          ? ` · ${recurrenceFreqLabels[post.recurrence.freq]}`
                          : ''}
                      </span>
                      <span className="truncate text-[10px] text-muted-foreground">
                        {post.caption}
                      </span>
                      <span className="truncate text-[10px] text-muted-foreground">
                        {targets.length > 0
                          ? networkMixLabel(targets)
                          : `${post.targets.length} comptes`}
                      </span>
                    </button>
                  )
                })}
              </div>
            )
          })}
        </div>
      </div>

      {selected && (
        <PostDetailPanel
          post={selected}
          channels={channels}
          onClose={() => setSelected(null)}
          onChanged={() => {
            setSelected(null)
            void reload()
          }}
        />
      )}

      <p className="shrink-0 text-[11px] text-muted-foreground">
        {posts.length > 0 &&
          `Prochaine sortie : ${
            posts
              .filter((post) => post.status === 'scheduled' && post.scheduledAt)
              .sort((a, b) =>
                (a.scheduledAt ?? '').localeCompare(b.scheduledAt ?? ''),
              )
              .map((post) => formatSchedule(post.scheduledAt as string))[0] ??
            'aucune'
          }`}
      </p>
    </div>
  )
}
