export type PostComment = {
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
  replies: PostComment[]
}

export type CommentAction =
  | 'list'
  | 'reply'
  | 'delete'
  | 'like'
  | 'unlike'
