import { Badge } from '@/components/ui/Badge'
import type { Lead } from '@/features/leads/domain/lead'
import {
  formatAmount,
  formatRelativeDate,
  leadStageLabels,
  leadTypeLabels,
} from '@/features/leads/domain/lead'

type Props = {
  lead: Lead
  isDragging?: boolean
  isOverlay?: boolean
  onPointerDown?: (event: React.PointerEvent) => void
  onClick?: () => void
}

export function PipelineCard({
  lead,
  isDragging = false,
  isOverlay = false,
  onPointerDown,
  onClick,
}: Props) {
  return (
    <article
      data-lead-id={isOverlay ? undefined : lead.id}
      role={isOverlay ? undefined : 'button'}
      tabIndex={isOverlay ? undefined : 0}
      aria-label={`${lead.name} — ${leadStageLabels[lead.stage]}`}
      onPointerDown={onPointerDown}
      onClick={onClick}
      onKeyDown={(event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault()
          onClick?.()
        }
      }}
      className={`select-none rounded-lg border border-border bg-card p-3 ${
        isOverlay
          ? 'rotate-1 cursor-grabbing shadow-2xl'
          : 'cursor-grab transition-colors hover:border-primary/40'
      } ${isDragging ? 'opacity-40' : ''}`}
    >
      <div className="flex items-start justify-between gap-2">
        <p className="text-[13px] font-medium leading-tight text-card-foreground">
          {lead.name}
        </p>
        <Badge tone={lead.type === 'merchant' ? 'primary' : 'neutral'}>
          {leadTypeLabels[lead.type]}
        </Badge>
      </div>

      <p className="mt-1 truncate text-[12px] text-muted-foreground">
        {lead.trade
          ? `${lead.company} · ${lead.trade}`
          : lead.instagram
            ? `${lead.company} · @${lead.instagram}`
            : lead.company}
      </p>

      <div className="mt-3 flex items-center justify-between">
        <span className="text-[13px] font-medium tabular-nums text-card-foreground">
          {lead.amount > 0 ? formatAmount(lead.amount) : '—'}
        </span>
        <span className="text-[11px] text-muted-foreground">
          {formatRelativeDate(lead.updatedAt)}
        </span>
      </div>

      <div className="mt-2 flex items-center gap-1.5 border-t border-border pt-2">
        <span className="flex size-5 items-center justify-center rounded-full bg-muted text-[9px] font-semibold text-muted-foreground">
          {lead.owner === 'Non assigné'
            ? '?'
            : lead.owner
                .split(' ')
                .map((part) => part[0])
                .join('')}
        </span>
        <span className="truncate text-[11px] text-muted-foreground">
          {lead.owner}
        </span>
      </div>
    </article>
  )
}
