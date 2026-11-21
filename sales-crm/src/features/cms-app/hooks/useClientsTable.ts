import { useEffect, useState } from 'react'

import type { ClientStatus, CmsClient } from '@/features/cms-app/domain/cms'
import { CMS_PAGE_SIZE } from '@/features/cms-app/domain/cms'
import {
  listClients,
  setClientStatus,
  updateClient,
  type ClientPatch,
} from '@/features/cms-app/services/clientService'

export function useClientsTable() {
  const [search, setSearchState] = useState('')
  const [status, setStatusState] = useState<ClientStatus | 'all'>('all')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSizeState] = useState(CMS_PAGE_SIZE)
  const [items, setItems] = useState<CmsClient[]>([])
  const [total, setTotal] = useState(0)
  const [totalPages, setTotalPages] = useState(1)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [revision, setRevision] = useState(0)

  useEffect(() => {
    let cancelled = false
    void listClients({ search, status, page, pageSize }).then(
      ({ data, error: failure }) => {
        if (cancelled) return
        if (failure || !data) {
          setError(failure?.message ?? 'Chargement impossible')
        } else {
          setError(null)
          setItems(data.items)
          setTotal(data.total)
          setTotalPages(data.totalPages)
          if (data.page !== page) setPage(data.page)
        }
        setIsLoading(false)
      },
    )
    return () => {
      cancelled = true
    }
  }, [search, status, page, pageSize, revision])

  const setSearch = (value: string) => {
    setSearchState(value)
    setPage(1)
  }

  const setStatus = (value: ClientStatus | 'all') => {
    setStatusState(value)
    setPage(1)
  }

  const setPageSize = (value: number) => {
    setPageSizeState(value)
    setPage(1)
  }

  const reload = () => setRevision((n) => n + 1)

  const save = async (id: string, patch: ClientPatch) => {
    const { error: failure } = await updateClient(id, patch)
    if (failure) return failure.message
    reload()
    return null
  }

  const changeStatus = async (id: string, next: ClientStatus) => {
    const { error: failure } = await setClientStatus(id, next)
    if (failure) return failure.message
    reload()
    return null
  }

  return {
    search,
    setSearch,
    status,
    setStatus,
    page,
    setPage,
    pageSize,
    setPageSize,
    items,
    total,
    totalPages,
    isLoading,
    error,
    reload,
    save,
    changeStatus,
  }
}
