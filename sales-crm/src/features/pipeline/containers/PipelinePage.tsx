import { useCallback, useState } from 'react'

import { LeadEditPanel } from '@/features/leads/components/LeadEditPanel'
import type { Lead } from '@/features/leads/domain/lead'
import { formatAmount, leadStageOrder } from '@/features/leads/domain/lead'
import { PipelineCard } from '@/features/pipeline/components/PipelineCard'
import { PipelineColumn } from '@/features/pipeline/components/PipelineColumn'
import type { DropTarget } from '@/features/pipeline/hooks/useKanbanDrag'
import { useKanbanDrag } from '@/features/pipeline/hooks/useKanbanDrag'
import { usePipelineBoard } from '@/features/pipeline/hooks/usePipelineBoard'

export function PipelinePage() {
  const { board, error, isLoading, moveLead, reload } = usePipelineBoard()
  const [editing, setEditing] = useState<Lead | null>(null)

  const onDrop = useCallback(
    (lead: Lead, target: DropTarget) => {
      void moveLead(lead, target.stage, target.index)
    },
    [moveLead],
  )

  const { drag, startDrag, registerColumn, wasDragged } = useKanbanDrag({
    onDrop,
  })

  const onCardClick = useCallback(
    (lead: Lead) => {
      if (wasDragged()) return
      setEditing(lead)
    },
    [wasDragged],
  )

  if (isLoading) {
    return (
      <div className="flex gap-4">
        {leadStageOrder.map((stage) => (
          <div key={stage} className="h-80 w-72 animate-pulse rounded-xl bg-muted" />
        ))}
      </div>
    )
  }

  if (error || !board) {
    return (
      <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
        Impossible de charger le pipeline.
      </div>
    )
  }

  const openAmount = leadStageOrder
    .filter((stage) => stage !== 'won')
    .reduce(
      (total, stage) =>
        total + board[stage].reduce((sum, lead) => sum + lead.amount, 0),
      0,
    )

  return (
    <div className="flex h-full min-h-0 flex-col gap-4">
      <header className="flex shrink-0 flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Pipeline
        </h1>
        <p className="text-[13px] text-muted-foreground">
          {formatAmount(openAmount)} en cours · glissez une carte pour changer
          d’étape.
        </p>
      </header>

      <div className="scrollbar-none flex min-h-0 flex-1 gap-4 overflow-x-auto overflow-y-hidden pb-1">
        {leadStageOrder.map((stage) => (
          <PipelineColumn
            key={stage}
            stage={stage}
            leads={board[stage]}
            drag={drag}
            onCardPointerDown={startDrag}
            onCardClick={onCardClick}
            registerColumn={registerColumn}
          />
        ))}
      </div>

      {drag && (
        <div
          className="pointer-events-none fixed z-50"
          style={{
            left: drag.pointerX - drag.offsetX,
            top: drag.pointerY - drag.offsetY,
            width: drag.width,
          }}
        >
          <PipelineCard lead={drag.lead} isOverlay />
        </div>
      )}

      {editing && (
        <LeadEditPanel
          lead={editing}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null)
            void reload()
          }}
        />
      )}
    </div>
  )
}
