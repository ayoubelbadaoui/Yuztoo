import { Search } from 'lucide-react'

import type { InboxFilter } from '@/features/inbox/services/inboxService'

const filters: InboxFilter[] = ['all', 'new', 'handled', 'archived']

const labels: Record<InboxFilter, string> = {
  all: 'Tous',
  new: 'Non lus',
  handled: 'Traités',
  archived: 'Archivés',
}

type Props = {
  filter: InboxFilter
  onFilter: (filter: InboxFilter) => void
  search: string
  onSearch: (search: string) => void
  counts: Record<InboxFilter, number> | null
}

export function InboxToolbar({
  filter,
  onFilter,
  search,
  onSearch,
  counts,
}: Props) {
  return (
    <div className="flex shrink-0 flex-col gap-2 border-b border-border p-2.5">
      <div className="flex h-9 items-center gap-2 rounded-lg border border-input bg-background px-2.5">
        <Search className="size-3.5 shrink-0 text-muted-foreground" />
        <input
          value={search}
          onChange={(event) => onSearch(event.target.value)}
          placeholder="Rechercher un expéditeur ou un mot"
          aria-label="Rechercher dans la boîte de réception"
          className="w-full bg-transparent text-[13px] text-foreground outline-none placeholder:text-muted-foreground"
        />
      </div>

      <div className="flex flex-wrap gap-1">
        {filters.map((option) => (
          <button
            key={option}
            type="button"
            onClick={() => onFilter(option)}
            className={`flex h-7 items-center gap-1.5 rounded-full px-2.5 text-[12px] transition-colors ${
              filter === option
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:bg-muted'
            }`}
          >
            {labels[option]}
            {counts && (
              <span className="text-[11px] tabular-nums opacity-70">
                {counts[option]}
              </span>
            )}
          </button>
        ))}
      </div>
    </div>
  )
}
