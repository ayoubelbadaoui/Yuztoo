import { Plus } from 'lucide-react'
import { useState } from 'react'

import { ContractPanel } from '@/features/contracts/components/ContractPanel'
import { ContractsTable } from '@/features/contracts/components/ContractsTable'
import { NewContractPanel } from '@/features/contracts/components/NewContractPanel'
import type { Contract } from '@/features/contracts/domain/contract'
import { contractStatusLabels } from '@/features/contracts/domain/contract'
import type { ContractFilter } from '@/features/contracts/hooks/useContracts'
import { useContracts } from '@/features/contracts/hooks/useContracts'

const filters: ContractFilter[] = [
  'all',
  'draft',
  'sent',
  'signed',
  'declined',
  'expired',
]

const filterLabels: Record<ContractFilter, string> = {
  all: 'Tous',
  ...contractStatusLabels,
}

export function ContractsPage() {
  const { filter, setFilter, contracts, counts, error, isLoading, reload } =
    useContracts()
  const [selected, setSelected] = useState<Contract | null>(null)
  const [isCreating, setIsCreating] = useState(false)

  const refresh = async () => {
    setSelected(null)
    setIsCreating(false)
    await reload()
  }

  const awaiting = contracts.filter(
    (contract) => contract.status === 'sent',
  ).length

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold tracking-tight text-foreground">
            Contrats
          </h1>
          <p className="text-[13px] text-muted-foreground">
            {`${contracts.length} contrat${contracts.length > 1 ? 's' : ''} · ${awaiting} en attente de signature.`}
          </p>
        </div>

        <button
          type="button"
          onClick={() => setIsCreating(true)}
          className="flex h-9 items-center gap-1.5 rounded-lg bg-primary px-3 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90"
        >
          <Plus className="size-4" />
          Nouveau contrat
        </button>
      </header>

      <div className="flex flex-wrap gap-1 rounded-lg border border-border p-0.5">
        {filters.map((option) => (
          <button
            key={option}
            type="button"
            onClick={() => setFilter(option)}
            className={`flex h-8 items-center gap-1.5 rounded-[6px] px-3 text-[13px] transition-colors ${
              filter === option
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {filterLabels[option]}
            {counts && (
              <span className="text-[11px] tabular-nums opacity-70">
                {counts[option]}
              </span>
            )}
          </button>
        ))}
      </div>

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
          Impossible de charger les contrats.
        </div>
      )}

      {isLoading && !error && (
        <div className="flex flex-col gap-2">
          {[0, 1, 2, 3, 4].map((index) => (
            <div
              key={index}
              className="h-14 animate-pulse rounded-lg bg-muted"
            />
          ))}
        </div>
      )}

      {!isLoading && !error && (
        <ContractsTable contracts={contracts} onSelect={setSelected} />
      )}

      {selected && (
        <ContractPanel
          contract={selected}
          onClose={() => setSelected(null)}
          onChanged={() => void refresh()}
        />
      )}

      {isCreating && (
        <NewContractPanel
          onClose={() => setIsCreating(false)}
          onCreated={() => void refresh()}
        />
      )}
    </div>
  )
}
