import { Badge, type BadgeTone } from '@/components/ui/Badge'
import type { LeadStage } from '@/features/leads/domain/lead'
import { leadStageLabels } from '@/features/leads/domain/lead'

const stageTones: Record<LeadStage, BadgeTone> = {
  new: 'neutral',
  contacted: 'neutral',
  qualified: 'primary',
  negotiation: 'warning',
  won: 'success',
  lost: 'danger',
}

export function LeadStageBadge({ stage }: { stage: LeadStage }) {
  return <Badge tone={stageTones[stage]}>{leadStageLabels[stage]}</Badge>
}
