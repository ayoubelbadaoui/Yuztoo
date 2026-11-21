import { Badge } from '@/components/ui/Badge'
import type { BadgeTone } from '@/components/ui/Badge'
import type { ContractStatus } from '@/features/contracts/domain/contract'
import { contractStatusLabels } from '@/features/contracts/domain/contract'

const tones: Record<ContractStatus, BadgeTone> = {
  draft: 'neutral',
  sent: 'warning',
  signed: 'success',
  declined: 'danger',
  expired: 'danger',
}

export function ContractStatusBadge({ status }: { status: ContractStatus }) {
  return <Badge tone={tones[status]}>{contractStatusLabels[status]}</Badge>
}
