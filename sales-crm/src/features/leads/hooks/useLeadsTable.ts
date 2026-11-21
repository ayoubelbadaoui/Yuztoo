import { useEffect, useState } from 'react'

import type { Lead, LeadType } from '@/features/leads/domain/lead'
import { LEAD_PAGE_SIZE } from '@/features/leads/domain/lead'
import type { LeadSortKey } from '@/features/leads/services/leadService'
import { getLeadCounts, getLeads } from '@/features/leads/services/leadService'

export type LeadSegment = LeadType | 'all'

type Counts = { all: number; merchant: number; client: number }

export function useLeadsTable(initialSegment: LeadSegment) {
  const [segment, setSegmentState] = useState<LeadSegment>(initialSegment)
  const [search, setSearchState] = useState('')
  const [sortKey, setSortKey] = useState<LeadSortKey>('updatedAt')
  const [sortAsc, setSortAsc] = useState(false)
  const [page, setPage] = useState(1)
  const [pageSize, setPageSizeState] = useState(LEAD_PAGE_SIZE)

  const [leads, setLeads] = useState<Lead[]>([])
  const [total, setTotal] = useState(0)
  const [totalPages, setTotalPages] = useState(1)
  const [counts, setCounts] = useState<Counts | null>(null)
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  /** Bumped after an edit so the list refetches with the current filters. */
  const [revision, setRevision] = useState(0)

  useEffect(() => {
    setSegmentState(initialSegment)
    setPage(1)
  }, [initialSegment])

  useEffect(() => {
    let cancelled = false

    const load = async () => {
      const [leadsResult, countsResult] = await Promise.all([
        getLeads({
          type: segment,
          search,
          sortKey,
          sortAsc,
          page,
          pageSize,
        }),
        getLeadCounts(),
      ])
      if (cancelled) return

      const failure = leadsResult.error ?? countsResult.error
      if (failure || !leadsResult.data) {
        setError(failure ?? new Error('Données indisponibles'))
      } else {
        setError(null)
        setLeads(leadsResult.data.items)
        setTotal(leadsResult.data.total)
        setTotalPages(leadsResult.data.totalPages)
        if (leadsResult.data.page !== page) setPage(leadsResult.data.page)
        setCounts(countsResult.data)
      }
      setIsLoading(false)
    }

    void load()
    return () => {
      cancelled = true
    }
  }, [segment, search, sortKey, sortAsc, page, pageSize, revision])

  const setSegment = (next: LeadSegment) => {
    setSegmentState(next)
    setPage(1)
  }

  const setSearch = (next: string) => {
    setSearchState(next)
    setPage(1)
  }

  const setPageSize = (next: number) => {
    setPageSizeState(next)
    setPage(1)
  }

  /** Clicking the active column flips direction, a new column resets to desc. */
  const toggleSort = (key: LeadSortKey) => {
    setPage(1)
    if (key === sortKey) {
      setSortAsc((current) => !current)
      return
    }
    setSortKey(key)
    setSortAsc(false)
  }

  return {
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
    reload: () => setRevision((current) => current + 1),
  }
}
