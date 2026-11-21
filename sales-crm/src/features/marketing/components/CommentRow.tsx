import { Heart, MessageCircle, Trash2 } from 'lucide-react'
import { useState } from 'react'

import type { PostComment } from '@/features/marketing/domain/comment'
import { formatSchedule } from '@/features/marketing/domain/post'

type Props = {
  comment: PostComment
  depth?: number
  isBusy: boolean
  onReply: (commentId: string, message: string) => Promise<boolean>
  onDelete: (commentId: string) => Promise<boolean>
  onToggleLike: (comment: PostComment) => Promise<boolean>
}

export function CommentRow({
  comment,
  depth = 0,
  isBusy,
  onReply,
  onDelete,
  onToggleLike,
}: Props) {
  const [isReplying, setIsReplying] = useState(false)
  const [draft, setDraft] = useState('')

  const submitReply = async () => {
    const ok = await onReply(comment.id, draft)
    if (ok) {
      setDraft('')
      setIsReplying(false)
    }
  }

  return (
    <li className={depth > 0 ? 'ml-6 border-l border-border pl-3' : undefined}>
      <article className="flex flex-col gap-1.5 py-2.5">
        <header className="flex items-baseline justify-between gap-2">
          <p className="min-w-0 truncate text-[13px] font-medium text-card-foreground">
            {comment.fromName}
            {comment.isHidden ? (
              <span className="ml-1.5 text-[11px] font-normal text-muted-foreground">
                · masqué
              </span>
            ) : null}
          </p>
          <time className="shrink-0 text-[11px] text-muted-foreground">
            {formatSchedule(comment.createdAt)}
          </time>
        </header>

        <p className="whitespace-pre-wrap text-[13px] text-foreground">
          {comment.message || '—'}
        </p>

        <div className="flex flex-wrap items-center gap-1">
          <button
            type="button"
            disabled={isBusy}
            onClick={() => void onToggleLike(comment)}
            className={`flex h-7 items-center gap-1 rounded-md px-2 text-[11px] transition-colors disabled:opacity-40 ${
              comment.likedByPage
                ? 'bg-primary/10 text-primary'
                : 'text-muted-foreground hover:bg-muted hover:text-foreground'
            }`}
          >
            <Heart
              className={`size-3.5 ${comment.likedByPage ? 'fill-current' : ''}`}
            />
            {comment.likeCount > 0 ? comment.likeCount : 'J’aime'}
          </button>

          {comment.canReply && (
            <button
              type="button"
              disabled={isBusy}
              onClick={() => setIsReplying((open) => !open)}
              className="flex h-7 items-center gap-1 rounded-md px-2 text-[11px] text-muted-foreground transition-colors hover:bg-muted hover:text-foreground disabled:opacity-40"
            >
              <MessageCircle className="size-3.5" />
              Répondre
            </button>
          )}

          {comment.canDelete && (
            <button
              type="button"
              disabled={isBusy}
              onClick={() => {
                if (window.confirm('Supprimer ce commentaire ?')) {
                  void onDelete(comment.id)
                }
              }}
              className="flex h-7 items-center gap-1 rounded-md px-2 text-[11px] text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive disabled:opacity-40"
            >
              <Trash2 className="size-3.5" />
              Supprimer
            </button>
          )}
        </div>

        {isReplying && (
          <div className="mt-1 flex flex-col gap-1.5">
            <textarea
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              rows={2}
              placeholder="Répondre en tant que Page…"
              className="w-full resize-none rounded-md border border-border bg-background px-2.5 py-2 text-[13px] text-foreground outline-none focus:border-ring"
            />
            <div className="flex justify-end gap-1.5">
              <button
                type="button"
                onClick={() => {
                  setIsReplying(false)
                  setDraft('')
                }}
                className="h-7 rounded-md px-2.5 text-[12px] text-muted-foreground hover:bg-muted"
              >
                Annuler
              </button>
              <button
                type="button"
                disabled={isBusy || draft.trim().length === 0}
                onClick={() => void submitReply()}
                className="h-7 rounded-md bg-primary px-2.5 text-[12px] font-medium text-primary-foreground disabled:opacity-40"
              >
                Envoyer
              </button>
            </div>
          </div>
        )}
      </article>

      {comment.replies.length > 0 && (
        <ul className="flex flex-col">
          {comment.replies.map((reply) => (
            <CommentRow
              key={reply.id}
              comment={reply}
              depth={depth + 1}
              isBusy={isBusy}
              onReply={onReply}
              onDelete={onDelete}
              onToggleLike={onToggleLike}
            />
          ))}
        </ul>
      )}
    </li>
  )
}
