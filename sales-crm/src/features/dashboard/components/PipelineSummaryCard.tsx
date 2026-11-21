import { formatAmount, leadStageLabels } from '@/features/leads/domain/lead'
import type { PipelineSummary } from '@/features/leads/services/leadService'

type Props = {
  summary: PipelineSummary[]
}

export function PipelineSummaryCard({ summary }: Props) {
  const maxCount = Math.max(...summary.map((row) => row.count), 1)

  return (
    <section className="rounded-xl border border-border bg-card p-4">
      <h2 className="text-[13px] font-semibold text-card-foreground">
        Répartition du pipeline
      </h2>

      <div className="mt-4 flex flex-col gap-3">
        {summary.map((row) => (
          <div key={row.stage} className="flex items-center gap-3">
            <span className="w-24 shrink-0 text-[12px] text-muted-foreground">
              {leadStageLabels[row.stage]}
            </span>
            <div className="h-2 flex-1 overflow-hidden rounded-full bg-muted">
              <div
                className="h-full rounded-full bg-primary"
                style={{ width: `${(row.count / maxCount) * 100}%` }}
              />
            </div>
            <span className="w-6 text-right text-[12px] tabular-nums text-card-foreground">
              {row.count}
            </span>
            <span className="hidden w-24 text-right text-[12px] tabular-nums text-muted-foreground sm:block">
              {row.amount > 0 ? formatAmount(row.amount) : '—'}
            </span>
          </div>
        ))}
      </div>
    </section>
  )
}
