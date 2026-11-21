import { Archive, Check, Link2, Mail, MapPin, Phone, UserPlus } from 'lucide-react'
import { useState } from 'react'

import { Badge } from '@/components/ui/Badge'
import { ReplyBox } from '@/features/inbox/components/ReplyBox'
import { SourceBadge } from '@/features/inbox/components/SourceBadge'
import type { InboxMessage } from '@/features/inbox/domain/message'
import {
  formatTime,
  messageStatusLabels,
  relativeTime,
} from '@/features/inbox/domain/message'
import {
  convertToLead,
  setMessageStatus,
} from '@/features/inbox/services/inboxService'

type Props = {
  message: InboxMessage
  onChanged: () => void
}

const actionButton =
  'flex h-8 items-center gap-1.5 rounded-lg border border-border px-2.5 text-[12px] text-foreground transition-colors hover:bg-muted disabled:opacity-40'

export function MessageView({ message, onChanged }: Props) {
  const [isBusy, setIsBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const run = async (action: 'lead' | 'handled' | 'archive') => {
    setIsBusy(true)
    const { error: failure } =
      action === 'lead'
        ? await convertToLead(message.id)
        : await setMessageStatus(
            message.id,
            action === 'handled' ? 'handled' : 'archived',
          )
    setIsBusy(false)

    if (failure) {
      setError(failure.message)
      return
    }
    onChanged()
  }

  const facts = [
    { icon: Mail, value: message.senderEmail },
    { icon: Phone, value: message.senderPhone },
    {
      icon: MapPin,
      value: [message.company, message.city].filter(Boolean).join(' · ') || null,
    },
    { icon: Link2, value: message.pageUrl && `yuztoo.fr${message.pageUrl}` },
  ].filter((fact) => Boolean(fact.value))

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <header className="flex shrink-0 flex-col gap-3 border-b border-border p-4">
        <div className="flex flex-wrap items-start justify-between gap-2">
          <div className="min-w-0">
            <h2 className="text-[15px] font-semibold text-card-foreground">
              {message.subject}
            </h2>
            <p className="mt-0.5 text-[12px] text-muted-foreground">
              {`${message.senderName} · ${formatTime(message.receivedAt)} · ${relativeTime(message.receivedAt)}`}
            </p>
          </div>

          <div className="flex shrink-0 items-center gap-1.5">
            <SourceBadge source={message.source} />
            <Badge tone={message.status === 'handled' ? 'success' : 'neutral'}>
              {messageStatusLabels[message.status]}
            </Badge>
          </div>
        </div>

        <ul className="flex flex-wrap gap-x-4 gap-y-1">
          {facts.map(({ icon: Icon, value }) => (
            <li
              key={String(value)}
              className="flex items-center gap-1.5 text-[12px] text-muted-foreground"
            >
              <Icon className="size-3.5 shrink-0" />
              {value}
            </li>
          ))}
        </ul>

        <div className="flex flex-wrap items-center gap-1.5">
          <button
            type="button"
            disabled={isBusy || Boolean(message.leadId)}
            onClick={() => void run('lead')}
            className={actionButton}
          >
            <UserPlus className="size-3.5" />
            {message.leadId ? `Lead ${message.leadId}` : 'Créer le lead'}
          </button>

          <button
            type="button"
            disabled={isBusy || message.status === 'handled'}
            onClick={() => void run('handled')}
            className={actionButton}
          >
            <Check className="size-3.5" />
            Marquer traité
          </button>

          <button
            type="button"
            disabled={isBusy || message.status === 'archived'}
            onClick={() => void run('archive')}
            className={actionButton}
          >
            <Archive className="size-3.5" />
            Archiver
          </button>
        </div>

        {error && (
          <p className="text-[12px] text-destructive">{error}</p>
        )}
      </header>

      <div className="scrollbar-none flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto p-4">
        <p className="whitespace-pre-line text-[13px] leading-relaxed text-foreground">
          {message.body}
        </p>

        {message.replies.map((reply) => (
          <div
            key={reply.id}
            className="rounded-xl border border-border bg-muted/40 p-3"
          >
            <p className="text-[12px] font-medium text-foreground">
              {`${reply.author} · ${relativeTime(reply.sentAt)}`}
            </p>
            <p className="mt-1 whitespace-pre-line text-[13px] leading-relaxed text-muted-foreground">
              {reply.body}
            </p>
          </div>
        ))}
      </div>

      <ReplyBox message={message} onSent={onChanged} />
    </div>
  )
}
