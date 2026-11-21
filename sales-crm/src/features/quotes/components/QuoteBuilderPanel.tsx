import { X } from 'lucide-react'
import { useEffect } from 'react'

import { Field, controlClass } from '@/components/ui/Field'
import type { EngagementMonths } from '@/features/quotes/domain/catalog'
import {
  engagements,
  moduleOrder,
  modules,
  plans,
} from '@/features/quotes/domain/catalog'
import type { Quote, QuoteStatus } from '@/features/quotes/domain/quote'
import { quoteStatusLabels } from '@/features/quotes/domain/quote'
import { LeadCombobox } from '@/features/quotes/components/LeadCombobox'
import { PlanPicker } from '@/features/quotes/components/PlanPicker'
import { QuoteSummary } from '@/features/quotes/components/QuoteSummary'
import { useQuoteBuilder } from '@/features/quotes/hooks/useQuoteBuilder'

type Props = {
  quote: Quote | null
  onClose: () => void
  onSaved: () => void
}

export function QuoteBuilderPanel({ quote, onClose, onSaved }: Props) {
  const {
    values,
    leads,
    totals,
    setField,
    setPlan,
    setEngagement,
    toggleModule,
    isSaving,
    error,
    submit,
  } = useQuoteBuilder(quote, onSaved)

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  const plan = plans[values.planId]

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
        aria-label={quote ? `Modifier ${quote.id}` : 'Nouveau devis'}
        className="pop-in relative flex h-full w-full max-w-md flex-col border-l border-border bg-card shadow-2xl"
      >
        <header className="flex shrink-0 items-start justify-between gap-3 border-b border-border p-4">
          <div className="min-w-0">
            <h2 className="truncate text-[15px] font-semibold text-card-foreground">
              {quote ? 'Modifier le devis' : 'Nouveau devis'}
            </h2>
            <p className="truncate text-[12px] text-muted-foreground">
              {quote ? quote.id : 'Grille tarifaire Yuztoo'}
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
            <div className="flex flex-col gap-1.5">
              <span className="text-[12px] font-medium text-muted-foreground">
                Lead
              </span>
              <LeadCombobox
                leads={leads}
                value={values.leadId}
                onChange={(leadId) => setField('leadId', leadId)}
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <span className="text-[12px] font-medium text-muted-foreground">
                Formule
              </span>
              <PlanPicker value={values.planId} onChange={setPlan} />
            </div>

            <div className="flex flex-col gap-1.5">
              <span className="text-[12px] font-medium text-muted-foreground">
                Modules à la carte
              </span>
              <div className="flex flex-col gap-1.5">
                {moduleOrder.map((moduleId) => (
                  <label
                    key={moduleId}
                    className="flex cursor-pointer items-center justify-between gap-2 rounded-lg border border-border px-2.5 py-2 text-[13px] text-foreground transition-colors hover:bg-muted"
                  >
                    <span className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={values.moduleIds.includes(moduleId)}
                        onChange={() => toggleModule(moduleId)}
                        className="size-3.5 accent-[var(--primary)]"
                      />
                      {modules[moduleId].name}
                    </span>
                    <span className="text-[11px] text-muted-foreground">
                      {`${plan.extraModulePrice} € /mois`}
                    </span>
                  </label>
                ))}
              </div>
              <p className="text-[11px] text-muted-foreground">
                {plan.includedModules > 0
                  ? `${plan.includedModules} module compris dans la formule ${plan.name}.`
                  : 'Aucun module compris dans cette formule.'}
              </p>
            </div>

            <Field
              label="Plaques et porte-clés NFC"
              htmlFor="quote-nfc"
              hint={`${plan.includedNfc} compris, puis ${plan.extraNfcPrice} € la pièce.`}
            >
              <input
                id="quote-nfc"
                type="number"
                min={0}
                value={values.nfcQuantity}
                onChange={(event) =>
                  setField('nfcQuantity', Number(event.target.value))
                }
                className={controlClass}
              />
            </Field>

            <Field label="Engagement" htmlFor="quote-engagement">
              <select
                id="quote-engagement"
                value={values.engagementMonths}
                onChange={(event) =>
                  setEngagement(Number(event.target.value) as EngagementMonths)
                }
                className={controlClass}
              >
                {engagements.map((option) => (
                  <option key={option.months} value={option.months}>
                    {option.label}
                  </option>
                ))}
              </select>
            </Field>

            <div className="grid grid-cols-2 gap-3">
              <Field label="Mois offerts" htmlFor="quote-free">
                <input
                  id="quote-free"
                  type="number"
                  min={0}
                  max={values.engagementMonths}
                  value={values.freeMonths}
                  onChange={(event) =>
                    setField('freeMonths', Number(event.target.value))
                  }
                  className={controlClass}
                />
              </Field>

              <Field label="Remise (%)" htmlFor="quote-discount">
                <input
                  id="quote-discount"
                  type="number"
                  min={0}
                  max={100}
                  value={values.discountPercent}
                  onChange={(event) =>
                    setField('discountPercent', Number(event.target.value))
                  }
                  className={controlClass}
                />
              </Field>
            </div>

            <Field label="Statut" htmlFor="quote-status">
              <select
                id="quote-status"
                value={values.status}
                onChange={(event) =>
                  setField('status', event.target.value as QuoteStatus)
                }
                className={controlClass}
              >
                {(Object.keys(quoteStatusLabels) as QuoteStatus[]).map(
                  (status) => (
                    <option key={status} value={status}>
                      {quoteStatusLabels[status]}
                    </option>
                  ),
                )}
              </select>
            </Field>

            <QuoteSummary
              planId={values.planId}
              totals={totals}
              engagementMonths={values.engagementMonths}
              freeMonths={values.freeMonths}
              discountPercent={values.discountPercent}
            />

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
              disabled={isSaving}
              className="h-9 rounded-lg bg-primary px-3.5 text-[13px] font-medium text-primary-foreground transition-opacity disabled:opacity-40"
            >
              {isSaving ? 'Enregistrement…' : quote ? 'Enregistrer' : 'Créer le devis'}
            </button>
          </footer>
        </form>
      </aside>
    </div>
  )
}
