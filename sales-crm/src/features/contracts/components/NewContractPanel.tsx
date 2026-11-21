import { X } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'

import { Combobox } from '@/components/ui/Combobox'
import { Field } from '@/components/ui/Field'
import { quoteOptions } from '@/features/quotes/components/quoteOptions'
import {
  createContractFromQuote,
  getContractableQuotes,
} from '@/features/contracts/services/contractService'
import { plans } from '@/features/quotes/domain/catalog'
import { computeTotals } from '@/features/quotes/domain/pricing'
import type { Quote } from '@/features/quotes/domain/quote'
import { formatEuro } from '@/lib/money'

type Props = {
  onClose: () => void
  onCreated: () => void
}

export function NewContractPanel({ onClose, onCreated }: Props) {
  const [quotes, setQuotes] = useState<Quote[]>([])
  const [quoteId, setQuoteId] = useState('')
  const [isBusy, setIsBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void getContractableQuotes().then(({ data }) => setQuotes(data ?? []))
  }, [])

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  const options = useMemo(() => quoteOptions(quotes), [quotes])
  const selected = quotes.find((quote) => quote.id === quoteId) ?? null

  const submit = async () => {
    if (!selected) {
      setError('Choisissez un devis accepté.')
      return
    }

    setIsBusy(true)
    const { error: failure } = await createContractFromQuote(selected.id)
    setIsBusy(false)

    if (failure) {
      setError(failure.message)
      return
    }
    onCreated()
  }

  return (
    <div className="fixed inset-0 z-40 flex justify-end">
      <button
        type="button"
        aria-label="Fermer le panneau"
        onClick={onClose}
        className="absolute inset-0 bg-foreground/20"
      />

      <aside
        role="dialog"
        aria-modal="true"
        aria-label="Nouveau contrat"
        className="pop-in relative flex h-full w-full max-w-sm flex-col border-l border-border bg-card shadow-2xl"
      >
        <header className="flex shrink-0 items-start justify-between gap-3 border-b border-border p-4">
          <div>
            <h2 className="text-[15px] font-semibold text-card-foreground">
              Nouveau contrat
            </h2>
            <p className="text-[12px] text-muted-foreground">
              Généré depuis un devis accepté
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Fermer"
            className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          >
            <X className="size-4" />
          </button>
        </header>

        <form
          onSubmit={(event) => {
            event.preventDefault()
            void submit()
          }}
          className="flex min-h-0 flex-1 flex-col"
        >
          <div className="scrollbar-none flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto p-4">
            {quotes.length === 0 ? (
              <p className="rounded-lg border border-border bg-muted/40 p-3 text-[12px] text-muted-foreground">
                Aucun devis accepté sans contrat. Faites accepter un devis dans
                l’onglet Devis pour générer un contrat.
              </p>
            ) : (
              <Field
                label="Devis accepté"
                htmlFor="contract-quote"
                hint="Les conditions sont figées à la génération du contrat."
              >
                <Combobox
                  options={options}
                  value={quoteId}
                  onChange={(id) => {
                    setQuoteId(id)
                    setError(null)
                  }}
                  placeholder="Rechercher un client…"
                  searchPlaceholder="Nom, commerce ou n° de devis"
                  emptyLabel="Aucun devis ne correspond."
                />
              </Field>
            )}

            {selected && (
              <div className="flex flex-col gap-2 rounded-lg border border-border bg-muted/40 p-3">
                <div className="flex items-center justify-between gap-2">
                  <span className="text-[12px] text-muted-foreground">
                    Formule
                  </span>
                  <span className="text-[12px] text-card-foreground">
                    {plans[selected.planId].name}
                  </span>
                </div>
                <div className="flex items-center justify-between gap-2">
                  <span className="text-[12px] text-muted-foreground">
                    Mensuel
                  </span>
                  <span className="text-[12px] font-medium tabular-nums text-card-foreground">
                    {formatEuro(computeTotals(selected).monthlyTotal)}
                  </span>
                </div>
                <div className="flex items-center justify-between gap-2">
                  <span className="text-[12px] text-muted-foreground">
                    Engagement
                  </span>
                  <span className="text-[12px] text-card-foreground">
                    {`${selected.engagementMonths} mois`}
                  </span>
                </div>
              </div>
            )}

            {error && (
              <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
                {error}
              </p>
            )}
          </div>

          <footer className="flex shrink-0 items-center justify-end gap-2 border-t border-border p-4">
            <button
              type="button"
              onClick={onClose}
              className="h-9 rounded-lg border border-border px-3 text-[13px] text-foreground transition-colors hover:bg-muted"
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={!selected || isBusy}
              className="h-9 rounded-lg bg-primary px-3.5 text-[13px] font-medium text-primary-foreground transition-opacity disabled:opacity-40"
            >
              {isBusy ? 'Génération…' : 'Générer le contrat'}
            </button>
          </footer>
        </form>
      </aside>
    </div>
  )
}
