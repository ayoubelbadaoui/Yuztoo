import { Search } from 'lucide-react'

import type { WaConversation } from '@/features/whatsapp/domain/conversation'
import {
  formatMessageTime,
  isWindowOpen,
} from '@/features/whatsapp/domain/conversation'
import type { ConversationFilter } from '@/features/whatsapp/services/whatsappService'

const filters: ConversationFilter[] = [
  'all',
  'unread',
  'window-open',
  'window-closed',
]

const filterLabels: Record<ConversationFilter, string> = {
  all: 'Toutes',
  unread: 'Non lues',
  'window-open': 'Fenêtre ouverte',
  'window-closed': 'Fenêtre fermée',
}

type Props = {
  conversations: WaConversation[]
  counts: Record<ConversationFilter, number> | null
  filter: ConversationFilter
  onFilter: (filter: ConversationFilter) => void
  search: string
  onSearch: (search: string) => void
  selectedId: string | null
  onSelect: (id: string) => void
}

export function ConversationList({
  conversations,
  counts,
  filter,
  onFilter,
  search,
  onSearch,
  selectedId,
  onSelect,
}: Props) {
  return (
    <section className="flex w-[21rem] shrink-0 flex-col overflow-hidden rounded-xl border border-border bg-card">
      <div className="flex shrink-0 flex-col gap-2 border-b border-border p-2.5">
        <div className="flex h-9 items-center gap-2 rounded-lg border border-input bg-background px-2.5">
          <Search className="size-3.5 shrink-0 text-muted-foreground" />
          <input
            value={search}
            onChange={(event) => onSearch(event.target.value)}
            placeholder="Rechercher un contact"
            aria-label="Rechercher une conversation"
            className="w-full bg-transparent text-[13px] text-foreground outline-none placeholder:text-muted-foreground"
          />
        </div>

        <div className="flex flex-wrap gap-1">
          {filters.map((option) => (
            <button
              key={option}
              type="button"
              onClick={() => onFilter(option)}
              className={`flex h-7 items-center gap-1.5 rounded-full px-2.5 text-[12px] transition-colors ${
                filter === option
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-muted'
              }`}
            >
              {filterLabels[option]}
              {counts && (
                <span className="text-[11px] tabular-nums opacity-70">
                  {counts[option]}
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      <ul className="scrollbar-none flex min-h-0 flex-1 flex-col gap-0.5 overflow-y-auto p-1.5">
        {conversations.length === 0 && (
          <li className="p-6 text-center text-[13px] text-muted-foreground">
            Aucune conversation.
          </li>
        )}

        {conversations.map((conversation) => {
          const open = isWindowOpen(conversation)
          return (
            <li key={conversation.id}>
              <button
                type="button"
                onClick={() => onSelect(conversation.id)}
                aria-current={conversation.id === selectedId}
                className={`flex w-full items-start gap-2.5 rounded-lg px-2.5 py-2 text-left transition-colors ${
                  conversation.id === selectedId
                    ? 'bg-accent'
                    : 'hover:bg-muted/60'
                }`}
              >
                <span
                  className={`mt-1 size-7 shrink-0 rounded-full text-center text-[11px] font-medium leading-7 ${
                    open
                      ? 'bg-success/15 text-success'
                      : 'bg-muted text-muted-foreground'
                  }`}
                >
                  {conversation.contactName.slice(0, 2).toUpperCase()}
                </span>

                <span className="min-w-0 flex-1">
                  <span className="flex items-center gap-2">
                    <span className="min-w-0 flex-1 truncate text-[13px] font-medium text-foreground">
                      {conversation.contactName}
                    </span>
                    <span className="shrink-0 text-[11px] tabular-nums text-muted-foreground">
                      {formatMessageTime(conversation.lastMessageAt)}
                    </span>
                  </span>

                  <span className="mt-0.5 flex items-center gap-2">
                    <span className="min-w-0 flex-1 truncate text-[12px] text-muted-foreground">
                      {conversation.company ?? conversation.phone}
                    </span>
                    {conversation.unread > 0 && (
                      <span className="flex h-4 min-w-4 shrink-0 items-center justify-center rounded-full bg-primary px-1 text-[10px] font-medium text-primary-foreground">
                        {conversation.unread}
                      </span>
                    )}
                  </span>
                </span>
              </button>
            </li>
          )
        })}
      </ul>
    </section>
  )
}
