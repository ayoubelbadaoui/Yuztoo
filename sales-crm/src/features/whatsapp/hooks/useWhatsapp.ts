import { useCallback, useEffect, useState } from 'react'

import type {
  WaConversation,
  WaMessage,
} from '@/features/whatsapp/domain/conversation'
import type { WaTemplate } from '@/features/whatsapp/domain/template'
import type { ConversationFilter } from '@/features/whatsapp/services/whatsappService'
import {
  getConversationCounts,
  getConversations,
  getMessages,
  getTemplates,
  markConversationRead,
} from '@/features/whatsapp/services/whatsappService'

export function useTemplates() {
  const [templates, setTemplates] = useState<WaTemplate[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    void getTemplates().then(({ data }) => {
      setTemplates(data ?? [])
      setIsLoading(false)
    })
  }, [])

  return { templates, isLoading }
}

export function useWhatsapp() {
  const [filter, setFilter] = useState<ConversationFilter>('all')
  const [search, setSearch] = useState('')
  const [conversations, setConversations] = useState<WaConversation[]>([])
  const [counts, setCounts] = useState<Record<
    ConversationFilter,
    number
  > | null>(null)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [messages, setMessages] = useState<WaMessage[]>([])
  const [isLoading, setIsLoading] = useState(true)

  const loadList = useCallback(async () => {
    const [list, totals] = await Promise.all([
      getConversations(filter, search),
      getConversationCounts(),
    ])
    setConversations(list.data ?? [])
    setCounts(totals.data)
    setIsLoading(false)
  }, [filter, search])

  const loadThread = useCallback(async (id: string) => {
    const { data } = await getMessages(id)
    setMessages(data ?? [])
  }, [])

  useEffect(() => {
    void loadList()
  }, [loadList])

  useEffect(() => {
    if (selectedId) void loadThread(selectedId)
  }, [selectedId, loadThread])

  const select = useCallback(
    async (id: string) => {
      setSelectedId(id)
      await markConversationRead(id)
      await loadList()
    },
    [loadList],
  )

  const refreshThread = useCallback(async () => {
    if (selectedId) await loadThread(selectedId)
    await loadList()
  }, [selectedId, loadThread, loadList])

  const selected =
    conversations.find((conversation) => conversation.id === selectedId) ?? null

  return {
    filter,
    setFilter,
    search,
    setSearch,
    conversations,
    counts,
    selected,
    messages,
    select,
    refreshThread,
    isLoading,
  }
}
