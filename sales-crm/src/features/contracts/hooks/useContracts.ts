import { useCallback, useEffect, useState } from 'react'

import type {
  Contract,
  ContractStatus,
} from '@/features/contracts/domain/contract'
import {
  getContractCounts,
  getContracts,
} from '@/features/contracts/services/contractService'

export type ContractFilter = ContractStatus | 'all'

type Counts = Record<ContractFilter, number>

export function useContracts() {
  const [filter, setFilter] = useState<ContractFilter>('all')
  const [contracts, setContracts] = useState<Contract[]>([])
  const [counts, setCounts] = useState<Counts | null>(null)
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const load = useCallback(async () => {
    const [list, totals] = await Promise.all([
      getContracts(filter),
      getContractCounts(),
    ])
    const failure = list.error ?? totals.error
    if (failure) {
      setError(failure)
    } else {
      setError(null)
      setContracts(list.data ?? [])
      setCounts(totals.data)
    }
    setIsLoading(false)
  }, [filter])

  useEffect(() => {
    void load()
  }, [load])

  return { filter, setFilter, contracts, counts, error, isLoading, reload: load }
}
