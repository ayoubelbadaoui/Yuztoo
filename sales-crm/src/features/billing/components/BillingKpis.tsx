import type { BillingSummary } from '@/features/billing/services/billingService'
import { formatEuro } from '@/lib/money'

type Props = {
  summary: BillingSummary
}

export function BillingKpis({ summary }: Props) {
  const cards = [
    {
      label: 'Revenu récurrent',
      value: `${formatEuro(summary.mrr)} /mois`,
      detail: `${summary.activeCount} abonnements facturés`,
    },
    {
      label: 'Encours impayé',
      value: formatEuro(summary.outstandingAmount),
      detail: `${summary.outstandingCount} échéance${summary.outstandingCount > 1 ? 's' : ''} à recouvrer`,
      alert: summary.outstandingCount > 0,
    },
    {
      label: 'Taux de recouvrement',
      value: `${summary.collectionRate} %`,
      detail: 'Échéances échues encaissées',
    },
    {
      label: 'Valeur annualisée',
      value: formatEuro(summary.mrr * 12),
      detail: 'MRR × 12',
    },
  ]

  return (
    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      {cards.map((card) => (
        <div
          key={card.label}
          className={`rounded-xl border bg-card p-3.5 ${
            card.alert ? 'border-warning/40' : 'border-border'
          }`}
        >
          <p className="text-[12px] text-muted-foreground">{card.label}</p>
          <p className="mt-1 text-[19px] font-semibold tabular-nums text-card-foreground">
            {card.value}
          </p>
          <p className="mt-0.5 text-[11px] text-muted-foreground">
            {card.detail}
          </p>
        </div>
      ))}
    </div>
  )
}
