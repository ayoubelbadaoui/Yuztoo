import { Search } from 'lucide-react'
import { useMemo, useState } from 'react'

import { allNavItems } from '@/app/navigation'

type Props = {
  onClose: () => void
  onSelect: (id: string) => void
}

export function CommandPalette({ onClose, onSelect }: Props) {
  const [query, setQuery] = useState('')

  const results = useMemo(() => {
    const normalized = query.trim().toLowerCase()
    const items = allNavItems.filter((item) => item.id !== 'search')
    if (!normalized) return items.slice(0, 6)
    return items.filter((item) =>
      item.title.toLowerCase().includes(normalized),
    )
  }, [query])

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center bg-background/60 px-4 pt-[15vh] backdrop-blur-sm">
      <div className="absolute inset-0" onClick={onClose} />
      <div className="pop-in relative w-full max-w-xl overflow-hidden rounded-xl border border-border bg-popover shadow-2xl">
        <div className="flex items-center border-b border-border px-4">
          <Search
            className="mr-3 size-[18px] shrink-0 text-muted-foreground"
            strokeWidth={1.5}
          />
          <input
            autoFocus
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            onKeyDown={(event) => event.key === 'Escape' && onClose()}
            placeholder="Rechercher un lead, un devis, un contrat…"
            className="flex-1 bg-transparent py-4 text-[14px] text-popover-foreground outline-none placeholder:text-muted-foreground"
          />
          <kbd className="hidden h-5 items-center justify-center rounded border border-border bg-muted px-1.5 font-mono text-[10px] text-muted-foreground sm:inline-flex">
            ESC
          </kbd>
        </div>

        <div className="flex max-h-72 flex-col gap-0.5 overflow-y-auto p-2">
          {results.length === 0 && (
            <p className="px-3 py-6 text-center text-[13px] text-muted-foreground">
              Aucun résultat
            </p>
          )}
          {results.map((item) => (
            <button
              key={item.id}
              type="button"
              onClick={() => {
                onSelect(item.id)
                onClose()
              }}
              className="flex items-center gap-2.5 rounded-md px-3 py-2 text-left text-[13px] text-popover-foreground transition-colors hover:bg-accent"
            >
              <item.icon
                className="size-4 text-muted-foreground"
                strokeWidth={1.5}
              />
              {item.title}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}
