import { Inbox as InboxIcon } from 'lucide-react'

import { InboxToolbar } from '@/features/inbox/components/InboxToolbar'
import { MessageList } from '@/features/inbox/components/MessageList'
import { MessageView } from '@/features/inbox/components/MessageView'
import { useInbox } from '@/features/inbox/hooks/useInbox'

export function InboxPage() {
  const {
    filter,
    setFilter,
    search,
    setSearch,
    messages,
    counts,
    selected,
    select,
    error,
    isLoading,
    reload,
  } = useInbox()

  return (
    <div className="flex h-full min-h-0 flex-col gap-4">
      <header className="flex shrink-0 flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Inbox
        </h1>
        <p className="text-[13px] text-muted-foreground">
          {counts
            ? `${counts.new} message${counts.new > 1 ? 's' : ''} non lu${counts.new > 1 ? 's' : ''} · demandes reçues depuis yuztoo.fr`
            : 'Demandes reçues depuis yuztoo.fr'}
        </p>
      </header>

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
          Impossible de charger la boîte de réception.
        </div>
      )}

      {!error && (
        <div className="flex min-h-0 flex-1 gap-4">
          <section className="flex w-[22rem] shrink-0 flex-col overflow-hidden rounded-xl border border-border bg-card">
            <InboxToolbar
              filter={filter}
              onFilter={setFilter}
              search={search}
              onSearch={setSearch}
              counts={counts}
            />

            {isLoading ? (
              <div className="flex flex-col gap-2 p-3">
                {[0, 1, 2, 3, 4].map((index) => (
                  <div
                    key={index}
                    className="h-14 animate-pulse rounded-lg bg-muted"
                  />
                ))}
              </div>
            ) : (
              <MessageList
                messages={messages}
                selectedId={selected?.id ?? null}
                onSelect={(id) => void select(id)}
              />
            )}
          </section>

          <section className="flex min-w-0 flex-1 flex-col overflow-hidden rounded-xl border border-border bg-card">
            {selected ? (
              <MessageView message={selected} onChanged={() => void reload()} />
            ) : (
              <div className="flex flex-1 flex-col items-center justify-center gap-2 p-8 text-center">
                <InboxIcon
                  className="size-6 text-muted-foreground"
                  strokeWidth={1.5}
                />
                <p className="text-[13px] text-muted-foreground">
                  Sélectionnez un message pour le lire et répondre.
                </p>
              </div>
            )}
          </section>
        </div>
      )}
    </div>
  )
}
