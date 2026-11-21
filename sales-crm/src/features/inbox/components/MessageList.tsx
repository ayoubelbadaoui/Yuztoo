import { MessageRow } from '@/features/inbox/components/MessageRow'
import type { InboxMessage } from '@/features/inbox/domain/message'
import { groupByDay } from '@/features/inbox/domain/message'

type Props = {
  messages: InboxMessage[]
  selectedId: string | null
  onSelect: (id: string) => void
}

export function MessageList({ messages, selectedId, onSelect }: Props) {
  if (messages.length === 0) {
    return (
      <div className="flex flex-1 items-center justify-center p-8 text-center">
        <p className="text-[13px] text-muted-foreground">
          Rien à traiter ici.
        </p>
      </div>
    )
  }

  return (
    <div className="scrollbar-none flex min-h-0 flex-1 flex-col overflow-y-auto p-1.5">
      {groupByDay(messages).map((group) => (
        <section key={group.key} className="flex flex-col">
          <h3 className="sticky top-0 z-10 bg-card/95 px-2.5 py-1.5 text-[11px] font-semibold uppercase tracking-wide text-muted-foreground backdrop-blur">
            {group.label}
          </h3>

          {group.messages.map((message) => (
            <MessageRow
              key={message.id}
              message={message}
              isSelected={message.id === selectedId}
              onSelect={() => onSelect(message.id)}
            />
          ))}
        </section>
      ))}
    </div>
  )
}
