import { useEffect, useState } from 'react'

import type {
  MediaRelease,
  MediaTestAccount,
} from '@/features/cms-app/domain/mediaRelease'
import {
  activateMediaPreview,
  demoteLiveMediaToDraft,
  getMediaRelease,
  listMediaTestAccounts,
  publishMediaLive,
  revertMediaToDraft,
  setMediaTestAccount,
  stopMediaPreview,
} from '@/features/cms-app/services/cmsMediaReleaseService'

export function useCmsMediaRelease() {
  const [release, setRelease] = useState<MediaRelease | null>(null)
  const [accounts, setAccounts] = useState<MediaTestAccount[]>([])
  const [search, setSearch] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [isBusy, setIsBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const reload = async (query = search) => {
    const [releaseResult, accountsResult] = await Promise.all([
      getMediaRelease(),
      listMediaTestAccounts(query),
    ])
    if (releaseResult.error) setError(releaseResult.error.message)
    else setRelease(releaseResult.data)
    if (accountsResult.error) setError(accountsResult.error.message)
    else setAccounts(accountsResult.data ?? [])
    setIsLoading(false)
  }

  useEffect(() => {
    void reload('')
  }, [])

  useEffect(() => {
    const handle = window.setTimeout(() => {
      void listMediaTestAccounts(search).then(({ data, error: failure }) => {
        if (failure) setError(failure.message)
        else setAccounts(data ?? [])
      })
    }, 200)
    return () => window.clearTimeout(handle)
  }, [search])

  const run = async (
    action: () => Promise<{ data: MediaRelease | null; error: Error | null }>,
  ) => {
    setIsBusy(true)
    setError(null)
    const { data, error: failure } = await action()
    setIsBusy(false)
    if (failure || !data) {
      setError(failure?.message ?? 'Action impossible')
      return failure?.message ?? 'Action impossible'
    }
    setRelease(data)
    return null
  }

  return {
    release,
    accounts,
    search,
    setSearch,
    isLoading,
    isBusy,
    error,
    setError,
    selectAccount: (account: MediaTestAccount | null) =>
      run(() => setMediaTestAccount(account)),
    activatePreview: () => run(() => activateMediaPreview()),
    stopPreview: () => run(() => stopMediaPreview()),
    publishLive: () => run(() => publishMediaLive()),
    revertToDraft: () => run(() => revertMediaToDraft()),
    demoteIfLive: () => run(() => demoteLiveMediaToDraft()),
    reload: () => reload(),
  }
}
