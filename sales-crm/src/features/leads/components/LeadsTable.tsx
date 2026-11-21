import { ArrowDown, ArrowUp, AtSign } from 'lucide-react'

import { Badge } from '@/components/ui/Badge'
import { LeadStageBadge } from '@/features/leads/components/LeadStageBadge'
import type { Lead } from '@/features/leads/domain/lead'
import {
  formatAmount,
  instagramUrl,
  leadTypeLabels,
  priorityLabels,
} from '@/features/leads/domain/lead'
import type { LeadSortKey } from '@/features/leads/services/leadService'

type Column = {
  key: LeadSortKey | null
  label: string
  className?: string
}

const columns: Column[] = [
  { key: 'name', label: 'Lead' },
  { key: null, label: 'Métier', className: 'w-36 hidden xl:table-cell' },
  { key: null, label: 'Type', className: 'w-28' },
  { key: 'stage', label: 'Étape', className: 'w-32' },
  { key: null, label: 'Prio', className: 'w-24 hidden lg:table-cell' },
  { key: 'amount', label: 'Montant', className: 'w-28 text-right' },
  { key: null, label: 'IG', className: 'w-14 text-center' },
]

type Props = {
  leads: Lead[]
  sortKey: LeadSortKey
  sortAsc: boolean
  onSort: (key: LeadSortKey) => void
  onSelect: (lead: Lead) => void
}

export function LeadsTable({
  leads,
  sortKey,
  sortAsc,
  onSort,
  onSelect,
}: Props) {
  if (leads.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-card p-10 text-center">
        <p className="text-[13px] text-muted-foreground">
          Aucun lead ne correspond à cette recherche.
        </p>
      </div>
    )
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-card">
      <table className="w-full min-w-[720px] border-collapse">
        <thead>
          <tr className="border-b border-border">
            {columns.map((column) => (
              <th
                key={column.label}
                className={`px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-muted-foreground ${column.className ?? ''}`}
              >
                {column.key ? (
                  <button
                    type="button"
                    onClick={() => onSort(column.key as LeadSortKey)}
                    className="inline-flex items-center gap-1 transition-colors hover:text-foreground"
                  >
                    {column.label}
                    {sortKey === column.key &&
                      (sortAsc ? (
                        <ArrowUp className="size-3" strokeWidth={2} />
                      ) : (
                        <ArrowDown className="size-3" strokeWidth={2} />
                      ))}
                  </button>
                ) : (
                  column.label
                )}
              </th>
            ))}
          </tr>
        </thead>

        <tbody>
          {leads.map((lead) => (
            <tr
              key={lead.id}
              tabIndex={0}
              onClick={() => onSelect(lead)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') onSelect(lead)
              }}
              className="cursor-pointer border-b border-border last:border-0 transition-colors hover:bg-accent focus:bg-accent focus:outline-none"
            >
              <td className="px-4 py-2.5">
                <div className="flex items-center gap-3">
                  <span className="flex size-7 shrink-0 items-center justify-center rounded-full bg-muted text-[10px] font-semibold text-muted-foreground">
                    {lead.name
                      .split(' ')
                      .slice(0, 2)
                      .map((part) => part[0]?.toUpperCase() ?? '')
                      .join('')}
                  </span>
                  <div className="min-w-0">
                    <p className="truncate text-[13px] font-medium text-card-foreground">
                      {lead.name}
                    </p>
                    <p className="truncate text-[12px] text-muted-foreground">
                      {lead.company}
                      {lead.yuztooStorefront ? ' · Vitrine' : ''}
                    </p>
                  </div>
                </div>
              </td>

              <td className="hidden px-4 py-2.5 text-[12px] text-muted-foreground xl:table-cell">
                {lead.trade ?? '—'}
              </td>

              <td className="px-4 py-2.5">
                <Badge tone={lead.type === 'merchant' ? 'primary' : 'neutral'}>
                  {leadTypeLabels[lead.type]}
                </Badge>
              </td>

              <td className="px-4 py-2.5">
                <LeadStageBadge stage={lead.stage} />
              </td>

              <td className="hidden px-4 py-2.5 text-[12px] text-muted-foreground lg:table-cell">
                {lead.priority ? priorityLabels[lead.priority] : '—'}
              </td>

              <td className="px-4 py-2.5 text-right text-[13px] tabular-nums text-card-foreground">
                {lead.amount > 0 ? formatAmount(lead.amount) : '—'}
              </td>

              <td className="px-4 py-2.5 text-center">
                {lead.instagram ? (
                  <a
                    href={instagramUrl(lead.instagram)}
                    target="_blank"
                    rel="noreferrer"
                    title={`@${lead.instagram}`}
                    onClick={(event) => event.stopPropagation()}
                    className="inline-flex rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                  >
                    <AtSign className="size-4" strokeWidth={1.5} />
                    <span className="sr-only">Instagram @{lead.instagram}</span>
                  </a>
                ) : (
                  <span className="text-[12px] text-muted-foreground">—</span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
