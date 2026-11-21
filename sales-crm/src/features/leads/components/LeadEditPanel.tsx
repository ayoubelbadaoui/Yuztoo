import { AtSign, X } from 'lucide-react'
import { useEffect } from 'react'

import { Field, controlClass } from '@/components/ui/Field'
import type { Lead, LeadStage, LeadType } from '@/features/leads/domain/lead'
import {
  instagramUrl,
  leadOwners,
  leadStageLabels,
  leadStageOrder,
  leadTypeLabels,
  priorityLabels,
} from '@/features/leads/domain/lead'
import { useLeadForm } from '@/features/leads/hooks/useLeadForm'

const allStages: LeadStage[] = [...leadStageOrder, 'lost']

type Props = {
  lead: Lead
  onClose: () => void
  onSaved: (updated: Lead) => void
}

export function LeadEditPanel({ lead, onClose, onSaved }: Props) {
  const { values, setField, isDirty, isSaving, error, submit } = useLeadForm(
    lead,
    onSaved,
  )

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

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
        aria-label={`Modifier ${lead.name}`}
        className="pop-in relative flex h-full w-full max-w-sm flex-col border-l border-border bg-card shadow-2xl"
      >
        <header className="flex shrink-0 items-start justify-between gap-3 border-b border-border p-4">
          <div className="min-w-0">
            <h2 className="truncate text-[15px] font-semibold text-card-foreground">
              Modifier le lead
            </h2>
            <p className="truncate text-[12px] text-muted-foreground">
              {lead.id}
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
          <div className="scrollbar-none flex min-h-0 flex-1 flex-col gap-3.5 overflow-y-auto p-4">
            {(lead.instagram ||
              lead.email ||
              lead.phone ||
              lead.trade ||
              lead.priority) && (
              <div className="rounded-lg border border-border bg-muted/40 p-3 text-[12px] text-muted-foreground">
                {lead.trade && (
                  <p>
                    Métier ·{' '}
                    <span className="text-foreground">{lead.trade}</span>
                  </p>
                )}
                {lead.priority && (
                  <p className="mt-1">
                    {priorityLabels[lead.priority]}
                    {lead.yuztooStorefront
                      ? ` · Vitrine${lead.storefrontStatus === 'online' ? ' en ligne' : lead.storefrontStatus === 'offline' ? ' hors ligne' : ''}`
                      : ''}
                  </p>
                )}
                {lead.email && (
                  <p className="mt-1 truncate">
                    <a
                      href={`mailto:${lead.email}`}
                      className="text-foreground underline-offset-2 hover:underline"
                    >
                      {lead.email}
                    </a>
                  </p>
                )}
                {lead.phone && (
                  <p className="mt-1">
                    <a
                      href={`tel:${lead.phone}`}
                      className="text-foreground underline-offset-2 hover:underline"
                    >
                      {lead.phone}
                    </a>
                  </p>
                )}
                {lead.instagram && (
                  <a
                    href={instagramUrl(lead.instagram)}
                    target="_blank"
                    rel="noreferrer"
                    className="mt-2 inline-flex items-center gap-1.5 text-foreground underline-offset-2 hover:underline"
                  >
                    <AtSign className="size-3.5" strokeWidth={1.5} />
                    @{lead.instagram}
                  </a>
                )}
              </div>
            )}

            <Field label="Nom" htmlFor="lead-name">
              <input
                id="lead-name"
                value={values.name}
                onChange={(event) => setField('name', event.target.value)}
                className={controlClass}
                autoFocus
              />
            </Field>

            <Field label="Type" htmlFor="lead-type">
              <select
                id="lead-type"
                value={values.type}
                onChange={(event) =>
                  setField('type', event.target.value as LeadType)
                }
                className={controlClass}
              >
                {(Object.keys(leadTypeLabels) as LeadType[]).map((type) => (
                  <option key={type} value={type}>
                    {leadTypeLabels[type]}
                  </option>
                ))}
              </select>
            </Field>

            <Field
              label="Entreprise"
              htmlFor="lead-company"
              hint="Laissez vide pour un particulier."
            >
              <input
                id="lead-company"
                value={values.company}
                onChange={(event) => setField('company', event.target.value)}
                className={controlClass}
              />
            </Field>

            <Field label="Ville" htmlFor="lead-city">
              <input
                id="lead-city"
                value={values.city}
                onChange={(event) => setField('city', event.target.value)}
                className={controlClass}
              />
            </Field>

            <Field label="Étape" htmlFor="lead-stage">
              <select
                id="lead-stage"
                value={values.stage}
                onChange={(event) =>
                  setField('stage', event.target.value as LeadStage)
                }
                className={controlClass}
              >
                {allStages.map((stage) => (
                  <option key={stage} value={stage}>
                    {leadStageLabels[stage]}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Montant (€)" htmlFor="lead-amount">
              <input
                id="lead-amount"
                inputMode="numeric"
                value={values.amount}
                onChange={(event) => setField('amount', event.target.value)}
                placeholder="0"
                className={controlClass}
              />
            </Field>

            <Field label="Responsable" htmlFor="lead-owner">
              <select
                id="lead-owner"
                value={values.owner}
                onChange={(event) => setField('owner', event.target.value)}
                className={controlClass}
              >
                {leadOwners.map((owner) => (
                  <option key={owner} value={owner}>
                    {owner}
                  </option>
                ))}
              </select>
            </Field>

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
              disabled={!isDirty || isSaving}
              className="h-9 rounded-lg bg-primary px-3.5 text-[13px] font-medium text-primary-foreground transition-opacity disabled:opacity-40"
            >
              {isSaving ? 'Enregistrement…' : 'Enregistrer'}
            </button>
          </footer>
        </form>
      </aside>
    </div>
  )
}
