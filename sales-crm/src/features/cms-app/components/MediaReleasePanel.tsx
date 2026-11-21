import type { MediaRelease, MediaTestAccount } from '@/features/cms-app/domain/mediaRelease'
import {
  canActivatePreview,
  canPublishLive,
  mediaReleaseStatusLabels,
} from '@/features/cms-app/domain/mediaRelease'

type Props = {
  release: MediaRelease | null
  accounts: MediaTestAccount[]
  search: string
  onSearch: (value: string) => void
  isLoading: boolean
  isBusy: boolean
  error: string | null
  onSelectAccount: (account: MediaTestAccount | null) => Promise<string | null>
  onActivatePreview: () => Promise<string | null>
  onStopPreview: () => Promise<string | null>
  onPublishLive: () => Promise<string | null>
  onRevertToDraft: () => Promise<string | null>
}

export function MediaReleasePanel({
  release,
  accounts,
  search,
  onSearch,
  isLoading,
  isBusy,
  error,
  onSelectAccount,
  onActivatePreview,
  onStopPreview,
  onPublishLive,
  onRevertToDraft,
}: Props) {
  const status = release?.status ?? 'draft'
  const statusLabel = mediaReleaseStatusLabels[status]
  const publishReady = release ? canPublishLive(release) : false
  const previewReady = release ? canActivatePreview(release) : false

  return (
    <section className="flex flex-col gap-3 rounded-xl border border-border bg-card p-4">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-[14px] font-semibold text-card-foreground">
            Publication
          </h2>
          <p className="mt-1 text-[12px] text-muted-foreground">
            Obligatoire : choisir un compte test, activer l’aperçu, puis
            seulement mettre en ligne pour tous.
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

      {release?.testAccountLabel ? (
        <p className="text-[13px] text-card-foreground">
          Compte test ·{' '}
          <span className="font-medium">{release.testAccountLabel}</span>
          <span className="text-muted-foreground"> · {release.testAccountId}</span>
        </p>
      ) : (
        <p className="text-[13px] text-amber-700 dark:text-amber-400">
          Aucun compte test sélectionné — publication bloquée.
        </p>
      )}

      {status !== 'live' && (
        <div className="flex flex-col gap-2">
          <input
            type="search"
            value={search}
            onChange={(event) => onSearch(event.target.value)}
            placeholder="Rechercher un client ou une boutique…"
            disabled={isBusy}
            className="h-9 rounded-lg border border-input bg-background px-3 text-[13px] text-foreground outline-none placeholder:text-muted-foreground focus:border-ring focus:ring-1 focus:ring-ring"
          />
          <div className="max-h-40 overflow-y-auto rounded-lg border border-border">
            {isLoading ? (
              <p className="p-3 text-[12px] text-muted-foreground">Chargement…</p>
            ) : accounts.length === 0 ? (
              <p className="p-3 text-[12px] text-muted-foreground">
                Aucun compte trouvé.
              </p>
            ) : (
              accounts.slice(0, 40).map((account) => {
                const selected = release?.testAccountId === account.id
                return (
                  <button
                    key={`${account.kind}:${account.id}`}
                    type="button"
                    disabled={isBusy}
                    onClick={() => void onSelectAccount(account)}
                    className={`flex w-full flex-col border-b border-border px-3 py-2 text-left last:border-0 transition-colors disabled:opacity-50 ${
                      selected
                        ? 'bg-primary/10'
                        : 'hover:bg-muted/60'
                    }`}
                  >
                    <span className="text-[13px] font-medium text-foreground">
                      {account.displayName}
                    </span>
                    <span className="text-[11px] text-muted-foreground">
                      {account.kind === 'client' ? 'Client' : 'Boutique'} ·{' '}
                      {account.email ?? account.id} · {account.city}
                    </span>
                  </button>
                )
              })
            )}
          </div>
          {release?.testAccountId && (
            <button
              type="button"
              disabled={isBusy}
              onClick={() => void onSelectAccount(null)}
              className="self-start text-[12px] text-muted-foreground underline-offset-2 hover:underline"
            >
              Effacer la sélection
            </button>
          )}
        </div>
      )}

      <div className="flex flex-wrap gap-2">
        {status !== 'live' && status !== 'preview' && (
          <button
            type="button"
            disabled={isBusy || !previewReady}
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
              onClick={() => void onStopPreview()}
              className="h-9 rounded-lg border border-border px-3 text-[13px] font-medium hover:bg-muted disabled:opacity-40"
            >
              Arrêter l’aperçu
            </button>
            <button
              type="button"
              disabled={isBusy || !publishReady}
              onClick={() => {
                const ok = window.confirm(
                  `Mettre les images en ligne pour TOUS les utilisateurs ?\nCompte test vérifié : ${release?.testAccountLabel ?? '—'}`,
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
                'Repasser en brouillon ? Les utilisateurs reviendront aux images par défaut (bundle) jusqu’à une nouvelle publication.',
              )
              if (ok) void onRevertToDraft()
            }}
            className="h-9 rounded-lg border border-border px-3 text-[13px] font-medium hover:bg-muted disabled:opacity-40"
          >
            Repasser en brouillon
          </button>
        )}
      </div>

      {error && (
        <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
          {error}
        </p>
      )}

      <ol className="list-decimal space-y-1 pl-4 text-[11px] text-muted-foreground">
        <li>Éditer les images (brouillon).</li>
        <li>Sélectionner un compte test.</li>
        <li>Activer l’aperçu — seul ce compte doit voir les nouveautés (après branchement Flutter).</li>
        <li>Mettre en ligne pour tous — impossible sans l’étape 3.</li>
      </ol>
    </section>
  )
}
