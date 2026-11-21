import { useCallback, useEffect, useState } from 'react'

import { useAuth } from '@/features/auth/hooks/useAuth'
import type { Channel } from '@/features/marketing/domain/channel'
import type { Post } from '@/features/marketing/domain/post'
import type {
  MarketingSummary,
  PostFilter,
} from '@/features/marketing/services/marketingService'
import { getChannels } from '@/features/marketing/services/channelService'
import {
  getMarketingSummary,
  getPostCounts,
  getPosts,
} from '@/features/marketing/services/marketingService'

export function useChannels() {
  const { session } = useAuth()
  const workspaceId = session?.activeWorkspaceId ?? null
  const [channels, setChannels] = useState<Channel[]>([])
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const load = useCallback(async () => {
    if (!workspaceId) {
      setChannels([])
      setIsLoading(false)
      return
    }
    setIsLoading(true)
    const { data, error: failure } = await getChannels(workspaceId)
    setChannels(data ?? [])
    setError(failure)
    setIsLoading(false)
  }, [workspaceId])

  useEffect(() => {
    void load()
  }, [load])

  return { channels, isLoading, error, reload: load, workspaceId }
}

export function useMarketing() {
  const { session } = useAuth()
  const workspaceId = session?.activeWorkspaceId ?? null
  const [filter, setFilter] = useState<PostFilter>('all')
  const [posts, setPosts] = useState<Post[]>([])
  const [counts, setCounts] = useState<Record<PostFilter, number> | null>(null)
  const [summary, setSummary] = useState<MarketingSummary | null>(null)
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const load = useCallback(async () => {
    if (!workspaceId) {
      setPosts([])
      setCounts(null)
      setSummary(null)
      setIsLoading(false)
      return
    }

    const [list, totals, stats] = await Promise.all([
      getPosts(workspaceId, filter),
      getPostCounts(workspaceId),
      getMarketingSummary(workspaceId),
    ])
    const failure = list.error ?? totals.error ?? stats.error
    if (failure) {
      setError(failure)
    } else {
      setError(null)
      setPosts(list.data ?? [])
      setCounts(totals.data)
      setSummary(stats.data)
    }
    setIsLoading(false)
  }, [filter, workspaceId])

  useEffect(() => {
    void load()
  }, [load])

  return {
    filter,
    setFilter,
    posts,
    counts,
    summary,
    error,
    isLoading,
    reload: load,
    workspaceId,
  }
}
