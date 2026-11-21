import { useCallback, useEffect, useState } from 'react'

import { useAuth } from '@/features/auth/hooks/useAuth'
import type {
  SocialConversation,
  SocialMessage,
} from '@/features/social/domain/conversation'
import {
  getConversations,
  getMessages,
  markRead,
  sendMessage,
  subscribeToWorkspaceMessages,
} from '@/features/social/services/socialInboxService'

export function useSocialInbox() {
  const { session } = useAuth()
  const workspaceId = session?.activeWorkspaceId ?? null

  const [conversations, setConversations] = useState<SocialConversation[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [messages, setMessages] = useState<SocialMessage[]>([])
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isSending, setIsSending] = useState(false)

  const loadConversations = useCallback(async () => {
    if (!workspaceId) {
      setConversations([])
      setIsLoading(false)
      return
    }
    const { data, error: failure } = await getConversations(workspaceId)
    setConversations(data ?? [])
    setError(failure)
    setIsLoading(false)
  }, [workspaceId])

  const loadMessages = useCallback(async (conversationId: string | null) => {
    if (!conversationId) {
      setMessages([])
      return
    }
    const { data } = await getMessages(conversationId)
    setMessages(data ?? [])
  }, [])

  useEffect(() => {
    void loadConversations()
  }, [loadConversations])

  useEffect(() => {
    void loadMessages(selectedId)
  }, [loadMessages, selectedId])

  useEffect(() => {
    if (!workspaceId) return
    return subscribeToWorkspaceMessages(workspaceId, () => {
      void loadConversations()
      void loadMessages(selectedId)
    })
  }, [workspaceId, loadConversations, loadMessages, selectedId])

  const select = useCallback(
    async (conversationId: string) => {
      setSelectedId(conversationId)
      await markRead(conversationId)
      void loadConversations()
    },
    [loadConversations],
  )

  const send = useCallback(
    async (text: string) => {
      if (!selectedId) return
      setIsSending(true)
      const { error: failure } = await sendMessage(selectedId, text)
      setError(failure)
      setIsSending(false)
      if (!failure) {
        await loadMessages(selectedId)
        void loadConversations()
      }
    },
    [selectedId, loadConversations, loadMessages],
  )

  const selected =
    conversations.find((conversation) => conversation.id === selectedId) ?? null

  return {
    conversations,
    selected,
    messages,
    isLoading,
    isSending,
    error,
    select,
    send,
    reload: loadConversations,
  }
}
