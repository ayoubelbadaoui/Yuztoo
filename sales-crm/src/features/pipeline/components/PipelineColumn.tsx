import { Fragment } from 'react'

import type { Lead, LeadStage } from '@/features/leads/domain/lead'
import { formatAmount, leadStageLabels } from '@/features/leads/domain/lead'
import { PipelineCard } from '@/features/pipeline/components/PipelineCard'
import type { DragState } from '@/features/pipeline/hooks/useKanbanDrag'

type Props = {
  stage: LeadStage
  leads: Lead[]
  drag: DragState | null
  onCardPointerDown: (event: React.PointerEvent, lead: Lead) => void
  onCardClick: (lead: Lead) => void
  registerColumn: (stage: LeadStage, element: HTMLElement | null) => void
}

export function PipelineColumn({
  stage,
  leads,
  drag,
  onCardPointerDown,
  onCardClick,
  registerColumn,
}: Props) {
  const total = leads.reduce((sum, lead) => sum + lead.amount, 0)
  const isTarget = drag?.target?.stage === stage
  const visible = leads.filter((lead) => lead.id !== drag?.lead.id)
  const placeholderAt = isTarget ? (drag?.target?.index ?? 0) : -1

  const placeholder = (
    <li
      aria-hidden
      className="rounded-lg border border-dashed border-primary/50 bg-primary/5"
      style={{ height: drag?.height ?? 96 }}
    />
  )

  return (
    <section className="flex h-full w-72 shrink-0 flex-col">
      <header className="flex shrink-0 items-center justify-between px-1 pb-2">
        <div className="flex items-center gap-2">
          <h2 className="text-[13px] font-semibold text-foreground">
            {leadStageLabels[stage]}
          </h2>
          <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-muted px-1.5 text-[11px] tabular-nums text-muted-foreground">
            {leads.length}
          </span>
        </div>
        <span className="text-[11px] tabular-nums text-muted-foreground">
          {total > 0 ? formatAmount(total) : '—'}
        </span>
      </header>

      <ul
        ref={(element) => registerColumn(stage, element)}
        className={`scrollbar-none flex min-h-0 flex-1 flex-col gap-2 overflow-y-auto rounded-xl border p-2 transition-colors ${
          isTarget
            ? 'border-primary/40 bg-primary/5'
            : 'border-border bg-muted/40'
        }`}
      >
        {visible.map((lead, index) => (
          <Fragment key={lead.id}>
            {placeholderAt === index && placeholder}
            <li>
              <PipelineCard
                lead={lead}
                onPointerDown={(event) => onCardPointerDown(event, lead)}
                onClick={() => onCardClick(lead)}
              />
            </li>
          </Fragment>
        ))}
        {placeholderAt >= visible.length && placeholder}

        {visible.length === 0 && placeholderAt < 0 && (
          <li className="flex flex-1 items-center justify-center py-6 text-[12px] text-muted-foreground">
            Aucun lead
          </li>
        )}
      </ul>
    </section>
  )
}
