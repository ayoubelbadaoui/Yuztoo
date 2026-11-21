import { Search, SlidersHorizontal } from 'lucide-react'

import type { LeadSegment } from '@/features/leads/hooks/useLeadsTable'

type Props = {
  segment: LeadSegment
  onSegmentChange: (segment: LeadSegment) => void
  counts: { all: number; merchant: number; client: number } | null
  search: string
  onSearchChange: (value: string) => void
}

const segments: { id: LeadSegment; label: string }[] = [
  { id: 'all', label: 'Tous' },
  { id: 'merchant', label: 'Commerçants' },
  { id: 'client', label: 'Clients' },
]

export function LeadsToolbar({
  segment,
  onSegmentChange,
  counts,
  search,
  onSearchChange,
}: Props) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <div className="inline-flex rounded-lg border border-border bg-card p-0.5">
        {segments.map((item) => (
          <button
            key={item.id}
            type="button"
            onClick={() => onSegmentChange(item.id)}
            className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 text-[13px] transition-colors ${
              segment === item.id
                ? 'bg-accent font-medium text-accent-foreground'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {item.label}
            {counts && (
              <span className="text-[11px] tabular-nums text-muted-foreground">
                {counts[item.id]}
              </span>
            )}
          </button>
        ))}
      </div>

      <div className="flex items-center gap-2">
        <div className="flex h-9 items-center gap-2 rounded-lg border border-border bg-card px-2.5">
          <Search className="size-4 text-muted-foreground" strokeWidth={1.5} />
          <input
            value={search}
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder="Nom, commerce, ville…"
            className="w-48 bg-transparent text-[13px] text-foreground outline-none placeholder:text-muted-foreground"
          />
        </div>
        <button
          type="button"
          className="flex h-9 items-center gap-2 rounded-lg border border-border bg-card px-3 text-[13px] text-muted-foreground transition-colors hover:text-foreground"
        >
          <SlidersHorizontal className="size-4" strokeWidth={1.5} />
          Filtres
        </button>
      </div>
    </div>
  )
}
