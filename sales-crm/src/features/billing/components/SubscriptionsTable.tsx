import { Badge } from '@/components/ui/Badge'
import type { BadgeTone } from '@/components/ui/Badge'
import type {
  Subscription,
  SubscriptionStatus,
} from '@/features/billing/domain/subscription'
import {
  engagementEnd,
  formatDay,
  paymentMethodLabels,
  subscriptionStatusLabels,
} from '@/features/billing/domain/subscription'
import { formatEuro } from '@/lib/money'

const tones: Record<SubscriptionStatus, BadgeTone> = {
  active: 'success',
  trial: 'primary',
  suspended: 'warning',
  cancelled: 'neutral',
}

/** Prochaine présentation du prélèvement, au jour de facturation convenu. */
function nextCharge(subscription: Subscription): Date {
  const next = new Date()
  next.setHours(0, 0, 0, 0)
  if (next.getDate() >= subscription.billingDay) {
    next.setMonth(next.getMonth() + 1)
  }
  next.setDate(subscription.billingDay)
  return next
}

type Props = {
  subscriptions: Subscription[]
  onSelect: (subscription: Subscription) => void
}

export function SubscriptionsTable({ subscriptions, onSelect }: Props) {
  if (subscriptions.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-card p-10 text-center">
        <p className="text-[13px] text-muted-foreground">
          Aucun abonnement pour ce filtre.
        </p>
      </div>
    )
  }

  const mrr = subscriptions
    .filter((item) => item.status === 'active' || item.status === 'trial')
    .reduce((sum, item) => sum + item.monthlyAmount, 0)

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-card">
      <table className="w-full min-w-[820px] border-collapse">
        <thead>
          <tr className="border-b border-border text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
            <th className="px-4 py-2.5 text-left">Client</th>
            <th className="w-28 px-4 py-2.5 text-left">Formule</th>
            <th className="w-28 px-4 py-2.5 text-right">Mensuel</th>
            <th className="w-36 px-4 py-2.5 text-left">Prochain prélèvement</th>
            <th className="hidden w-40 px-4 py-2.5 text-left lg:table-cell">
              Moyen de paiement
            </th>
            <th className="hidden w-32 px-4 py-2.5 text-left xl:table-cell">
              Fin d’engagement
            </th>
            <th className="w-32 px-4 py-2.5 text-left">Statut</th>
          </tr>
        </thead>

        <tbody>
          {subscriptions.map((subscription) => (
            <tr
              key={subscription.id}
              tabIndex={0}
              onClick={() => onSelect(subscription)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') onSelect(subscription)
              }}
              className="cursor-pointer border-b border-border transition-colors last:border-0 hover:bg-accent focus:bg-accent focus:outline-none"
            >
              <td className="px-4 py-2.5">
                <p className="text-[13px] font-medium text-card-foreground">
                  {subscription.leadName}
                </p>
                <p className="truncate text-[12px] text-muted-foreground">
                  {subscription.id} · {subscription.company}
                </p>
              </td>

              <td className="px-4 py-2.5 text-[13px] text-card-foreground">
                {subscription.planName}
              </td>

              <td className="px-4 py-2.5 text-right text-[13px] font-medium tabular-nums text-card-foreground">
                {formatEuro(subscription.monthlyAmount)}
              </td>

              <td className="px-4 py-2.5 text-[12px] text-muted-foreground">
                {subscription.status === 'cancelled'
                  ? '—'
                  : formatDay(nextCharge(subscription).toISOString())}
              </td>

              <td className="hidden px-4 py-2.5 text-[12px] text-muted-foreground lg:table-cell">
                {paymentMethodLabels[subscription.paymentMethod]}
              </td>

              <td className="hidden px-4 py-2.5 text-[12px] text-muted-foreground xl:table-cell">
                {formatDay(engagementEnd(subscription).toISOString())}
              </td>

              <td className="px-4 py-2.5">
                <Badge tone={tones[subscription.status]}>
                  {subscriptionStatusLabels[subscription.status]}
                </Badge>
              </td>
            </tr>
          ))}
        </tbody>

        <tfoot>
          <tr className="bg-muted/40">
            <td
              colSpan={2}
              className="px-4 py-2.5 text-[12px] font-medium text-card-foreground"
            >
              Revenu récurrent de la sélection
            </td>
            <td className="px-4 py-2.5 text-right text-[13px] font-semibold tabular-nums text-card-foreground">
              {formatEuro(mrr)}
            </td>
            <td colSpan={4} />
          </tr>
        </tfoot>
      </table>
    </div>
  )
}
