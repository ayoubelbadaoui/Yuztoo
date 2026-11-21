import { X } from 'lucide-react'
import { useEffect } from 'react'

import { Badge } from '@/components/ui/Badge'
import { Field, controlClass } from '@/components/ui/Field'
import type {
  PaymentMethod,
  Subscription,
} from '@/features/billing/domain/subscription'
import {
  engagementEnd,
  formatDay,
  paymentMethodLabels,
  statusTransitions,
  subscriptionStatusLabels,
  transitionLabel,
} from '@/features/billing/domain/subscription'
import { useSubscriptionForm } from '@/features/billing/hooks/useSubscriptionForm'
import { leadOwners } from '@/features/leads/domain/lead'
import { formatEuro } from '@/lib/money'

type Props = {
  subscription: Subscription
  onClose: () => void
  onSaved: () => void
}

export function SubscriptionEditPanel({
  subscription,
  onClose,
  onSaved,
}: Props) {
  const { values, setField, isDirty, isSaving, error, submit, changeStatus } =
    useSubscriptionForm(subscription, onSaved)

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  const transitions = statusTransitions[subscription.status]

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
        aria-label={`Abonnement ${subscription.leadName}`}
        className="pop-in relative flex h-full w-full max-w-sm flex-col border-l border-border bg-card shadow-2xl"
      >
        <header className="flex shrink-0 items-start justify-between gap-3 border-b border-border p-4">
          <div className="min-w-0">
            <h2 className="truncate text-[15px] font-semibold text-card-foreground">
              {subscription.leadName}
            </h2>
            <p className="truncate text-[12px] text-muted-foreground">
              {`${subscription.id} · ${subscription.planName}`}
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
            <div className="flex flex-col gap-2 rounded-lg border border-border bg-muted/40 p-3">
              <div className="flex items-center justify-between gap-2">
                <span className="text-[12px] text-muted-foreground">
                  Statut
                </span>
                <Badge
                  tone={subscription.status === 'active' ? 'success' : 'neutral'}
                >
                  {subscriptionStatusLabels[subscription.status]}
                </Badge>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-[12px] text-muted-foreground">
                  Démarré le
                </span>
                <span className="text-[12px] text-card-foreground">
                  {formatDay(subscription.startDate)}
                </span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-[12px] text-muted-foreground">
                  Fin d’engagement
                </span>
                <span className="text-[12px] text-card-foreground">
                  {formatDay(engagementEnd(subscription).toISOString())}
                </span>
              </div>
            </div>

            <Field
              label="Montant mensuel (€)"
              htmlFor="sub-amount"
              hint={`Actuellement ${formatEuro(subscription.monthlyAmount)}. Modifier revient à passer un avenant.`}
            >
              <input
                id="sub-amount"
                inputMode="decimal"
                value={values.monthlyAmount}
                onChange={(event) =>
                  setField('monthlyAmount', event.target.value)
                }
                className={controlClass}
              />
            </Field>

            <div className="grid grid-cols-2 gap-3">
              <Field
                label="Jour de prélèvement"
                htmlFor="sub-day"
                hint="Entre 1 et 28."
              >
                <input
                  id="sub-day"
                  type="number"
                  min={1}
                  max={28}
                  value={values.billingDay}
                  onChange={(event) =>
                    setField('billingDay', event.target.value)
                  }
                  className={controlClass}
                />
              </Field>

              <Field label="Engagement (mois)" htmlFor="sub-engagement">
                <input
                  id="sub-engagement"
                  type="number"
                  min={1}
                  value={values.engagementMonths}
                  onChange={(event) =>
                    setField('engagementMonths', event.target.value)
                  }
                  className={controlClass}
                />
              </Field>
            </div>

            <Field label="Moyen de paiement" htmlFor="sub-method">
              <select
                id="sub-method"
                value={values.paymentMethod}
                onChange={(event) =>
                  setField('paymentMethod', event.target.value as PaymentMethod)
                }
                className={controlClass}
              >
                {(Object.keys(paymentMethodLabels) as PaymentMethod[]).map(
                  (method) => (
                    <option key={method} value={method}>
                      {paymentMethodLabels[method]}
                    </option>
                  ),
                )}
              </select>
            </Field>

            <Field label="Responsable" htmlFor="sub-owner">
              <select
                id="sub-owner"
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

            <div className="flex flex-col gap-2 border-t border-border pt-4">
              <span className="text-[12px] font-medium text-muted-foreground">
                Cycle de vie
              </span>
              {transitions.length === 0 ? (
                <p className="text-[12px] text-muted-foreground">
                  Abonnement résilié : plus aucune échéance n’est présentée.
                </p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {transitions.map((status) => (
                    <button
                      key={status}
                      type="button"
                      disabled={isSaving}
                      onClick={() => void changeStatus(status)}
                      className={`h-8 rounded-lg border px-3 text-[12px] transition-colors disabled:opacity-40 ${
                        status === 'cancelled'
                          ? 'border-destructive/40 text-destructive hover:bg-destructive/10'
                          : 'border-border text-foreground hover:bg-muted'
                      }`}
                    >
                      {transitionLabel(subscription.status, status)}
                    </button>
                  ))}
                </div>
              )}
              <p className="text-[11px] text-muted-foreground">
                Suspendre ou résilier retire les échéances encore planifiées.
                Les échéances passées restent au recouvrement.
              </p>
            </div>

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
              Fermer
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
