import { useCallback, useEffect, useState } from 'react'

import type { Invoice } from '@/features/billing/domain/invoice'
import type {
  Subscription,
  SubscriptionStatus,
} from '@/features/billing/domain/subscription'
import type { BillingSummary } from '@/features/billing/services/billingService'
import {
  getBillingSummary,
  getOutstandingInvoices,
  getSubscriptions,
  getUpcomingInvoices,
} from '@/features/billing/services/billingService'

type State<T> = { data: T | null; error: Error | null; isLoading: boolean }

function useAsync<T>(load: () => Promise<{ data: T | null; error: Error | null }>) {
  const [state, setState] = useState<State<T>>({
    data: null,
    error: null,
    isLoading: true,
  })

  const run = useCallback(async () => {
    const { data, error } = await load()
    setState({ data, error, isLoading: false })
  }, [load])

  useEffect(() => {
    void run()
  }, [run])

  return { ...state, reload: run }
}

export function useSubscriptions(status: SubscriptionStatus | 'all') {
  const load = useCallback(() => getSubscriptions(status), [status])
  return useAsync<Subscription[]>(load)
}

export function useBillingSummary() {
  return useAsync<BillingSummary>(getBillingSummary)
}

export function useOutstandingInvoices() {
  return useAsync<Invoice[]>(getOutstandingInvoices)
}

export function usePaymentSchedule(monthsAhead = 3) {
  const load = useCallback(() => getUpcomingInvoices(monthsAhead), [monthsAhead])
  return useAsync<Invoice[]>(load)
}
