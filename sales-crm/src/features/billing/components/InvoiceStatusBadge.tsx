import { Badge } from '@/components/ui/Badge'
import type { BadgeTone } from '@/components/ui/Badge'
import type { InvoiceStatus } from '@/features/billing/domain/invoice'
import { invoiceStatusLabels } from '@/features/billing/domain/invoice'

const tones: Record<InvoiceStatus, BadgeTone> = {
  scheduled: 'neutral',
  due: 'primary',
  paid: 'success',
  late: 'warning',
  failed: 'danger',
}

export function InvoiceStatusBadge({ status }: { status: InvoiceStatus }) {
  return <Badge tone={tones[status]}>{invoiceStatusLabels[status]}</Badge>
}
