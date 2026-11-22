import { useEffect, useState } from 'react'

import type {
  NewsTestClient,
  YuztooNews,
  YuztooNewsActiveFilter,
  YuztooNewsInput,
} from '@/features/cms-app/domain/yuztooNews'
import {
  activateYuztooNewsPreview,
  deleteYuztooNews,
  listYuztooNews,
  publishYuztooNewsLive,
  revertYuztooNewsToDraft,
  setYuztooNewsActive,
  setYuztooNewsTestAccount,
  upsertYuztooNews,
} from '@/features/cms-app/services/yuztooNewsService'

export function useYuztooNews() {
  const [items, setItems] = useState<YuztooNews[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [activeFilter, setActiveFilter] =
    useState<YuztooNewsActiveFilter>('all')
  const [revision, setRevision] = useState(0)

  useEffect(() => {
    let cancelled = false
    setIsLoading(true)
    void listYuztooNews({
      limit: 100,
      includeInactive: activeFilter !== 'active',
      search,
    }).then(({ data, error: failure }) => {
      if (cancelled) return
      if (failure || !data) {
        setError(failure?.message ?? 'Chargement impossible')
        setItems([])
      } else {
        setError(null)
        let next = data.items
        if (activeFilter === 'inactive') {
          next = next.filter((n) => !n.active)
        }
        setItems(next)
      }
      setIsLoading(false)
    })
    return () => {
      cancelled = true
    }
  }, [revision, search, activeFilter])

  const reload = () => setRevision((n) => n + 1)

  const runRelease = async (
    action: () => Promise<{ data: YuztooNews | null; error: Error | null }>,
  ): Promise<{ error: string | null; news: YuztooNews | null }> => {
    const { data, error: failure } = await action()
    if (failure || !data) {
      return { error: failure?.message ?? 'Action impossible', news: null }
    }
    reload()
    return { error: null, news: data }
  }

  return {
    items,
    isLoading,
    error,
    search,
    setSearch,
    activeFilter,
    setActiveFilter,
    reload,
    upsert: async (input: YuztooNewsInput) => {
      const { data, error: failure } = await upsertYuztooNews(input)
      if (failure || !data) return { error: failure?.message ?? 'Erreur', news: null }
      reload()
      return { error: null, news: data }
    },
    setActive: async (id: string, active: boolean) => {
      const { error: failure } = await setYuztooNewsActive(id, active)
      if (failure) return failure.message
      reload()
      return null
    },
    remove: async (id: string) => {
      const { error: failure } = await deleteYuztooNews(id)
      if (failure) return failure.message
      reload()
      return null
    },
    selectTestAccount: (id: string, account: NewsTestClient | null) =>
      runRelease(() => setYuztooNewsTestAccount(id, account)),
    activatePreview: (id: string) =>
      runRelease(() => activateYuztooNewsPreview(id)),
    publishLive: (id: string) => runRelease(() => publishYuztooNewsLive(id)),
    revertToDraft: (id: string) =>
      runRelease(() => revertYuztooNewsToDraft(id)),
  }
}
