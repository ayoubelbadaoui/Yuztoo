import type { Invoice } from '@/features/billing/domain/invoice'
import { InvoiceStatusBadge } from '@/features/billing/components/InvoiceStatusBadge'
import { formatEuro } from '@/lib/money'

type Props = {
  label: string
  invoices: Invoice[]
}

function dayLabel(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    weekday: 'short',
    day: '2-digit',
  }).format(new Date(iso))
}

export function PaymentScheduleMonth({ label, invoices }: Props) {
  const total = invoices.reduce((sum, invoice) => sum + invoice.amount, 0)

  return (
    <section className="overflow-hidden rounded-xl border border-border bg-card">
      <header className="flex items-baseline justify-between gap-3 border-b border-border bg-muted/40 px-4 py-2.5">
        <h2 className="text-[13px] font-semibold text-card-foreground">
          {label}
        </h2>
        <p className="text-[12px] text-muted-foreground">
          {`${invoices.length} échéance${invoices.length > 1 ? 's' : ''} · `}
          <span className="font-medium tabular-nums text-card-foreground">
            {formatEuro(total)}
          </span>
        </p>
      </header>

      <ol className="flex flex-col">
        {invoices.map((invoice) => (
          <li
            key={invoice.id}
            className="flex items-center gap-3 border-b border-border px-4 py-2.5 last:border-0"
          >
            <span className="w-16 shrink-0 text-[12px] tabular-nums text-muted-foreground">
              {dayLabel(invoice.dueDate)}
            </span>

            <span className="min-w-0 flex-1">
              <span className="block truncate text-[13px] text-card-foreground">
                {invoice.leadName}
              </span>
              <span className="block truncate text-[11px] text-muted-foreground">
                {invoice.company}
              </span>
            </span>

            <InvoiceStatusBadge status={invoice.status} />

            <span className="w-20 shrink-0 text-right text-[13px] font-medium tabular-nums text-card-foreground">
              {formatEuro(invoice.amount)}
            </span>
          </li>
        ))}
      </ol>
    </section>
  )
}
