import { AlertTriangle } from 'lucide-react'
import { useState } from 'react'

import type { Invoice } from '@/features/billing/domain/invoice'
import { DunningTable } from '@/features/billing/components/DunningTable'
import { useOutstandingInvoices } from '@/features/billing/hooks/useBilling'
import {
  markInvoicePaid,
  retryPayment,
} from '@/features/billing/services/billingService'
import { formatEuro } from '@/lib/money'

export function DunningPage() {
  const { data: invoices, error, isLoading, reload } = useOutstandingInvoices()
  const [busyId, setBusyId] = useState<string | null>(null)

  const run = async (invoice: Invoice, action: 'paid' | 'retry') => {
    setBusyId(invoice.id)
    await (action === 'paid'
      ? markInvoicePaid(invoice.id)
      : retryPayment(invoice.id))
    setBusyId(null)
    await reload()
  }

  const outstanding = (invoices ?? []).reduce(
    (sum, invoice) => sum + invoice.amount,
    0,
  )

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Recouvrement
        </h1>
        <p className="text-[13px] text-muted-foreground">
          Échéances rejetées ou en retard, par ancienneté.
        </p>
      </header>

      {invoices && invoices.length > 0 && (
        <div className="flex items-start gap-2.5 rounded-xl border border-warning/40 bg-warning/10 px-4 py-3">
          <AlertTriangle className="mt-px size-4 shrink-0 text-warning" />
          <p className="text-[13px] text-foreground">
            {`${formatEuro(outstanding)} à recouvrer sur ${invoices.length} échéance${invoices.length > 1 ? 's' : ''}.`}
            <span className="text-muted-foreground">
              {' '}
              L’étape proposée reste une recommandation : c’est le commercial qui
              décide.
            </span>
          </p>
        </div>
      )}

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
          Impossible de charger le recouvrement.
        </div>
      )}

      {isLoading && !error && (
        <div className="h-64 animate-pulse rounded-xl bg-muted" />
      )}

      {!isLoading && !error && invoices && (
        <DunningTable
          invoices={invoices}
          busyId={busyId}
          onMarkPaid={(invoice) => void run(invoice, 'paid')}
          onRetry={(invoice) => void run(invoice, 'retry')}
        />
      )}
    </div>
  )
}
