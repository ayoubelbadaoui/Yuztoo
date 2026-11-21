import { useState } from 'react'

import { ClientEditPanel } from '@/features/cms-app/components/ClientEditPanel'
import { ClientsTable } from '@/features/cms-app/components/ClientsTable'
import { ClientsToolbar } from '@/features/cms-app/components/ClientsToolbar'
import { CmsPagination } from '@/features/cms-app/components/CmsPagination'
import type { CmsClient } from '@/features/cms-app/domain/cms'
import { useClientsTable } from '@/features/cms-app/hooks/useClientsTable'

export function ClientsPage() {
  const table = useClientsTable()
  const [selected, setSelected] = useState<CmsClient | null>(null)
  const [busyId, setBusyId] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const runStatus = async (client: CmsClient, next: 'active' | 'blocked') => {
    setBusyId(client.id)
    setActionError(null)
    const message = await table.changeStatus(client.id, next)
    if (message) setActionError(message)
    setBusyId(null)
  }

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Clients
        </h1>
        <p className="text-[13px] text-muted-foreground">
          Comptes produit — édition et blocage (mock phase 1).
        </p>
      </header>

      <ClientsToolbar
        search={table.search}
        onSearch={table.setSearch}
        status={table.status}
        onStatus={table.setStatus}
      />

      {(table.error || actionError) && (
        <p className="rounded-xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-[13px] text-destructive">
          {table.error ?? actionError}
        </p>
      )}

      {table.isLoading ? (
        <div className="h-64 animate-pulse rounded-xl bg-muted" />
      ) : (
        <ClientsTable
          clients={table.items}
          busyId={busyId}
          onEdit={setSelected}
          onBlock={(client) => void runStatus(client, 'blocked')}
          onUnblock={(client) => void runStatus(client, 'active')}
        />
      )}

      <CmsPagination
        page={table.page}
        totalPages={table.totalPages}
        total={table.total}
        pageSize={table.pageSize}
        onPageChange={table.setPage}
        onPageSizeChange={table.setPageSize}
      />

      {selected && (
        <ClientEditPanel
          key={selected.id}
          client={selected}
          onClose={() => setSelected(null)}
          onSave={table.save}
        />
      )}
    </div>
  )
}
