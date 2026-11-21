import { useCallback, useEffect, useState } from 'react'

import type { PostComment } from '@/features/marketing/domain/comment'
import {
  deleteComment,
  listPostComments,
  replyToComment,
  toggleCommentLike,
} from '@/features/marketing/services/commentService'

export function usePostComments(input: {
  workspaceId: string | null
  postId: string
  channelId: string | null
  enabled: boolean
}) {
  const [comments, setComments] = useState<PostComment[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [isBusy, setIsBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const reload = useCallback(async () => {
    if (!input.enabled || !input.workspaceId || !input.channelId) {
      setComments([])
      return
    }
    setIsLoading(true)
    setError(null)
    const { data, error: failure } = await listPostComments({
      workspaceId: input.workspaceId,
      postId: input.postId,
      channelId: input.channelId,
    })
    setIsLoading(false)
    if (failure) {
      setError(failure.message)
      setComments([])
      return
    }
    setComments(data ?? [])
  }, [input.channelId, input.enabled, input.postId, input.workspaceId])

  useEffect(() => {
    void reload()
  }, [reload])

  const reply = async (
    commentId: string | null,
    message: string,
  ): Promise<boolean> => {
    if (!input.workspaceId || !input.channelId) return false
    setIsBusy(true)
    setError(null)
    const { error: failure } = await replyToComment({
      workspaceId: input.workspaceId,
      postId: input.postId,
      channelId: input.channelId,
      commentId,
      message,
    })
    setIsBusy(false)
    if (failure) {
      setError(failure.message)
      return false
    }
    await reload()
    return true
  }

  const remove = async (commentId: string): Promise<boolean> => {
    if (!input.workspaceId || !input.channelId) return false
    setIsBusy(true)
    setError(null)
    const { error: failure } = await deleteComment({
      workspaceId: input.workspaceId,
      postId: input.postId,
      channelId: input.channelId,
      commentId,
    })
    setIsBusy(false)
    if (failure) {
      setError(failure.message)
      return false
    }
    await reload()
    return true
  }

  const toggleLike = async (comment: PostComment): Promise<boolean> => {
    if (!input.workspaceId || !input.channelId) return false
    setIsBusy(true)
    setError(null)
    const { error: failure } = await toggleCommentLike({
      workspaceId: input.workspaceId,
      postId: input.postId,
      channelId: input.channelId,
      commentId: comment.id,
      liked: comment.likedByPage,
    })
    setIsBusy(false)
    if (failure) {
      setError(failure.message)
      return false
    }
    await reload()
    return true
  }

  return {
    comments,
    isLoading,
    isBusy,
    error,
    reload,
    reply,
    remove,
    toggleLike,
  }
}
