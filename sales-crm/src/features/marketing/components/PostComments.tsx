import { RefreshCw, Send } from 'lucide-react'
import { useMemo, useState } from 'react'

import { CommentRow } from '@/features/marketing/components/CommentRow'
import type { Channel } from '@/features/marketing/domain/channel'
import type { Post } from '@/features/marketing/domain/post'
import { usePostComments } from '@/features/marketing/hooks/usePostComments'

type Props = {
  post: Post
  channels: Channel[]
  workspaceId: string | null
}

export function PostComments({ post, channels, workspaceId }: Props) {
  const publishedTargets = useMemo(
    () =>
      post.targets.filter(
        (target) => target.status === 'published' && target.metaPostId,
      ),
    [post.targets],
  )

  const [channelId, setChannelId] = useState(
    publishedTargets[0]?.channelId ?? null,
  )
  const [topDraft, setTopDraft] = useState('')

  const activeChannelId = publishedTargets.some((t) => t.channelId === channelId)
    ? channelId
    : (publishedTargets[0]?.channelId ?? null)

  const comments = usePostComments({
    workspaceId,
    postId: post.id,
    channelId: activeChannelId,
    enabled: publishedTargets.length > 0,
  })

  if (publishedTargets.length === 0) {
    return (
      <section className="rounded-lg border border-dashed border-border px-3 py-4 text-[12px] text-muted-foreground">
        Les commentaires Meta apparaissent après une publication réussie sur un
        post (pas sur une story sans fil de discussion).
      </section>
    )
  }

  const submitTop = async () => {
    const ok = await comments.reply(null, topDraft)
    if (ok) setTopDraft('')
  }

  return (
    <section className="flex flex-col gap-3">
      <div className="flex items-center justify-between gap-2">
        <p className="text-[12px] font-medium text-muted-foreground">
          Commentaires
        </p>
        <button
          type="button"
          disabled={comments.isLoading || comments.isBusy}
          onClick={() => void comments.reload()}
          className="flex h-7 items-center gap-1 rounded-md px-2 text-[11px] text-muted-foreground transition-colors hover:bg-muted hover:text-foreground disabled:opacity-40"
        >
          <RefreshCw className="size-3.5" />
          Actualiser
        </button>
      </div>

      {publishedTargets.length > 1 && (
        <div className="flex flex-wrap gap-1">
          {publishedTargets.map((target) => {
            const channel = channels.find((c) => c.id === target.channelId)
            const selected = target.channelId === activeChannelId
            return (
              <button
                key={target.channelId}
                type="button"
                onClick={() => setChannelId(target.channelId)}
                className={`h-7 rounded-md px-2.5 text-[11px] transition-colors ${
                  selected
                    ? 'bg-primary text-primary-foreground'
                    : 'bg-muted text-muted-foreground hover:text-foreground'
                }`}
              >
                {channel?.name ?? 'Compte'}
              </button>
            )
          })}
        </div>
      )}

      <div className="flex flex-col gap-1.5">
        <textarea
          value={topDraft}
          onChange={(event) => setTopDraft(event.target.value)}
          rows={2}
          placeholder="Commenter en tant que Page…"
          className="w-full resize-none rounded-md border border-border bg-background px-2.5 py-2 text-[13px] text-foreground outline-none focus:border-ring"
        />
        <div className="flex justify-end">
          <button
            type="button"
            disabled={comments.isBusy || topDraft.trim().length === 0}
            onClick={() => void submitTop()}
            className="flex h-8 items-center gap-1.5 rounded-md bg-primary px-3 text-[12px] font-medium text-primary-foreground disabled:opacity-40"
          >
            <Send className="size-3.5" />
            Publier
          </button>
        </div>
      </div>

      {comments.error && (
        <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
          {comments.error}
          {comments.error.toLowerCase().includes('permission') ||
          comments.error.toLowerCase().includes('(#10)') ||
          comments.error.toLowerCase().includes('oauth')
            ? ' — reconnectez la Page pour accorder pages_manage_engagement.'
            : ''}
        </p>
      )}

      {comments.isLoading ? (
        <p className="text-[12px] text-muted-foreground">Chargement…</p>
      ) : comments.comments.length === 0 ? (
        <p className="rounded-lg border border-dashed border-border px-3 py-4 text-center text-[12px] text-muted-foreground">
          Aucun commentaire pour l’instant.
        </p>
      ) : (
        <ul className="flex flex-col divide-y divide-border rounded-lg border border-border px-2.5">
          {comments.comments.map((comment) => (
            <CommentRow
              key={comment.id}
              comment={comment}
              isBusy={comments.isBusy}
              onReply={comments.reply}
              onDelete={comments.remove}
              onToggleLike={comments.toggleLike}
            />
          ))}
        </ul>
      )}
    </section>
  )
}
