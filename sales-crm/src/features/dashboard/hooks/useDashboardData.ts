import { useEffect, useState } from 'react'

import type { Lead } from '@/features/leads/domain/lead'
import type { PipelineSummary } from '@/features/leads/services/leadService'
import {
  getPipelineSummary,
  getRecentLeads,
} from '@/features/leads/services/leadService'

type DashboardData = {
  leads: Lead[]
  summary: PipelineSummary[]
}

export function useDashboardData() {
  const [data, setData] = useState<DashboardData | null>(null)
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    let cancelled = false

    const load = async () => {
      const [leadsResult, summaryResult] = await Promise.all([
        getRecentLeads(),
        getPipelineSummary(),
      ])
      if (cancelled) return

      const failure = leadsResult.error ?? summaryResult.error
      if (failure || !leadsResult.data || !summaryResult.data) {
        setError(failure ?? new Error('Données indisponibles'))
      } else {
        setData({ leads: leadsResult.data, summary: summaryResult.data })
      }
      setIsLoading(false)
    }

    void load()
    return () => {
      cancelled = true
    }
  }, [])

  return { data, error, isLoading }
}
