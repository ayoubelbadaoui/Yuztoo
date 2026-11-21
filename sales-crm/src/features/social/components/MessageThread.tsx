import type { SocialMessage } from '@/features/social/domain/conversation'

type Props = {
  messages: SocialMessage[]
}

const statusLabels: Record<SocialMessage['status'], string> = {
  queued: 'envoi…',
  sent: 'envoyé',
  delivered: 'remis',
  read: 'lu',
  failed: 'échec',
}

export function MessageThread({ messages }: Props) {
  if (messages.length === 0) {
    return (
      <p className="flex-1 p-4 text-[13px] text-muted-foreground">
        Aucun message dans cette conversation.
      </p>
    )
  }

  return (
    <div className="flex flex-1 flex-col gap-2 overflow-y-auto p-4">
      {messages.map((message) => (
        <div
          key={message.id}
          className={`max-w-[80%] rounded-xl px-3 py-2 text-[13px] ${
            message.direction === 'out'
              ? 'self-end bg-primary text-primary-foreground'
              : 'self-start bg-muted text-foreground'
          }`}
        >
          <p className="whitespace-pre-wrap break-words">{message.body}</p>
          <p
            className={`mt-1 text-[11px] ${
              message.direction === 'out'
                ? 'text-primary-foreground/70'
                : 'text-muted-foreground'
            }`}
          >
            {new Date(message.sentAt).toLocaleTimeString('fr-FR', {
              hour: '2-digit',
              minute: '2-digit',
            })}
            {message.direction === 'out' && ` · ${statusLabels[message.status]}`}
          </p>
        </div>
      ))}
    </div>
  )
}
