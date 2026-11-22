import type { MediaTestAccount } from '@/features/cms-app/domain/mediaRelease'
import type { YuztooNews } from '@/features/cms-app/domain/yuztooNews'
import {
  canActivateNewsPreview,
  canPublishNewsLive,
  yuztooNewsReleaseLabels,
} from '@/features/cms-app/domain/yuztooNews'

type Props = {
  news: YuztooNews
  accounts: MediaTestAccount[]
  search: string
  onSearch: (value: string) => void
  isBusy: boolean
  onSelectAccount: (account: MediaTestAccount | null) => Promise<string | null>
  onActivatePreview: () => Promise<string | null>
  onPublishLive: () => Promise<string | null>
  onRevertToDraft: () => Promise<string | null>
}

export function YuztooNewsReleaseSection({
  news,
  accounts,
  search,
  onSearch,
  isBusy,
  onSelectAccount,
  onActivatePreview,
  onPublishLive,
  onRevertToDraft,
}: Props) {
  const status = news.release_status
  const statusLabel = yuztooNewsReleaseLabels[status]

  return (
    <section className="flex flex-col gap-3 rounded-xl border border-border bg-muted/30 p-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div>
          <p className="text-[13px] font-semibold text-card-foreground">
            Publication
          </p>
          <p className="text-[11px] text-muted-foreground">
            Compte test obligatoire → aperçu → tous les utilisateurs.
          </p>
        </div>
        <span
          className={`rounded-md px-2 py-1 text-[11px] font-semibold ${
            status === 'live'
              ? 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400'
              : status === 'preview'
                ? 'bg-primary/15 text-primary'
                : 'bg-muted text-muted-foreground'
          }`}
        >
          {statusLabel}
        </span>
      </div>

      {news.test_account_label ? (
        <p className="text-[12px] text-foreground">
          Compte test · <span className="font-medium">{news.test_account_label}</span>
        </p>
      ) : (
        <p className="text-[12px] text-amber-700 dark:text-amber-400">
          Aucun compte test — mise en ligne bloquée.
        </p>
      )}

      {status !== 'live' && (
        <>
          <input
            type="search"
            value={search}
            onChange={(event) => onSearch(event.target.value)}
            placeholder="Rechercher un client ou une boutique…"
            disabled={isBusy}
            className="h-9 rounded-lg border border-input bg-background px-3 text-[13px] outline-none placeholder:text-muted-foreground focus:border-ring focus:ring-1 focus:ring-ring"
          />
          <div className="max-h-36 overflow-y-auto rounded-lg border border-border bg-background">
            {accounts.length === 0 ? (
              <p className="p-3 text-[12px] text-muted-foreground">
                Aucun compte trouvé.
              </p>
            ) : (
              accounts.slice(0, 30).map((account) => {
                const selected = news.test_account_id === account.id
                return (
                  <button
                    key={`${account.kind}:${account.id}`}
                    type="button"
                    disabled={isBusy}
                    onClick={() => void onSelectAccount(account)}
                    className={`flex w-full flex-col border-b border-border px-3 py-2 text-left last:border-0 disabled:opacity-50 ${
                      selected ? 'bg-primary/10' : 'hover:bg-muted/60'
                    }`}
                  >
                    <span className="text-[13px] font-medium">
                      {account.displayName}
                    </span>
                    <span className="text-[11px] text-muted-foreground">
                      {account.kind === 'client' ? 'Client' : 'Boutique'} ·{' '}
                      {account.email ?? account.id}
                    </span>
                  </button>
                )
              })
            )}
          </div>
        </>
      )}

      <div className="flex flex-wrap gap-2">
        {status === 'draft' && (
          <button
            type="button"
            disabled={isBusy || !canActivateNewsPreview(news)}
            onClick={() => void onActivatePreview()}
            className="h-9 rounded-lg bg-primary px-3 text-[13px] font-medium text-primary-foreground disabled:opacity-40"
          >
            Activer aperçu test
          </button>
        )}
        {status === 'preview' && (
          <>
            <button
              type="button"
              disabled={isBusy}
              onClick={() => void onRevertToDraft()}
              className="h-9 rounded-lg border border-border px-3 text-[13px] font-medium hover:bg-muted disabled:opacity-40"
            >
              Arrêter l’aperçu
            </button>
            <button
              type="button"
              disabled={isBusy || !canPublishNewsLive(news)}
              onClick={() => {
                const ok = window.confirm(
                  `Mettre cette actu en ligne pour TOUS ?\nCompte test : ${news.test_account_label ?? '—'}`,
                )
                if (ok) void onPublishLive()
              }}
              className="h-9 rounded-lg bg-emerald-600 px-3 text-[13px] font-medium text-white disabled:opacity-40"
            >
              Mettre en ligne pour tous
            </button>
          </>
        )}
        {status === 'live' && (
          <button
            type="button"
            disabled={isBusy}
            onClick={() => {
              const ok = window.confirm(
                'Repasser en brouillon ? L’actu disparaît pour tous jusqu’à une nouvelle publication.',
              )
              if (ok) void onRevertToDraft()
            }}
            className="h-9 rounded-lg border border-border px-3 text-[13px] font-medium hover:bg-muted disabled:opacity-40"
          >
            Repasser en brouillon
          </button>
        )}
      </div>
    </section>
  )
}
