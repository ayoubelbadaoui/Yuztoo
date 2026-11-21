import { MessagesSquare } from 'lucide-react'

import { ConversationList } from '@/features/social/components/ConversationList'
import { MessageThread } from '@/features/social/components/MessageThread'
import { ReplyComposer } from '@/features/social/components/ReplyComposer'
import { platformLabel, replyWindow } from '@/features/social/domain/conversation'
import { useSocialInbox } from '@/features/social/hooks/useSocialInbox'

export function SocialInboxPage() {
  const {
    conversations,
    selected,
    messages,
    isLoading,
    isSending,
    error,
    select,
    send,
  } = useSocialInbox()

  const window = replyWindow(selected?.lastInboundAt ?? null)

  return (
    <div className="flex h-full min-h-0 flex-col gap-4">
      <header className="flex shrink-0 flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Messages Meta
        </h1>
        <p className="text-[13px] text-muted-foreground">
          Conversations Messenger et Instagram des comptes connectés.
        </p>
      </header>

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
          {error.message}
        </div>
      )}

      <div className="flex min-h-0 flex-1 gap-4">
        <section className="flex w-[22rem] shrink-0 flex-col overflow-hidden rounded-xl border border-border bg-card">
          {isLoading ? (
            <div className="flex flex-col gap-2 p-3">
              {[0, 1, 2].map((index) => (
                <div
                  key={index}
                  className="h-14 animate-pulse rounded-lg bg-muted"
                />
              ))}
            </div>
          ) : (
            <ConversationList
              conversations={conversations}
              selectedId={selected?.id ?? null}
              onSelect={(id) => void select(id)}
            />
          )}
        </section>

        <section className="flex min-w-0 flex-1 flex-col overflow-hidden rounded-xl border border-border bg-card">
          {selected ? (
            <>
              <header className="shrink-0 border-b border-border p-3">
                <p className="text-[13px] font-medium text-foreground">
                  {selected.peerName}
                </p>
                <p className="text-[12px] text-muted-foreground">
                  {platformLabel(selected.platform)} · {selected.channelName}
                </p>
              </header>
              <MessageThread messages={messages} />
              <ReplyComposer
                isOpen={window.isOpen}
                hoursLeft={window.hoursLeft}
                isSending={isSending}
                onSend={(text) => void send(text)}
              />
            </>
          ) : (
            <div className="flex flex-1 flex-col items-center justify-center gap-2 p-8 text-center">
              <MessagesSquare
                className="size-6 text-muted-foreground"
                strokeWidth={1.5}
              />
              <p className="text-[13px] text-muted-foreground">
                Sélectionnez une conversation pour lire et répondre.
              </p>
            </div>
          )}
        </section>
      </div>
    </div>
  )
}
