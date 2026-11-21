import { Badge } from '@/components/ui/Badge'
import type { BadgeTone } from '@/components/ui/Badge'
import type { ClientStatus, MerchantStatus } from '@/features/cms-app/domain/cms'
import {
  clientStatusLabels,
  merchantStatusLabels,
} from '@/features/cms-app/domain/cms'

const merchantTones: Record<MerchantStatus, BadgeTone> = {
  draft: 'neutral',
  published: 'success',
  unpublished: 'warning',
  deleted: 'danger',
}

const clientTones: Record<ClientStatus, BadgeTone> = {
  active: 'success',
  blocked: 'warning',
  deleted: 'danger',
}

export function MerchantStatusBadge({ status }: { status: MerchantStatus }) {
  return (
    <Badge tone={merchantTones[status]}>{merchantStatusLabels[status]}</Badge>
  )
}

export function ClientStatusBadge({ status }: { status: ClientStatus }) {
  return <Badge tone={clientTones[status]}>{clientStatusLabels[status]}</Badge>
}
