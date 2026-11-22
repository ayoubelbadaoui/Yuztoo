import { Plug, ShieldCheck } from 'lucide-react'
import { useState } from 'react'

import { useAuth } from '@/features/auth/hooks/useAuth'
import {
  ChannelIcon,
  ConnectionBadge,
} from '@/features/marketing/components/ChannelBadge'
import type { Channel } from '@/features/marketing/domain/channel'
import {
  channelKindLabels,
  daysUntil,
  formatFollowers,
} from '@/features/marketing/domain/channel'
import { useChannels } from '@/features/marketing/hooks/useMarketing'
import {
  disconnectChannel,
  startMetaConnect,
} from '@/features/marketing/services/metaConnectService'

function ChannelCard({
  channel,
  onRenew,
  onDisconnect,
  isRenewing,
}: {
  channel: Channel
  onRenew: () => void
  onDisconnect: () => void
  isRenewing: boolean
}) {
  const days = daysUntil(channel.tokenExpiresAt)

  return (
    <article className="flex flex-col gap-2 rounded-xl border border-border bg-card p-4">
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0">
          <div className="flex items-center gap-1.5">
            <ChannelIcon channel={channel} />
            <p className="truncate text-[13px] font-medium text-card-foreground">
              {channel.name}
            </p>
          </div>
          <p className="truncate text-[12px] text-muted-foreground">
            {`@${channel.handle} · ${channelKindLabels[channel.kind]}`}
          </p>
        </div>
        <ConnectionBadge status={channel.status} />
      </div>

      <dl className="flex flex-wrap gap-x-4 gap-y-1 text-[12px] text-muted-foreground">
        <div className="flex gap-1">
          <dt>Abonnés</dt>
          <dd className="tabular-nums text-foreground">
            {formatFollowers(channel.followers)}
          </dd>
        </div>
        <div className="flex gap-1">
          <dt>Messages</dt>
          <dd className="text-foreground">
            {channel.subscribed ? 'Webhook actif' : 'Webhook inactif'}
          </dd>
        </div>
        {channel.city && (
          <div className="flex gap-1">
            <dt>Ville</dt>
            <dd className="text-foreground">{channel.city}</dd>
          </div>
        )}
        {channel.planName && (
          <div className="flex gap-1">
            <dt>Formule</dt>
            <dd className="text-foreground">{channel.planName}</dd>
          </div>
        )}
      </dl>

      <div className="flex items-center justify-between gap-2 border-t border-border pt-2">
        <p className="truncate text-[11px] text-muted-foreground">
          {channel.status === 'disconnected'
            ? 'Aucun jeton actif'
            : days === null
              ? 'Jeton longue durée'
              : days <= 7
                ? `Jeton expire dans ${days} jour${days > 1 ? 's' : ''}`
                : `Jeton valide ${days} jours`}
        </p>
        <div className="flex shrink-0 gap-1.5">
          {channel.status !== 'disconnected' && (
            <button
              type="button"
              disabled={isRenewing}
              onClick={onDisconnect}
              className="h-7 rounded-lg px-2.5 text-[12px] text-destructive transition-colors hover:bg-destructive/10 disabled:opacity-50"
            >
              Déconnecter
            </button>
          )}
          <button
            type="button"
            disabled={isRenewing}
            onClick={onRenew}
            className="h-7 rounded-lg border border-border px-2.5 text-[12px] text-foreground transition-colors hover:bg-muted disabled:opacity-50"
          >
            {channel.status === 'disconnected' ? 'Reconnecter' : 'Renouveler'}
          </button>
        </div>
      </div>
    </article>
  )
}

export function ChannelsPage() {
  const { session } = useAuth()
  const { channels, isLoading, reload } = useChannels()
  const [connectError, setConnectError] = useState<string | null>(null)
  const [isConnecting, setIsConnecting] = useState(false)
  const yuztoo = channels.filter((channel) => channel.owner === 'yuztoo')
  const merchants = channels.filter((channel) => channel.owner === 'merchant')
  const hasFb = channels.some((channel) => channel.kind === 'facebook-page')
  const hasIg = channels.some((channel) => channel.kind === 'instagram')

  const onDisconnect = async (channel: Channel) => {
    const ok = window.confirm(
      `Déconnecter « ${channel.name} » ?\nLe CRM ne recevra plus ses messages et ne pourra plus publier dessus. « Connecter un compte » ne le réactivera pas : utilisez « Reconnecter » sur sa carte.`,
    )
    if (!ok) return
    setConnectError(null)
    setIsConnecting(true)
    const { error } = await disconnectChannel(channel.id)
    setIsConnecting(false)
    if (error) {
      setConnectError(error.message)
      return
    }
    await reload()
  }

  /** `reconnectId` revives a channel that was disconnected on purpose. */
  const onConnect = async (reconnectId?: string) => {
    const workspaceId = session?.activeWorkspaceId
    if (!workspaceId) {
      setConnectError('Aucun workspace actif')
      return
    }
    setConnectError(null)
    setIsConnecting(true)
    const returnUrl = new URL(window.location.href)
    returnUrl.searchParams.delete('reconnect')
    if (reconnectId) returnUrl.searchParams.set('reconnect', reconnectId)
    const { data, error } = await startMetaConnect({
      workspaceId,
      returnTo: `${returnUrl.pathname}${returnUrl.search}`,
    })
    setIsConnecting(false)
    if (error || !data?.authorizeUrl) {
      setConnectError(error?.message ?? 'Connexion Meta indisponible')
      return
    }
    window.location.assign(data.authorizeUrl)
  }

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Comptes connectés
        </h1>
        <p className="text-[13px] text-muted-foreground">
          Pages Facebook et comptes Instagram autorisés à publier depuis le CRM.
        </p>
      </header>

      <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-card p-4">
        <div className="flex items-start gap-2.5">
          <ShieldCheck className="mt-0.5 size-4 shrink-0 text-primary" />
          <div>
            <p className="text-[13px] font-medium text-card-foreground">
              Connexion Meta Business
            </p>
            <p className="mt-0.5 max-w-xl text-[12px] text-muted-foreground">
              Une Page Facebook et son Instagram Business liés apparaissent
              comme deux comptes : vous pourrez publier sur FB, IG, ou les deux
              en même temps depuis le composeur. Pour lire / répondre /
              supprimer / aimer les commentaires, reconnectez après avoir
              ajouté « pages_manage_engagement » et « pages_read_user_content »
              dans la config Meta Login.
            </p>
            {connectError && (
              <p className="mt-1 text-[12px] text-destructive">{connectError}</p>
            )}
          </div>
        </div>

        <button
          type="button"
          disabled={isConnecting || !session?.activeWorkspaceId}
          onClick={() => void onConnect()}
          className="flex h-9 shrink-0 items-center gap-1.5 rounded-lg bg-primary px-3 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-50"
        >
          <Plug className="size-4" />
          {isConnecting ? 'Redirection…' : 'Connecter un compte'}
        </button>
      </div>

      {isLoading ? (
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {[0, 1, 2, 3, 4, 5].map((index) => (
            <div
              key={index}
              className="h-32 animate-pulse rounded-xl bg-muted"
            />
          ))}
        </div>
      ) : channels.length === 0 ? (
        <p className="rounded-xl border border-dashed border-border p-6 text-center text-[13px] text-muted-foreground">
          Aucun compte connecté pour l’instant. Lancez « Connecter un compte »
          pour autoriser une Page Facebook et son compte Instagram.
        </p>
      ) : (
        <>
          {hasFb && !hasIg && (
            <p className="rounded-xl border border-dashed border-border px-4 py-3 text-[12px] text-muted-foreground">
              Page Facebook connectée, mais aucun Instagram Business rattaché
              n’a été renvoyé par Meta. Liez un compte IG pro à la Page dans
              Meta Business, puis reconnectez ici pour activer « FB + IG ».
            </p>
          )}

          <section className="flex flex-col gap-2">
            <h2 className="text-[12px] font-semibold uppercase tracking-wide text-muted-foreground">
              {`Comptes Yuztoo · ${yuztoo.length}`}
            </h2>
            <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
              {yuztoo.map((channel) => (
                <ChannelCard
                  key={channel.id}
                  channel={channel}
                  onRenew={() =>
                    void onConnect(
                      channel.status === 'disconnected' ? channel.id : undefined,
                    )
                  }
                  onDisconnect={() => void onDisconnect(channel)}
                  isRenewing={isConnecting}
                />
              ))}
            </div>
          </section>

          {merchants.length > 0 && (
            <section className="flex flex-col gap-2">
              <h2 className="text-[12px] font-semibold uppercase tracking-wide text-muted-foreground">
                {`Comptes commerçants délégués · ${merchants.length}`}
              </h2>
              <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
                {merchants.map((channel) => (
                  <ChannelCard
                    key={channel.id}
                    channel={channel}
                    onRenew={() =>
                      void onConnect(
                        channel.status === 'disconnected' ? channel.id : undefined,
                      )
                    }
                    onDisconnect={() => void onDisconnect(channel)}
                    isRenewing={isConnecting}
                  />
                ))}
              </div>
            </section>
          )}
        </>
      )}
    </div>
  )
}
