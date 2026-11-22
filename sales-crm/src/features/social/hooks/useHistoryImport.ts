import { useCallback, useState } from 'react'

import { useAuth } from '@/features/auth/hooks/useAuth'
import {
  importHistoryPage,
  listInboxChannels,
} from '@/features/social/services/historyImportService'

/** Hard stop so a looping cursor can never run forever (≈ 2 000 threads). */
const MAX_PAGES_PER_CHANNEL = 200

export type ImportProgress = {
  channelName: string
  conversations: number
  imported: number
}

/** Pulls past Messenger + Instagram conversations for every connected channel. */
export function useHistoryImport(onBatchDone: () => void) {
  const { session } = useAuth()
  const workspaceId = session?.activeWorkspaceId ?? null
  const [isImporting, setIsImporting] = useState(false)
  const [progress, setProgress] = useState<ImportProgress | null>(null)
  const [summary, setSummary] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const run = useCallback(async () => {
    if (!workspaceId) return
    setIsImporting(true)
    setError(null)
    setSummary(null)
    const { data: channels, error: listError } = await listInboxChannels(workspaceId)
    if (listError || !channels) {
      setError(listError?.message ?? 'Comptes introuvables')
      setIsImporting(false)
      return
    }

    let totalConversations = 0
    let totalImported = 0
    const failures: string[] = []
    for (const channel of channels) {
      let cursor: string | null = null
      let conversations = 0
      let imported = 0
      for (let page = 0; page < MAX_PAGES_PER_CHANNEL; page += 1) {
        setProgress({ channelName: channel.name, conversations, imported })
        const { data, error: pageError } = await importHistoryPage(channel.id, cursor)
        if (pageError || !data) {
          failures.push(`${channel.name} : ${pageError?.message ?? 'erreur'}`)
          break
        }
        conversations += data.conversations
        imported += data.imported
        onBatchDone()
        if (!data.nextCursor) break
        cursor = data.nextCursor
      }
      totalConversations += conversations
      totalImported += imported
    }

    setProgress(null)
    setSummary(
      `${totalConversations} conversation${totalConversations > 1 ? 's' : ''} parcourue${totalConversations > 1 ? 's' : ''}, ${totalImported} nouveau${totalImported > 1 ? 'x' : ''} message${totalImported > 1 ? 's' : ''}.`,
    )
    if (failures.length > 0) setError(failures.join(' · '))
    setIsImporting(false)
  }, [workspaceId, onBatchDone])

  return { run, isImporting, progress, summary, error }
}
