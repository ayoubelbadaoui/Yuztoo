import { Badge } from '@/components/ui/Badge'
import { LeadStageBadge } from '@/features/leads/components/LeadStageBadge'
import type { Lead } from '@/features/leads/domain/lead'
import {
  formatAmount,
  formatRelativeDate,
  leadTypeLabels,
} from '@/features/leads/domain/lead'

type Props = {
  leads: Lead[]
}

export function RecentLeadsCard({ leads }: Props) {
  return (
    <section className="overflow-hidden rounded-xl border border-border bg-card">
      <header className="flex items-center justify-between border-b border-border px-4 py-3">
        <h2 className="text-[13px] font-semibold text-card-foreground">
          Derniers leads
        </h2>
        <span className="text-[12px] text-muted-foreground">
          {leads.length} affichés
        </span>
      </header>

      <ul className="divide-y divide-border">
        {leads.map((lead) => (
          <li
            key={lead.id}
            className="flex items-center gap-4 px-4 py-3 transition-colors hover:bg-accent"
          >
            <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-muted text-[11px] font-semibold text-muted-foreground">
              {lead.name
                .split(' ')
                .map((part) => part[0])
                .join('')}
            </span>

            <div className="min-w-0 flex-1">
              <p className="truncate text-[13px] font-medium text-card-foreground">
                {lead.name}
              </p>
              <p className="truncate text-[12px] text-muted-foreground">
                {lead.company} · {lead.city}
              </p>
            </div>

            <Badge tone={lead.type === 'merchant' ? 'primary' : 'neutral'}>
              {leadTypeLabels[lead.type]}
            </Badge>
            <LeadStageBadge stage={lead.stage} />

            <span className="hidden w-24 text-right text-[13px] tabular-nums text-card-foreground sm:block">
              {lead.amount > 0 ? formatAmount(lead.amount) : '—'}
            </span>
            <span className="hidden w-28 text-right text-[12px] text-muted-foreground lg:block">
              {formatRelativeDate(lead.updatedAt)}
            </span>
          </li>
        ))}
      </ul>
    </section>
  )
}
