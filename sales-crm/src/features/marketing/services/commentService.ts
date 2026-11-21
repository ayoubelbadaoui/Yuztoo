import type { CommentAction, PostComment } from '@/features/marketing/domain/comment'
import { callEdgeFunction } from '@/lib/callEdgeFunction'

type Result<T> = { data: T | null; error: Error | null }

type EdgeComment = {
  id: string
  message: string
  createdAt: string
  fromName: string
  fromId: string | null
  likeCount: number
  replyCount: number
  canReply: boolean
  canDelete: boolean
  likedByPage: boolean
  isHidden: boolean
  parentId: string | null
  replies?: EdgeComment[]
}

function mapComment(row: EdgeComment): PostComment {
  return {
    id: row.id,
    message: row.message,
    createdAt: row.createdAt,
    fromName: row.fromName,
    fromId: row.fromId,
    likeCount: row.likeCount,
    replyCount: row.replyCount,
    canReply: row.canReply,
    canDelete: row.canDelete,
    likedByPage: row.likedByPage,
    isHidden: row.isHidden,
    parentId: row.parentId,
    replies: (row.replies ?? []).map(mapComment),
  }
}

async function callComments<T>(
  action: CommentAction,
  body: Record<string, unknown>,
): Promise<Result<T>> {
  const { data, error } = await callEdgeFunction<{
    ok?: boolean
    error?: string
  } & T>('meta-post-comments', { action, ...body })
  if (error) return { data: null, error }
  if (data && data.ok === false) {
    return { data: null, error: new Error(data.error ?? 'Action commentaire refusée') }
  }
  return { data: data as T, error: null }
}

export async function listPostComments(input: {
  workspaceId: string
  postId: string
  channelId: string
}): Promise<Result<PostComment[]>> {
  const result = await callComments<{ comments?: EdgeComment[] }>('list', input)
  if (result.error) return { data: null, error: result.error }
  return {
    data: (result.data?.comments ?? []).map(mapComment),
    error: null,
  }
}

export async function replyToComment(input: {
  workspaceId: string
  postId: string
  channelId: string
  commentId: string | null
  message: string
}): Promise<Result<{ id: string | null }>> {
  const message = input.message.trim()
  if (message.length < 1) {
    return { data: null, error: new Error('Le message est vide') }
  }
  return callComments<{ id: string | null }>('reply', {
    ...input,
    message,
  })
}

export async function deleteComment(input: {
  workspaceId: string
  postId: string
  channelId: string
  commentId: string
}): Promise<Result<{ ok: true }>> {
  return callComments<{ ok: true }>('delete', input)
}

export async function toggleCommentLike(input: {
  workspaceId: string
  postId: string
  channelId: string
  commentId: string
  liked: boolean
}): Promise<Result<{ ok: true }>> {
  return callComments<{ ok: true }>(input.liked ? 'unlike' : 'like', input)
}
