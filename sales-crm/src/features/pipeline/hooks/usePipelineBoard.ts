import { useCallback, useEffect, useState } from 'react'

import type { Lead, LeadStage } from '@/features/leads/domain/lead'
import {
  getLeadsByStage,
  updateLeadStage,
} from '@/features/leads/services/leadService'

type Board = Record<LeadStage, Lead[]>

export function usePipelineBoard() {
  const [board, setBoard] = useState<Board | null>(null)
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const load = useCallback(async () => {
    const { data, error: failure } = await getLeadsByStage()
    if (failure || !data) {
      setError(failure ?? new Error('Pipeline indisponible'))
    } else {
      setError(null)
      setBoard(data)
    }
    setIsLoading(false)
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  /**
   * Optimistic move: the card lands where it was dropped immediately, and we
   * only reload if the service rejects the change.
   */
  const moveLead = useCallback(
    async (lead: Lead, stage: LeadStage, index: number) => {
      setBoard((current) => {
        if (!current) return current
        const next = { ...current }
        for (const key of Object.keys(next) as LeadStage[]) {
          next[key] = next[key].filter((item) => item.id !== lead.id)
        }
        const column = [...next[stage]]
        column.splice(index, 0, { ...lead, stage })
        next[stage] = column
        return next
      })

      const { error: failure } = await updateLeadStage(lead.id, stage)
      if (failure) {
        setError(failure)
        await load()
      }
    },
    [load],
  )

  return { board, error, isLoading, moveLead, reload: load }
}
