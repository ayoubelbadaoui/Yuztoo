import type { ClientStatus } from '@/features/cms-app/domain/cms'
import { clientStatusLabels } from '@/features/cms-app/domain/cms'

const statusFilters: Array<ClientStatus | 'all'> = [
  'all',
  'active',
  'blocked',
  'deleted',
]

type Props = {
  search: string
  onSearch: (value: string) => void
  status: ClientStatus | 'all'
  onStatus: (value: ClientStatus | 'all') => void
}

export function ClientsToolbar({ search, onSearch, status, onStatus }: Props) {
  return (
    <div className="flex flex-wrap items-center gap-2">
      <input
        type="search"
        value={search}
        onChange={(event) => onSearch(event.target.value)}
        placeholder="Rechercher un client…"
        className="h-9 min-w-[200px] flex-1 rounded-lg border border-input bg-background px-3 text-[13px] text-foreground outline-none placeholder:text-muted-foreground focus:border-ring focus:ring-1 focus:ring-ring"
      />
      <select
        value={status}
        onChange={(event) =>
          onStatus(event.target.value as ClientStatus | 'all')
        }
        className="h-9 rounded-lg border border-input bg-background px-2.5 text-[13px] text-foreground outline-none"
      >
        {statusFilters.map((value) => (
          <option key={value} value={value}>
            {value === 'all' ? 'Tous les statuts' : clientStatusLabels[value]}
          </option>
        ))}
      </select>
    </div>
  )
}
