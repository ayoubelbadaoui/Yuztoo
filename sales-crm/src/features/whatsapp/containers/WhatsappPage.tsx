import { MessagesSquare } from 'lucide-react'

import { ChatThread } from '@/features/whatsapp/components/ChatThread'
import { ConversationList } from '@/features/whatsapp/components/ConversationList'
import {
  useTemplates,
  useWhatsapp,
} from '@/features/whatsapp/hooks/useWhatsapp'

export function WhatsappPage() {
  const {
    filter,
    setFilter,
    search,
    setSearch,
    conversations,
    counts,
    selected,
    messages,
    select,
    refreshThread,
  } = useWhatsapp()
  const { templates } = useTemplates()

  return (
    <div className="flex h-full min-h-0 flex-col gap-4">
      <header className="flex shrink-0 flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          WhatsApp
        </h1>
        <p className="text-[13px] text-muted-foreground">
          Conversations de l’API WhatsApp Business, rattachées aux leads.
        </p>
      </header>

      <div className="flex min-h-0 flex-1 gap-4">
        <ConversationList
          conversations={conversations}
          counts={counts}
          filter={filter}
          onFilter={setFilter}
          search={search}
          onSearch={setSearch}
          selectedId={selected?.id ?? null}
          onSelect={(id) => void select(id)}
        />

        {selected ? (
          <ChatThread
            conversation={selected}
            messages={messages}
            templates={templates}
            onSent={() => void refreshThread()}
          />
        ) : (
          <section className="flex min-w-0 flex-1 flex-col items-center justify-center gap-2 rounded-xl border border-border bg-card p-8 text-center">
            <MessagesSquare
              className="size-6 text-muted-foreground"
              strokeWidth={1.5}
            />
            <p className="text-[13px] text-muted-foreground">
              Choisissez une conversation pour répondre.
            </p>
          </section>
        )}
      </div>
    </div>
  )
}
