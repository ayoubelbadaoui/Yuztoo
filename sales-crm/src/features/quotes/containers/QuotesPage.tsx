import { Plus } from 'lucide-react'
import { useState } from 'react'

import { formatEuro } from '@/features/quotes/domain/catalog'
import type { Quote } from '@/features/quotes/domain/quote'
import { quoteStatusLabels } from '@/features/quotes/domain/quote'
import { QuoteBuilderPanel } from '@/features/quotes/components/QuoteBuilderPanel'
import { QuotesTable } from '@/features/quotes/components/QuotesTable'
import type { QuoteFilter } from '@/features/quotes/hooks/useQuotes'
import { useQuotes } from '@/features/quotes/hooks/useQuotes'
import { quoteAmount } from '@/features/quotes/services/quoteService'

const filters: QuoteFilter[] = ['all', 'draft', 'sent', 'accepted', 'refused']

const filterLabels: Record<QuoteFilter, string> = {
  all: 'Tous',
  ...quoteStatusLabels,
}

export function QuotesPage() {
  const { filter, setFilter, quotes, counts, error, isLoading, reload } =
    useQuotes()
  const [editing, setEditing] = useState<Quote | null>(null)
  const [isCreating, setIsCreating] = useState(false)

  const isPanelOpen = isCreating || editing !== null
  const total = quotes.reduce((sum, quote) => sum + quoteAmount(quote), 0)

  const closePanel = () => {
    setEditing(null)
    setIsCreating(false)
  }

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold tracking-tight text-foreground">
            Devis
          </h1>
          <p className="text-[13px] text-muted-foreground">
            {`${quotes.length} devis · ${formatEuro(total)} au total.`}
          </p>
        </div>

        <button
          type="button"
          onClick={() => setIsCreating(true)}
          className="flex h-9 items-center gap-1.5 rounded-lg bg-primary px-3 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90"
        >
          <Plus className="size-4" />
          Nouveau devis
        </button>
      </header>

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
          Impossible de charger les devis.
        </div>
      )}

      {isLoading && !error && (
        <div className="flex flex-col gap-2">
          {[0, 1, 2, 3, 4].map((index) => (
            <div key={index} className="h-14 animate-pulse rounded-lg bg-muted" />
          ))}
        </div>
      )}

      {!isLoading && !error && (
        <QuotesTable quotes={quotes} onSelect={setEditing} />
      )}

      {isPanelOpen && (
        <QuoteBuilderPanel
          quote={editing}
          onClose={closePanel}
          onSaved={() => {
            closePanel()
            void reload()
          }}
        />
      )}
    </div>
  )
}
