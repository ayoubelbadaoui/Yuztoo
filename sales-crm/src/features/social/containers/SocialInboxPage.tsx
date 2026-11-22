import { History, MessagesSquare } from 'lucide-react'
import { useState } from 'react'

import { ConversationList } from '@/features/social/components/ConversationList'
import { MessageThread } from '@/features/social/components/MessageThread'
import { PlatformTabs } from '@/features/social/components/PlatformTabs'
import { ReplyComposer } from '@/features/social/components/ReplyComposer'
import type { PlatformFilter } from '@/features/social/domain/conversation'
import { platformLabel, replyWindow } from '@/features/social/domain/conversation'
import { useHistoryImport } from '@/features/social/hooks/useHistoryImport'
import { useSocialInbox } from '@/features/social/hooks/useSocialInbox'

const emptyLabels: Record<PlatformFilter, string> = {
  all: 'Aucune conversation. Importez l’historique ou attendez un nouveau message Messenger / Instagram.',
  instagram: 'Aucune conversation Instagram pour l’instant.',
  messenger: 'Aucune conversation Facebook pour l’instant.',
}

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
    reload,
  } = useSocialInbox()
  const [platform, setPlatform] = useState<PlatformFilter>('all')
  const history = useHistoryImport(() => void reload())
  const visible =
    platform === 'all'
      ? conversations
      : conversations.filter((conversation) => conversation.platform === platform)

  const window = replyWindow(selected?.lastInboundAt ?? null)

  return (
    <div className="flex h-full min-h-0 flex-col gap-4">
      <header className="flex shrink-0 flex-wrap items-start justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold tracking-tight text-foreground">
            Messages Meta
          </h1>
          <p className="text-[13px] text-muted-foreground">
            Conversations Instagram et Facebook des comptes connectés.
          </p>
        </div>
        <div className="flex flex-col items-end gap-1">
          <button
            type="button"
            disabled={history.isImporting}
            onClick={() => void history.run()}
            className="flex h-9 items-center gap-1.5 rounded-lg border border-border px-3 text-[13px] font-medium hover:bg-muted disabled:opacity-50"
          >
            <History className="size-4" />
            {history.isImporting ? 'Import en cours…' : 'Importer l’historique'}
          </button>
          <p className="max-w-xs text-right text-[11px] text-muted-foreground">
            {history.progress
              ? `${history.progress.channelName} · ${history.progress.conversations} conversations · ${history.progress.imported} messages`
              : (history.summary ??
                'Meta fournit les 20 derniers messages de chaque conversation.')}
          </p>
        </div>
      </header>

      {history.error && (
        <div className="rounded-xl border border-amber-500/30 bg-amber-500/10 p-3 text-[12px] text-amber-800 dark:text-amber-300">
          Import partiel — {history.error}
        </div>
      )}

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
          {error.message}
        </div>
      )}

      <div className="flex min-h-0 flex-1 gap-4">
        <section className="flex w-[22rem] shrink-0 flex-col overflow-hidden rounded-xl border border-border bg-card">
          <PlatformTabs
            conversations={conversations}
            value={platform}
            onChange={setPlatform}
          />
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
              conversations={visible}
              emptyLabel={emptyLabels[platform]}
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
