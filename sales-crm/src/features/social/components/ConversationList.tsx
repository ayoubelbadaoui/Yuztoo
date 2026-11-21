import type { SocialConversation } from '@/features/social/domain/conversation'
import { platformLabel } from '@/features/social/domain/conversation'

type Props = {
  conversations: SocialConversation[]
  selectedId: string | null
  onSelect: (id: string) => void
}

function formatTime(iso: string): string {
  return new Date(iso).toLocaleString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export function ConversationList({
  conversations,
  selectedId,
  onSelect,
}: Props) {
  if (conversations.length === 0) {
    return (
      <p className="p-4 text-[13px] text-muted-foreground">
        Aucune conversation pour l’instant. Envoyez un message à la Page depuis
        Messenger ou Instagram pour la voir apparaître ici.
      </p>
    )
  }

  return (
    <ul className="flex flex-col gap-1 overflow-y-auto p-2">
      {conversations.map((conversation) => (
        <li key={conversation.id}>
          <button
            type="button"
            onClick={() => onSelect(conversation.id)}
            aria-current={conversation.id === selectedId}
            className={`flex w-full flex-col gap-0.5 rounded-lg px-2.5 py-2 text-left transition-colors ${
              conversation.id === selectedId ? 'bg-accent' : 'hover:bg-muted/60'
            }`}
          >
            <span className="flex items-center gap-2">
              <span
                className={`min-w-0 flex-1 truncate text-[13px] ${
                  conversation.unread > 0
                    ? 'font-semibold text-foreground'
                    : 'font-medium text-muted-foreground'
                }`}
              >
                {conversation.peerName}
              </span>
              <span className="shrink-0 text-[11px] tabular-nums text-muted-foreground">
                {formatTime(conversation.lastMessageAt)}
              </span>
            </span>
            <span className="truncate text-[12px] text-muted-foreground">
              {platformLabel(conversation.platform)} ·{' '}
              {conversation.channelName}
            </span>
          </button>
        </li>
      ))}
    </ul>
  )
}
