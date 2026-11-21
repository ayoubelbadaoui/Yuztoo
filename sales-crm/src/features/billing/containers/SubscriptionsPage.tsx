import { Plus } from 'lucide-react'
import { useState } from 'react'

import type {
  Subscription,
  SubscriptionStatus,
} from '@/features/billing/domain/subscription'
import { subscriptionStatusLabels } from '@/features/billing/domain/subscription'
import { BillingKpis } from '@/features/billing/components/BillingKpis'
import { StartSubscriptionPanel } from '@/features/billing/components/StartSubscriptionPanel'
import { SubscriptionEditPanel } from '@/features/billing/components/SubscriptionEditPanel'
import { SubscriptionsTable } from '@/features/billing/components/SubscriptionsTable'
import {
  useBillingSummary,
  useSubscriptions,
} from '@/features/billing/hooks/useBilling'

type Filter = SubscriptionStatus | 'all'

const filters: Filter[] = ['all', 'active', 'trial', 'suspended', 'cancelled']

const filterLabels: Record<Filter, string> = {
  all: 'Tous',
  ...subscriptionStatusLabels,
}

export function SubscriptionsPage() {
  const [filter, setFilter] = useState<Filter>('all')
  const {
    data: subscriptions,
    error,
    isLoading,
    reload,
  } = useSubscriptions(filter)
  const { data: summary, reload: reloadSummary } = useBillingSummary()
  const [editing, setEditing] = useState<Subscription | null>(null)
  const [isStarting, setIsStarting] = useState(false)

  const refresh = async () => {
    setEditing(null)
    setIsStarting(false)
    await Promise.all([reload(), reloadSummary()])
  }

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold tracking-tight text-foreground">
            Abonnements
          </h1>
          <p className="text-[13px] text-muted-foreground">
            Contrats en cours, prélèvements et engagements.
          </p>
        </div>

        <button
          type="button"
          onClick={() => setIsStarting(true)}
          className="flex h-9 items-center gap-1.5 rounded-lg bg-primary px-3 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90"
        >
          <Plus className="size-4" />
          Démarrer un abonnement
        </button>
      </header>

      {summary && <BillingKpis summary={summary} />}

      <div className="flex flex-wrap gap-1 rounded-lg border border-border p-0.5">
        {filters.map((option) => (
          <button
            key={option}
            type="button"
            onClick={() => setFilter(option)}
            className={`h-8 rounded-[6px] px-3 text-[13px] transition-colors ${
              filter === option
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {filterLabels[option]}
          </button>
        ))}
      </div>

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
          Impossible de charger les abonnements.
        </div>
      )}

      {isLoading && !error && (
        <div className="h-64 animate-pulse rounded-xl bg-muted" />
      )}

      {!isLoading && !error && subscriptions && (
        <SubscriptionsTable
          subscriptions={subscriptions}
          onSelect={setEditing}
        />
      )}

      {editing && (
        <SubscriptionEditPanel
          subscription={editing}
          onClose={() => setEditing(null)}
          onSaved={() => void refresh()}
        />
      )}

      {isStarting && (
        <StartSubscriptionPanel
          onClose={() => setIsStarting(false)}
          onStarted={() => void refresh()}
        />
      )}
    </div>
  )
}
