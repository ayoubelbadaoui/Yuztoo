import { Check, CheckCheck, FileText, TriangleAlert } from 'lucide-react'

import type { WaMessage } from '@/features/whatsapp/domain/conversation'
import {
  formatMessageTime,
  messageStatusLabels,
} from '@/features/whatsapp/domain/conversation'

/** Coche simple à l'envoi, double à la distribution, double colorée à la lecture. */
function StatusIcon({ message }: { message: WaMessage }) {
  if (message.status === 'failed') {
    return <TriangleAlert className="size-3 text-destructive" />
  }
  if (message.status === 'sent') return <Check className="size-3" />
  return (
    <CheckCheck
      className={`size-3 ${message.status === 'read' ? 'text-primary' : ''}`}
    />
  )
}

export function MessageBubble({ message }: { message: WaMessage }) {
  const isOut = message.direction === 'out'

  return (
    <li className={`flex flex-col ${isOut ? 'items-end' : 'items-start'}`}>
      <div
        className={`max-w-[78%] rounded-2xl px-3 py-2 ${
          isOut
            ? 'rounded-br-sm bg-primary/15 text-foreground'
            : 'rounded-bl-sm bg-muted text-foreground'
        }`}
      >
        {message.kind === 'template' && (
          <p className="mb-1 flex items-center gap-1 text-[10px] uppercase tracking-wide text-muted-foreground">
            <FileText className="size-3" />
            {`Modèle ${message.templateName}`}
          </p>
        )}

        <p className="whitespace-pre-line text-[13px] leading-relaxed">
          {message.body}
        </p>

        {message.buttons.length > 0 && (
          <div className="mt-2 flex flex-wrap gap-1 border-t border-border/60 pt-2">
            {message.buttons.map((button) => (
              <span
                key={button}
                className="rounded-md border border-border px-2 py-0.5 text-[11px] text-muted-foreground"
              >
                {button}
              </span>
            ))}
          </div>
        )}
      </div>

      <span className="mt-0.5 flex items-center gap-1 px-1 text-[10px] text-muted-foreground">
        {formatMessageTime(message.sentAt)}
        {isOut && (
          <>
            <StatusIcon message={message} />
            <span className="sr-only">
              {messageStatusLabels[message.status]}
            </span>
          </>
        )}
      </span>
    </li>
  )
}
