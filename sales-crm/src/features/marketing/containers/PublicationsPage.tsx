import { Plus } from 'lucide-react'
import { useState } from 'react'

import { PostComposer } from '@/features/marketing/components/PostComposer'
import { PostDetailPanel } from '@/features/marketing/components/PostDetailPanel'
import { PostsTable } from '@/features/marketing/components/PostsTable'
import type { Post } from '@/features/marketing/domain/post'
import { formatCount, postStatusLabels } from '@/features/marketing/domain/post'
import {
  useChannels,
  useMarketing,
} from '@/features/marketing/hooks/useMarketing'
import type { PostFilter } from '@/features/marketing/services/marketingService'

const filters: PostFilter[] = [
  'all',
  'draft',
  'scheduled',
  'published',
  'partial',
  'failed',
]

const filterLabels: Record<PostFilter, string> = {
  all: 'Toutes',
  ...postStatusLabels,
}

export function PublicationsPage() {
  const { filter, setFilter, posts, counts, summary, error, isLoading, reload } =
    useMarketing()
  const { channels } = useChannels()
  const [selected, setSelected] = useState<Post | null>(null)
  const [isComposing, setIsComposing] = useState(false)

  const refresh = async () => {
    setSelected(null)
    setIsComposing(false)
    await reload()
  }

  const kpis = summary
    ? [
        { label: 'Portée 30 jours', value: formatCount(summary.reach30d) },
        {
          label: 'Taux d’engagement',
          value: `${summary.engagementRate.toFixed(1).replace('.', ',')} %`,
        },
        { label: 'Programmées', value: String(summary.scheduledCount) },
        {
          label: 'Comptes connectés',
          value: String(summary.connectedCount),
          warning:
            summary.expiringCount > 0
              ? `${summary.expiringCount} jeton${summary.expiringCount > 1 ? 's' : ''} à renouveler`
              : null,
        },
      ]
    : []

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold tracking-tight text-foreground">
            Publications
          </h1>
          <p className="text-[13px] text-muted-foreground">
            Publier sur Facebook et Instagram, pour Yuztoo et pour les
            commerçants partenaires.
          </p>
        </div>

        <button
          type="button"
          onClick={() => setIsComposing(true)}
          className="flex h-9 items-center gap-1.5 rounded-lg bg-primary px-3 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90"
        >
          <Plus className="size-4" />
          Nouvelle publication
        </button>
      </header>

      {summary && (
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {kpis.map((kpi) => (
            <div
              key={kpi.label}
              className="rounded-xl border border-border bg-card p-4"
            >
              <p className="text-[12px] text-muted-foreground">{kpi.label}</p>
              <p className="mt-1 text-xl font-semibold tabular-nums text-card-foreground">
                {kpi.value}
              </p>
              {'warning' in kpi && kpi.warning && (
                <p className="mt-0.5 text-[11px] text-warning">{kpi.warning}</p>
              )}
            </div>
          ))}
        </div>
      )}

      <div className="flex flex-wrap gap-1 rounded-lg border border-border p-0.5">
        {filters.map((option) => (
          <button
            key={option}
            type="button"
            onClick={() => setFilter(option)}
            className={`flex h-8 items-center gap-1.5 rounded-[6px] px-3 text-[13px] transition-colors ${
              filter === option
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {filterLabels[option]}
            {counts && (
              <span className="text-[11px] tabular-nums opacity-70">
                {counts[option]}
              </span>
            )}
          </button>
        ))}
      </div>

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
          Impossible de charger les publications.
        </div>
      )}

      {isLoading && !error && (
        <div className="flex flex-col gap-2">
          {[0, 1, 2, 3].map((index) => (
            <div
              key={index}
              className="h-14 animate-pulse rounded-lg bg-muted"
            />
          ))}
        </div>
      )}

      {!isLoading && !error && (
        <PostsTable posts={posts} onSelect={setSelected} />
      )}

      {selected && (
        <PostDetailPanel
          post={selected}
          channels={channels}
          onClose={() => setSelected(null)}
          onChanged={() => void refresh()}
        />
      )}

      {isComposing && (
        <PostComposer
          channels={channels}
          onClose={() => setIsComposing(false)}
          onPublished={() => void refresh()}
        />
      )}
    </div>
  )
}
