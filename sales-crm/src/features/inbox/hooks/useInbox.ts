import { useCallback, useEffect, useState } from 'react'

import type { InboxMessage } from '@/features/inbox/domain/message'
import type { InboxFilter } from '@/features/inbox/services/inboxService'
import {
  getMessageCounts,
  getMessages,
  markRead,
} from '@/features/inbox/services/inboxService'

export function useInbox() {
  const [filter, setFilter] = useState<InboxFilter>('all')
  const [search, setSearch] = useState('')
  const [messages, setMessages] = useState<InboxMessage[]>([])
  const [counts, setCounts] = useState<Record<InboxFilter, number> | null>(null)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const load = useCallback(async () => {
    const [list, totals] = await Promise.all([
      getMessages({ filter, search }),
      getMessageCounts(),
    ])
    const failure = list.error ?? totals.error
    if (failure) {
      setError(failure)
    } else {
      setError(null)
      setMessages(list.data ?? [])
      setCounts(totals.data)
    }
    setIsLoading(false)
  }, [filter, search])

  useEffect(() => {
    void load()
  }, [load])

  /** Ouvrir un message le marque lu, d'où le rechargement des compteurs. */
  const select = useCallback(async (id: string) => {
    setSelectedId(id)
    await markRead(id)
    await load()
  }, [load])

  const selected =
    messages.find((message) => message.id === selectedId) ?? null

  return {
    filter,
    setFilter,
    search,
    setSearch,
    messages,
    counts,
    selected,
    select,
    error,
    isLoading,
    reload: load,
  }
}
