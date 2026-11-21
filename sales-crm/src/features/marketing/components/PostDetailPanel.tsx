import { AlertTriangle, ExternalLink, RotateCw, X } from 'lucide-react'
import { useEffect, useState } from 'react'

import { useAuth } from '@/features/auth/hooks/useAuth'
import { ChannelIcon } from '@/features/marketing/components/ChannelBadge'
import { PostComments } from '@/features/marketing/components/PostComments'
import { PostPreview } from '@/features/marketing/components/PostPreview'
import type { Channel } from '@/features/marketing/domain/channel'
import { networkMixLabel } from '@/features/marketing/domain/channel'
import type { Post, PostRun } from '@/features/marketing/domain/post'
import {
  failedCount,
  formatCount,
  formatSchedule,
  postFormatLabels,
  postRunStatusLabels,
  publishedCount,
} from '@/features/marketing/domain/post'
import { recurrenceFreqLabels } from '@/features/marketing/domain/recurrence'
import {
  cancelPost,
  getPostRuns,
  publishNow,
  retryFailedTargets,
} from '@/features/marketing/services/marketingService'

type Props = {
  post: Post
  channels: Channel[]
  onClose: () => void
  onChanged: () => void
}

export function PostDetailPanel({ post, channels, onClose, onChanged }: Props) {
  const { session } = useAuth()
  const workspaceId = session?.activeWorkspaceId ?? null
  const [isBusy, setIsBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [runs, setRuns] = useState<PostRun[]>([])

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  useEffect(() => {
    let cancelled = false
    void getPostRuns(post.id).then(({ data }) => {
      if (!cancelled) setRuns(data ?? [])
    })
    return () => {
      cancelled = true
    }
  }, [post.id])

  const targetChannels = post.targets
    .map((target) =>
      channels.find((channel) => channel.id === target.channelId),
    )
    .filter((channel): channel is Channel => Boolean(channel))

  const run = async (action: 'publish' | 'retry' | 'cancel') => {
    if (action !== 'cancel' && !workspaceId) {
      setError('Aucun espace de travail actif')
      return
    }
    setIsBusy(true)
    const { error: failure } =
      action === 'publish'
        ? await publishNow(workspaceId!, post.id)
        : action === 'retry'
          ? await retryFailedTargets(workspaceId!, post.id)
          : await cancelPost(post.id)
    setIsBusy(false)

    if (failure) {
      setError(failure.message)
      return
    }
    onChanged()
  }

  const failed = failedCount(post)
  const isSent = post.status === 'published' || post.status === 'partial'

  return (
    <div className="fixed inset-0 z-40 flex justify-end">
      <button
        type="button"
        aria-label="Fermer le panneau"
        onClick={onClose}
        className="absolute inset-0 bg-foreground/20"
      />

      <aside
        role="dialog"
        aria-modal="true"
        aria-label={`Publication ${post.id}`}
        className="pop-in relative flex h-full w-full max-w-xl flex-col border-l border-border bg-card shadow-2xl"
      >
        <header className="flex shrink-0 items-start justify-between gap-3 border-b border-border p-4">
          <div className="min-w-0">
            <h2 className="text-[15px] font-semibold text-card-foreground">
              {`${postFormatLabels[post.format]} · ${post.id}`}
            </h2>
            <p className="truncate text-[12px] text-muted-foreground">
              {post.publishedAt
                ? `Publiée le ${formatSchedule(post.publishedAt)}`
                : post.scheduledAt
                  ? `Programmée le ${formatSchedule(post.scheduledAt)}`
                  : 'Brouillon'}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Fermer"
            className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          >
            <X className="size-4" />
          </button>
        </header>

        <div className="scrollbar-none flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto p-4">
          <PostPreview
            format={post.format}
            caption={post.caption}
            mediaLabel={post.mediaLabel}
            mediaUrl={post.mediaUrl}
            channels={targetChannels}
          />

          <dl className="grid grid-cols-2 gap-2 text-[12px]">
            <div className="rounded-lg border border-border bg-muted/40 p-2.5">
              <dt className="text-muted-foreground">Réseaux</dt>
              <dd className="font-medium text-card-foreground">
                {targetChannels.length > 0
                  ? networkMixLabel(targetChannels)
                  : '—'}
              </dd>
            </div>
            <div className="rounded-lg border border-border bg-muted/40 p-2.5">
              <dt className="text-muted-foreground">Récurrence</dt>
              <dd className="font-medium text-card-foreground">
                {recurrenceFreqLabels[post.recurrence.freq]}
                {post.recurrence.freq === 'every_n_days'
                  ? ` (${post.recurrence.interval} j)`
                  : ''}
              </dd>
            </div>
          </dl>

          {post.metrics && (
            <dl className="grid grid-cols-3 gap-2">
              {[
                { label: 'Portée', value: post.metrics.reach },
                { label: 'Interactions', value: post.metrics.engagements },
                { label: 'Clics', value: post.metrics.clicks },
              ].map((metric) => (
                <div
                  key={metric.label}
                  className="rounded-lg border border-border bg-muted/40 p-2.5"
                >
                  <dt className="text-[11px] text-muted-foreground">
                    {metric.label}
                  </dt>
                  <dd className="text-[15px] font-semibold tabular-nums text-card-foreground">
                    {formatCount(metric.value)}
                  </dd>
                </div>
              ))}
            </dl>
          )}

          {failed > 0 && (
            <p className="flex items-start gap-2 rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
              <AlertTriangle className="mt-px size-3.5 shrink-0" />
              {`${failed} compte${failed > 1 ? 's ont' : ' a'} échoué. Relancer ne renvoie que ceux-là.`}
            </p>
          )}

          {runs.length > 0 && (
            <section className="flex flex-col gap-1.5">
              <p className="text-[12px] font-medium text-muted-foreground">
                {`Occurrences · ${runs.filter((run) => run.status === 'published').length}/${runs.length}`}
              </p>
              <ul className="flex flex-col divide-y divide-border rounded-lg border border-border">
                {runs.map((run) => (
                  <li
                    key={run.id}
                    className="flex items-center gap-2 px-2.5 py-2 text-[12px]"
                  >
                    <span className="tabular-nums text-muted-foreground">
                      #{run.occurrenceIndex}
                    </span>
                    <span className="min-w-0 flex-1 text-foreground">
                      {formatSchedule(run.runAt)}
                    </span>
                    <span
                      className={
                        run.status === 'failed'
                          ? 'text-destructive'
                          : run.status === 'published'
                            ? 'text-success'
                            : 'text-muted-foreground'
                      }
                    >
                      {postRunStatusLabels[run.status]}
                    </span>
                  </li>
                ))}
              </ul>
            </section>
          )}

          <section className="flex flex-col gap-1.5">
            <p className="text-[12px] font-medium text-muted-foreground">
              {`Destinations · ${publishedCount(post)}/${post.targets.length} publiées`}
            </p>

            <ul className="flex flex-col divide-y divide-border rounded-lg border border-border">
              {post.targets.map((target) => {
                const channel = channels.find(
                  (candidate) => candidate.id === target.channelId,
                )
                return (
                  <li
                    key={target.channelId}
                    className="flex items-center gap-2 px-2.5 py-2"
                  >
                    {channel && <ChannelIcon channel={channel} />}
                    <span className="min-w-0 flex-1 truncate text-[12px] text-foreground">
                      {channel?.name ?? target.channelId}
                    </span>
                    <span
                      className={`shrink-0 text-[11px] ${
                        target.status === 'failed'
                          ? 'text-destructive'
                          : target.status === 'published'
                            ? 'text-success'
                            : 'text-muted-foreground'
                      }`}
                    >
                      {target.error ??
                        (target.status === 'published'
                          ? 'Publiée'
                          : 'En attente')}
                    </span>
                    {target.permalink && (
                      <a
                        href={target.permalink}
                        target="_blank"
                        rel="noreferrer"
                        aria-label="Ouvrir la publication"
                        className="shrink-0 text-muted-foreground transition-colors hover:text-foreground"
                      >
                        <ExternalLink className="size-3.5" />
                      </a>
                    )}
                  </li>
                )
              })}
            </ul>
          </section>

          {isSent && (
            <PostComments
              post={post}
              channels={channels}
              workspaceId={workspaceId}
            />
          )}

          {error && (
            <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
              {error}
            </p>
          )}
        </div>

        <footer className="flex shrink-0 items-center justify-between gap-2 border-t border-border p-4">
          {post.status !== 'published' && post.status !== 'partial' ? (
            <button
              type="button"
              disabled={isBusy}
              onClick={() => void run('cancel')}
              className="h-9 rounded-lg border border-border px-3 text-[13px] text-muted-foreground transition-colors hover:bg-muted disabled:opacity-40"
            >
              Dépublier en brouillon
            </button>
          ) : (
            <span />
          )}

          <div className="flex items-center gap-2">
            {failed > 0 && (
              <button
                type="button"
                disabled={isBusy}
                onClick={() => void run('retry')}
                className="flex h-9 items-center gap-1.5 rounded-lg border border-border px-3 text-[13px] text-foreground transition-colors hover:bg-muted disabled:opacity-40"
              >
                <RotateCw className="size-4" />
                Relancer les échecs
              </button>
            )}
            {!isSent && (
              <button
                type="button"
                disabled={isBusy}
                onClick={() => void run('publish')}
                className="h-9 rounded-lg bg-primary px-3.5 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-40"
              >
                Publier maintenant
              </button>
            )}
          </div>
        </footer>
      </aside>
    </div>
  )
}
