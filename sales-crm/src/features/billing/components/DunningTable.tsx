import { Badge } from '@/components/ui/Badge'
import { dunningStepFor } from '@/features/billing/domain/dunning'
import type { Invoice } from '@/features/billing/domain/invoice'
import { daysLate } from '@/features/billing/domain/invoice'
import { formatDay } from '@/features/billing/domain/subscription'
import { InvoiceStatusBadge } from '@/features/billing/components/InvoiceStatusBadge'
import { formatEuro } from '@/lib/money'

type Props = {
  invoices: Invoice[]
  busyId: string | null
  onMarkPaid: (invoice: Invoice) => void
  onRetry: (invoice: Invoice) => void
}

export function DunningTable({
  invoices,
  busyId,
  onMarkPaid,
  onRetry,
}: Props) {
  if (invoices.length === 0) {
    return (
      <div className="rounded-xl border border-success/30 bg-success/10 p-10 text-center">
        <p className="text-[13px] text-success">
          Aucun impayé. Tout est encaissé.
        </p>
      </div>
    )
  }

  const outstanding = invoices.reduce((sum, invoice) => sum + invoice.amount, 0)

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-card">
      <table className="w-full min-w-[860px] border-collapse">
        <thead>
          <tr className="border-b border-border text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
            <th className="px-4 py-2.5 text-left">Client</th>
            <th className="w-28 px-4 py-2.5 text-left">Échéance</th>
            <th className="w-24 px-4 py-2.5 text-right">Montant</th>
            <th className="w-24 px-4 py-2.5 text-right">Retard</th>
            <th className="w-28 px-4 py-2.5 text-left">Statut</th>
            <th className="px-4 py-2.5 text-left">Action recommandée</th>
            <th className="w-44 px-4 py-2.5 text-right">Traiter</th>
          </tr>
        </thead>

        <tbody>
          {invoices.map((invoice) => {
            const step = dunningStepFor(invoice)
            const late = daysLate(invoice)
            const isBusy = busyId === invoice.id

            return (
              <tr
                key={invoice.id}
                className="border-b border-border transition-colors last:border-0 hover:bg-accent"
              >
                <td className="px-4 py-2.5">
                  <p className="text-[13px] font-medium text-card-foreground">
                    {invoice.leadName}
                  </p>
                  <p className="truncate text-[12px] text-muted-foreground">
                    {invoice.id} · {invoice.periodLabel}
                  </p>
                </td>

                <td className="px-4 py-2.5 text-[12px] text-muted-foreground">
                  {formatDay(invoice.dueDate)}
                </td>

                <td className="px-4 py-2.5 text-right text-[13px] font-medium tabular-nums text-card-foreground">
                  {formatEuro(invoice.amount)}
                </td>

                <td className="px-4 py-2.5 text-right text-[13px] tabular-nums text-card-foreground">
                  {`${late} j`}
                </td>

                <td className="px-4 py-2.5">
                  <InvoiceStatusBadge status={invoice.status} />
                </td>

                <td className="px-4 py-2.5">
                  <div className="flex items-center gap-2">
                    <Badge tone={step.tone}>{step.label}</Badge>
                    <span className="truncate text-[12px] text-muted-foreground">
                      {step.action}
                    </span>
                  </div>
                  {invoice.attempts > 1 && (
                    <p className="mt-0.5 text-[11px] text-muted-foreground">
                      {`${invoice.attempts} présentations bancaires`}
                    </p>
                  )}
                </td>

                <td className="px-4 py-2.5">
                  <div className="flex items-center justify-end gap-1.5">
                    <button
                      type="button"
                      disabled={isBusy}
                      onClick={() => onRetry(invoice)}
                      className="h-7 rounded-md border border-border px-2 text-[12px] text-foreground transition-colors hover:bg-muted disabled:opacity-40"
                    >
                      Représenter
                    </button>
                    <button
                      type="button"
                      disabled={isBusy}
                      onClick={() => onMarkPaid(invoice)}
                      className="h-7 rounded-md bg-primary px-2 text-[12px] font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-40"
                    >
                      Marquer payée
                    </button>
                  </div>
                </td>
              </tr>
            )
          })}
        </tbody>

        <tfoot>
          <tr className="bg-muted/40">
            <td
              colSpan={2}
              className="px-4 py-2.5 text-[12px] font-medium text-card-foreground"
            >
              Encours total à recouvrer
            </td>
            <td className="px-4 py-2.5 text-right text-[13px] font-semibold tabular-nums text-card-foreground">
              {formatEuro(outstanding)}
            </td>
            <td colSpan={4} />
          </tr>
        </tfoot>
      </table>
    </div>
  )
}
