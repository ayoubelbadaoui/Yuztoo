import { CheckCircle2, Smartphone, UserRound, Users, X } from 'lucide-react'
import { useCallback } from 'react'

import type {
  NewsTestClient,
  YuztooNews,
} from '@/features/cms-app/domain/yuztooNews'
import {
  canActivateNewsPreview,
  canPublishNewsLive,
  yuztooNewsReleaseLabels,
} from '@/features/cms-app/domain/yuztooNews'
import { useDebouncedLookup } from '@/features/cms-app/hooks/useDebouncedLookup'
import { findActuTestClient } from '@/features/cms-app/services/yuztooNewsLookupService'

type Props = {
  news: YuztooNews
  isBusy: boolean
  /** Unsaved content edits — a test must show what will really go live. */
  isDirty: boolean
  onSelectAccount: (account: NewsTestClient | null) => Promise<string | null>
  onActivatePreview: () => Promise<string | null>
  onPublishLive: () => Promise<string | null>
  onRevertToDraft: () => Promise<string | null>
}

const badgeClass = {
  live: 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400',
  preview: 'bg-primary/15 text-primary',
  draft: 'bg-muted text-muted-foreground',
} as const

const primaryBtn =
  'h-9 rounded-lg bg-primary px-3 text-[13px] font-medium text-primary-foreground disabled:opacity-40'
const secondaryBtn =
  'h-9 rounded-lg border border-border px-3 text-[13px] font-medium hover:bg-muted disabled:opacity-40'

/** Who receives the actu: 1 test client first, then every client. */
export function YuztooNewsReleaseSection({
  news,
  isBusy,
  isDirty,
  onSelectAccount,
  onActivatePreview,
  onPublishLive,
  onRevertToDraft,
}: Props) {
  const status = news.release_status
  const locked = isBusy || isDirty

  return (
    <section className="flex flex-col gap-3 rounded-xl border border-border bg-muted/30 p-3">
      <div className="flex items-center justify-between gap-2">
        <p className="text-[13px] font-semibold text-card-foreground">
          Destinataires
        </p>
        <span
          className={`rounded-md px-2 py-1 text-[11px] font-semibold ${badgeClass[status]}`}
        >
          {yuztooNewsReleaseLabels[status]}
        </span>
      </div>

      {isDirty && status !== 'live' && (
        <p className="rounded-lg bg-amber-500/10 px-3 py-2 text-[12px] text-amber-800 dark:text-amber-300">
          Enregistrez vos modifications avant d’envoyer le test ou de publier.
        </p>
      )}

      {status === 'live' ? (
        <LiveState news={news} isBusy={isBusy} onRevertToDraft={onRevertToDraft} />
      ) : (
        <>
          <Step
            index={1}
            title="Envoyer un test à 1 client"
            done={status === 'preview'}
          >
            {news.test_account_id ? (
              <SelectedClient
                label={news.test_account_label ?? news.test_account_id}
                canChange={!locked}
                onClear={() => void onSelectAccount(null)}
              />
            ) : (
              <ClientFinder
                disabled={locked}
                onPick={(client) => void onSelectAccount(client)}
              />
            )}

            {status === 'draft' ? (
              <button
                type="button"
                disabled={locked || !canActivateNewsPreview(news)}
                onClick={() => void onActivatePreview()}
                className={`${primaryBtn} self-start`}
              >
                <Smartphone className="mr-1.5 inline size-4" />
                Envoyer le test
              </button>
            ) : (
              <div className="flex flex-wrap items-center gap-2">
                <p className="text-[12px] text-foreground">
                  Visible uniquement par ce client, dans l’app → Alertes.
                </p>
                <button
                  type="button"
                  disabled={isBusy}
                  onClick={() => void onRevertToDraft()}
                  className={secondaryBtn}
                >
                  Arrêter le test
                </button>
              </div>
            )}
          </Step>

          <Step index={2} title="Publier pour tous les clients" done={false}>
            <button
              type="button"
              disabled={locked || !canPublishNewsLive(news)}
              onClick={() => {
                const ok = window.confirm(
                  `Publier cette actu pour TOUS les clients Yuztoo ?\nTest validé sur : ${news.test_account_label ?? '—'}`,
                )
                if (ok) void onPublishLive()
              }}
              className="h-9 self-start rounded-lg bg-emerald-600 px-3 text-[13px] font-medium text-white disabled:opacity-40"
            >
              <Users className="mr-1.5 inline size-4" />
              Publier pour tous
            </button>
            {status === 'draft' && (
              <p className="text-[11px] text-muted-foreground">
                Débloqué après l’envoi du test.
              </p>
            )}
          </Step>
        </>
      )}
    </section>
  )
}

function Step({
  index,
  title,
  done,
  children,
}: {
  index: number
  title: string
  done: boolean
  children: React.ReactNode
}) {
  return (
    <div className="flex flex-col gap-2 rounded-lg border border-border bg-card p-3">
      <p className="flex items-center gap-2 text-[12.5px] font-semibold">
        {done ? (
          <CheckCircle2 className="size-4 text-emerald-600" />
        ) : (
          <span className="flex size-4 items-center justify-center rounded-full bg-muted text-[10px]">
            {index}
          </span>
        )}
        {title}
      </p>
      {children}
    </div>
  )
}

function SelectedClient({
  label,
  canChange,
  onClear,
}: {
  label: string
  canChange: boolean
  onClear: () => void
}) {
  return (
    <div className="flex items-center gap-2 rounded-lg border border-border bg-background px-3 py-2">
      <UserRound className="size-4 shrink-0 text-muted-foreground" />
      <p className="min-w-0 flex-1 truncate text-[13px] font-medium">{label}</p>
      {canChange && (
        <button
          type="button"
          onClick={onClear}
          aria-label="Changer de client test"
          className="rounded-md p-1 text-muted-foreground hover:bg-accent"
        >
          <X className="size-4" />
        </button>
      )}
    </div>
  )
}

function ClientFinder({
  disabled,
  onPick,
}: {
  disabled: boolean
  onPick: (client: NewsTestClient) => void
}) {
  const lookup = useCallback((search: string) => findActuTestClient(search), [])
  const { query, setQuery, results, isSearching, error } =
    useDebouncedLookup<NewsTestClient>(lookup, 500)
  const ready = query.trim().length >= 3

  return (
    <div className="flex flex-col gap-1.5">
      <input
        type="search"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        placeholder="Email ou téléphone du client test"
        aria-label="Rechercher le client test"
        disabled={disabled}
        className="h-9 rounded-lg border border-input bg-background px-3 text-[13px] outline-none placeholder:text-muted-foreground focus:border-ring focus:ring-1 focus:ring-ring disabled:opacity-50"
      />
      <p className="text-[11px] text-muted-foreground">
        Email complet ou numéro (06…, +33…, +212…). Utilisez votre propre compte
        client pour vérifier sur votre téléphone.
      </p>
      {ready && (
        <div className="rounded-lg border border-border bg-background">
          {isSearching ? (
            <p className="p-3 text-[12px] text-muted-foreground">Recherche…</p>
          ) : error ? (
            <p className="p-3 text-[12px] text-destructive">{error}</p>
          ) : results.length === 0 ? (
            <p className="p-3 text-[12px] text-muted-foreground">
              Aucun client avec cet email / numéro exact.
            </p>
          ) : (
            results.map((client) => (
              <button
                key={client.id}
                type="button"
                disabled={disabled}
                onClick={() => onPick(client)}
                className="flex w-full flex-col border-b border-border px-3 py-2 text-left last:border-0 hover:bg-muted/60 disabled:opacity-50"
              >
                <span className="text-[13px] font-medium">
                  {client.displayName}
                </span>
                <span className="text-[11px] text-muted-foreground">
                  {[client.contactHint, client.city].filter(Boolean).join(' · ')}
                </span>
              </button>
            ))
          )}
        </div>
      )}
    </div>
  )
}

function LiveState({
  news,
  isBusy,
  onRevertToDraft,
}: {
  news: YuztooNews
  isBusy: boolean
  onRevertToDraft: () => Promise<string | null>
}) {
  const since = news.live_at
    ? new Date(news.live_at).toLocaleString('fr-FR', {
        dateStyle: 'medium',
        timeStyle: 'short',
      })
    : null
  return (
    <div className="flex flex-col gap-2">
      <p className="text-[12px] text-foreground">
        Visible par tous les clients{since ? ` depuis le ${since}` : ''}. Toute
        modification du contenu la repasse en brouillon.
      </p>
      <button
        type="button"
        disabled={isBusy}
        onClick={() => {
          const ok = window.confirm(
            'Retirer l’actu ? Elle disparaît pour tous les clients jusqu’à une nouvelle publication.',
          )
          if (ok) void onRevertToDraft()
        }}
        className={`${secondaryBtn} self-start`}
      >
        Retirer (repasser en brouillon)
      </button>
    </div>
  )
}
