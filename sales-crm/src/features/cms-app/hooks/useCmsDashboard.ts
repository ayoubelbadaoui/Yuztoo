import { useEffect, useState } from 'react'

import type { CmsOverview } from '@/features/cms-app/domain/cms'
import { getCmsOverview } from '@/features/cms-app/services/cmsOverviewService'

export function useCmsDashboard() {
  const [overview, setOverview] = useState<CmsOverview | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void getCmsOverview().then(({ data, error: failure }) => {
      if (failure) setError(failure.message)
      else setOverview(data)
      setIsLoading(false)
    })
  }, [])

  return { overview, isLoading, error }
}
