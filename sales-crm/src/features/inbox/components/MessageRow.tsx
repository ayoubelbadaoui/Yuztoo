import { CornerUpLeft, UserPlus } from 'lucide-react'

import { SourceBadge } from '@/features/inbox/components/SourceBadge'
import type { InboxMessage } from '@/features/inbox/domain/message'
import { formatTime, isUnread } from '@/features/inbox/domain/message'

type Props = {
  message: InboxMessage
  isSelected: boolean
  onSelect: () => void
}

export function MessageRow({ message, isSelected, onSelect }: Props) {
  const unread = isUnread(message)

  return (
    <button
      type="button"
      onClick={onSelect}
      aria-current={isSelected}
      className={`flex w-full gap-2.5 rounded-lg px-2.5 py-2 text-left transition-colors ${
        isSelected ? 'bg-accent' : 'hover:bg-muted/60'
      }`}
    >
      <span
        aria-hidden
        className={`mt-1.5 size-1.5 shrink-0 rounded-full ${unread ? 'bg-primary' : 'bg-transparent'}`}
      />

      <span className="min-w-0 flex-1">
        <span className="flex items-center gap-2">
          <span
            className={`min-w-0 flex-1 truncate text-[13px] ${
              unread
                ? 'font-semibold text-foreground'
                : 'font-medium text-muted-foreground'
            }`}
          >
            {message.senderName}
          </span>
          <SourceBadge source={message.source} iconOnly />
          <span className="shrink-0 text-[11px] tabular-nums text-muted-foreground">
            {formatTime(message.receivedAt)}
          </span>
        </span>

        <span
          className={`mt-0.5 block truncate text-[13px] ${unread ? 'text-foreground' : 'text-muted-foreground'}`}
        >
          {message.subject}
        </span>

        <span className="mt-0.5 flex items-center gap-2">
          <span className="min-w-0 flex-1 truncate text-[12px] text-muted-foreground">
            {message.company ?? message.senderEmail}
          </span>
          {message.replies.length > 0 && (
            <CornerUpLeft className="size-3 shrink-0 text-success" />
          )}
          {message.leadId && (
            <UserPlus className="size-3 shrink-0 text-primary" />
          )}
        </span>
      </span>
    </button>
  )
}
