import type { YuztooNewsActiveFilter } from '@/features/cms-app/domain/yuztooNews'

type Props = {
  search: string
  onSearch: (value: string) => void
  activeFilter: YuztooNewsActiveFilter
  onActiveFilter: (value: YuztooNewsActiveFilter) => void
  onCreate: () => void
}

export function YuztooNewsToolbar({
  search,
  onSearch,
  activeFilter,
  onActiveFilter,
  onCreate,
}: Props) {
  return (
    <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div className="flex min-w-0 flex-1 flex-col gap-2 sm:flex-row sm:items-center">
        <input
          type="search"
          value={search}
          onChange={(event) => onSearch(event.target.value)}
          placeholder="Rechercher une actu…"
          className="h-9 w-full max-w-sm rounded-lg border border-input bg-background px-3 text-[13px] outline-none placeholder:text-muted-foreground focus:border-ring focus:ring-1 focus:ring-ring"
        />
        <select
          value={activeFilter}
          onChange={(event) =>
            onActiveFilter(event.target.value as YuztooNewsActiveFilter)
          }
          className="h-9 rounded-lg border border-input bg-background px-2 text-[13px] outline-none focus:border-ring focus:ring-1 focus:ring-ring"
        >
          <option value="all">Toutes</option>
          <option value="active">Actives</option>
          <option value="inactive">Inactives</option>
        </select>
      </div>
      <button
        type="button"
        onClick={onCreate}
        className="h-9 shrink-0 rounded-lg bg-primary px-3 text-[13px] font-medium text-primary-foreground"
      >
        Nouvelle actu
      </button>
    </div>
  )
}
