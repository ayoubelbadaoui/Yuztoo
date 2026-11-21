import { useState } from 'react'

import { CmsPagination } from '@/features/cms-app/components/CmsPagination'
import { MerchantEditPanel } from '@/features/cms-app/components/MerchantEditPanel'
import { MerchantsTable } from '@/features/cms-app/components/MerchantsTable'
import { MerchantsToolbar } from '@/features/cms-app/components/MerchantsToolbar'
import type { CmsMerchant } from '@/features/cms-app/domain/cms'
import { useMerchantsTable } from '@/features/cms-app/hooks/useMerchantsTable'

export function MerchantsPage() {
  const table = useMerchantsTable()
  const [selected, setSelected] = useState<CmsMerchant | null>(null)
  const [busyId, setBusyId] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const runStatus = async (
    merchant: CmsMerchant,
    next: 'published' | 'unpublished',
  ) => {
    setBusyId(merchant.id)
    setActionError(null)
    const message = await table.changeStatus(merchant.id, next)
    if (message) setActionError(message)
    setBusyId(null)
  }

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Boutiques
        </h1>
        <p className="text-[13px] text-muted-foreground">
          Liste, édition et publication — miroir de l’admin produit.
        </p>
      </header>

      <MerchantsToolbar
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
        <MerchantsTable
          merchants={table.items}
          busyId={busyId}
          onEdit={setSelected}
          onPublish={(merchant) => void runStatus(merchant, 'published')}
          onUnpublish={(merchant) => void runStatus(merchant, 'unpublished')}
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
        <MerchantEditPanel
          key={selected.id}
          merchant={selected}
          onClose={() => setSelected(null)}
          onSave={table.save}
        />
      )}
    </div>
  )
}
