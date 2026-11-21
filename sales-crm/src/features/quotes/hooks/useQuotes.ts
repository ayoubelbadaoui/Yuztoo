import { useCallback, useEffect, useState } from 'react'

import type { Quote, QuoteStatus } from '@/features/quotes/domain/quote'
import { getQuoteCounts, getQuotes } from '@/features/quotes/services/quoteService'

export type QuoteFilter = QuoteStatus | 'all'

type Counts = Record<QuoteFilter, number>

export function useQuotes() {
  const [filter, setFilter] = useState<QuoteFilter>('all')
  const [quotes, setQuotes] = useState<Quote[]>([])
  const [counts, setCounts] = useState<Counts | null>(null)
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const load = useCallback(async () => {
    const [list, totals] = await Promise.all([
      getQuotes(filter),
      getQuoteCounts(),
    ])
    const failure = list.error ?? totals.error
    if (failure) {
      setError(failure)
    } else {
      setError(null)
      setQuotes(list.data ?? [])
      setCounts(totals.data)
    }
    setIsLoading(false)
  }, [filter])

  useEffect(() => {
    void load()
  }, [load])

  return { filter, setFilter, quotes, counts, error, isLoading, reload: load }
}
