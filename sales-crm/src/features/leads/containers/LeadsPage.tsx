import { useState } from 'react'

import { LeadEditPanel } from '@/features/leads/components/LeadEditPanel'
import { LeadsPagination } from '@/features/leads/components/LeadsPagination'
import { LeadsTable } from '@/features/leads/components/LeadsTable'
import { LeadsToolbar } from '@/features/leads/components/LeadsToolbar'
import type { Lead } from '@/features/leads/domain/lead'
import type { LeadSegment } from '@/features/leads/hooks/useLeadsTable'
import { useLeadsTable } from '@/features/leads/hooks/useLeadsTable'

const titles: Record<LeadSegment, string> = {
  all: 'Tous les leads',
  merchant: 'Leads commerçants',
  client: 'Leads clients',
}

export function LeadsPage({ initialSegment }: { initialSegment: LeadSegment }) {
  const {
    segment,
    setSegment,
    search,
    setSearch,
    sortKey,
    sortAsc,
    toggleSort,
    page,
    setPage,
    pageSize,
    setPageSize,
    total,
    totalPages,
    leads,
    counts,
    error,
    isLoading,
    reload,
  } = useLeadsTable(initialSegment)

  const [editing, setEditing] = useState<Lead | null>(null)

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          {titles[segment]}
        </h1>
        <p className="text-[13px] text-muted-foreground">
          {`${total} lead${total > 1 ? 's' : ''}`}
          {segment === 'merchant' || segment === 'all'
            ? ' · prospection Yuztoo (commerçants)'
            : ' · segment clients (vide pour l’instant)'}
          {` · ${pageSize} par page`}
        </p>
      </header>

      <LeadsToolbar
        segment={segment}
        onSegmentChange={setSegment}
        counts={counts}
        search={search}
        onSearchChange={setSearch}
      />

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
          Impossible de charger les leads.
        </div>
      )}

      {isLoading && !error && (
        <div className="flex flex-col gap-2">
          {[0, 1, 2, 3, 4, 5].map((index) => (
            <div key={index} className="h-12 animate-pulse rounded-lg bg-muted" />
          ))}
        </div>
      )}

      {!isLoading && !error && (
        <>
          <LeadsTable
            leads={leads}
            sortKey={sortKey}
            sortAsc={sortAsc}
            onSort={toggleSort}
            onSelect={setEditing}
          />
          <LeadsPagination
            page={page}
            totalPages={totalPages}
            total={total}
            pageSize={pageSize}
            onPageChange={setPage}
            onPageSizeChange={setPageSize}
          />
        </>
      )}

      {editing && (
        <LeadEditPanel
          lead={editing}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null)
            reload()
          }}
        />
      )}
    </div>
  )
}
