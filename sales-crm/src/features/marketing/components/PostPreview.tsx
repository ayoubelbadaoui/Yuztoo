import { Heart, MessageCircle, Send } from 'lucide-react'

import type { Channel } from '@/features/marketing/domain/channel'
import {
  channelKindLabels,
  networkMixLabel,
} from '@/features/marketing/domain/channel'
import type { PostFormat } from '@/features/marketing/domain/post'

type Props = {
  format: PostFormat
  caption: string
  mediaLabel: string | null
  mediaUrl?: string | null
  /** Un ou plusieurs comptes — l’aperçu reste indicatif. */
  channels: Channel[]
}

/** Aperçu indicatif : montrer la coupe du texte vaut mieux qu'un rendu exact. */
export function PostPreview({
  format,
  caption,
  mediaLabel,
  mediaUrl,
  channels,
}: Props) {
  const primary = channels[0] ?? null
  const name = primary?.name ?? 'Yuztoo'
  const handle = primary?.handle ?? 'yuztoo_fr'
  const text = caption.trim() || 'Votre texte apparaîtra ici.'
  const mix = channels.length > 0 ? networkMixLabel(channels) : null

  if (format === 'story') {
    return (
      <div className="mx-auto flex aspect-[9/16] w-40 flex-col justify-between overflow-hidden rounded-xl border border-border bg-gradient-to-b from-primary/25 to-foreground/80 p-2.5">
        <div className="flex items-center gap-1.5">
          <span className="size-5 rounded-full border border-background/60 bg-background/30" />
          <span className="truncate text-[10px] font-medium text-background">
            {handle}
          </span>
        </div>

        <p className="line-clamp-4 rounded-md bg-foreground/50 p-1.5 text-[10px] leading-snug text-background">
          {text}
        </p>
      </div>
    )
  }

  return (
    <div className="overflow-hidden rounded-xl border border-border bg-card">
      <div className="flex items-center gap-2 p-2.5">
        <span className="size-7 rounded-full bg-primary/15" />
        <div className="min-w-0">
          <p className="truncate text-[12px] font-medium text-card-foreground">
            {name}
          </p>
          <p className="truncate text-[10px] text-muted-foreground">
            {mix ?? 'Sponsorisé'} · à l’instant
          </p>
        </div>
      </div>

      {channels.length > 1 && (
        <div className="flex flex-wrap gap-1 px-2.5 pb-2">
          {channels.map((channel) => (
            <span
              key={channel.id}
              className="rounded-full border border-border px-2 py-0.5 text-[10px] text-muted-foreground"
            >
              {channelKindLabels[channel.kind]}
            </span>
          ))}
        </div>
      )}

      <p className="whitespace-pre-line px-2.5 pb-2 text-[12px] leading-relaxed text-card-foreground">
        {text}
      </p>

      <div className="flex aspect-[4/3] items-center justify-center overflow-hidden border-y border-border bg-muted">
        {mediaUrl ? (
          <img
            src={mediaUrl}
            alt={mediaLabel ?? 'Visuel'}
            className="size-full object-cover"
          />
        ) : (
          <span className="px-3 text-center text-[11px] text-muted-foreground">
            {mediaLabel ?? 'Aucun visuel joint'}
          </span>
        )}
      </div>

      <div className="flex items-center gap-4 p-2.5 text-muted-foreground">
        <Heart className="size-3.5" />
        <MessageCircle className="size-3.5" />
        <Send className="size-3.5" />
      </div>
    </div>
  )
}
