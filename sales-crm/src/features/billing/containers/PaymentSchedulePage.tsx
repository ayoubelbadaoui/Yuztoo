import type { Invoice } from '@/features/billing/domain/invoice'
import { formatMonth } from '@/features/billing/domain/subscription'
import { PaymentScheduleMonth } from '@/features/billing/components/PaymentScheduleMonth'
import { usePaymentSchedule } from '@/features/billing/hooks/useBilling'
import { formatEuro } from '@/lib/money'

function groupByMonth(invoices: Invoice[]): [string, Invoice[]][] {
  const groups = new Map<string, Invoice[]>()
  for (const invoice of invoices) {
    const key = formatMonth(invoice.dueDate)
    groups.set(key, [...(groups.get(key) ?? []), invoice])
  }
  return [...groups.entries()]
}

export function PaymentSchedulePage() {
  const { data: invoices, error, isLoading } = usePaymentSchedule(3)

  const expected = (invoices ?? []).reduce(
    (sum, invoice) => sum + invoice.amount,
    0,
  )

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Échéancier
        </h1>
        <p className="text-[13px] text-muted-foreground">
          {`Prélèvements des trois prochains mois · ${formatEuro(expected)} attendus.`}
        </p>
      </header>

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
          Impossible de charger l’échéancier.
        </div>
      )}

      {isLoading && !error && (
        <div className="flex flex-col gap-3">
          {[0, 1, 2].map((index) => (
            <div key={index} className="h-40 animate-pulse rounded-xl bg-muted" />
          ))}
        </div>
      )}

      {!isLoading && !error && invoices && (
        <div className="flex flex-col gap-3">
          {groupByMonth(invoices).map(([label, monthInvoices]) => (
            <PaymentScheduleMonth
              key={label}
              label={label}
              invoices={monthInvoices}
            />
          ))}
        </div>
      )}
    </div>
  )
}
