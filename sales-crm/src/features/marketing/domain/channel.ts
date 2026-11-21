export type ChannelKind = 'facebook-page' | 'instagram'

export const channelKindLabels: Record<ChannelKind, string> = {
  'facebook-page': 'Page Facebook',
  instagram: 'Compte Instagram',
}

/**
 * État de la connexion Meta. Un jeton de page expire : le marketeur doit le
 * voir venir, sinon une campagne programmée échoue en silence la nuit.
 */
export type ConnectionStatus = 'connected' | 'expiring' | 'disconnected'

export const connectionStatusLabels: Record<ConnectionStatus, string> = {
  connected: 'Connecté',
  expiring: 'Jeton à renouveler',
  disconnected: 'Déconnecté',
}

/** Compte de Yuztoo, ou compte d'un commerçant qui nous a délégué sa page. */
export type ChannelOwner = 'yuztoo' | 'merchant'

export type Channel = {
  id: string
  kind: ChannelKind
  /** Nom affiché de la page ou du compte. */
  name: string
  handle: string
  /** Identifiant Meta de la page ou du compte professionnel. */
  metaId: string
  /**
   * Page Facebook liée (page elle-même, ou page parente d'un IG).
   * Sert à proposer « FB + IG » d'un coup pour le même établissement.
   */
  pageMetaId: string | null
  owner: ChannelOwner
  city: string | null
  /** Formule souscrite par le commerçant, utile pour cibler en masse. */
  planName: string | null
  followers: number
  pictureUrl: string | null
  /**
   * Page abonnée au webhook de l'app. Sans cela Meta ne livre aucun message,
   * même si le webhook est vérifié côté tableau de bord.
   */
  subscribed: boolean
  status: ConnectionStatus
  tokenExpiresAt: string | null
}

/** Paire page Facebook + Instagram Business rattachés à la même Page Meta. */
export type ChannelPair = {
  pageMetaId: string
  facebook: Channel | null
  instagram: Channel | null
}

export function groupChannelPairs(channels: Channel[]): ChannelPair[] {
  const byPage = new Map<string, ChannelPair>()
  const orphans: ChannelPair[] = []

  for (const channel of channels) {
    const key = channel.pageMetaId
    if (!key) {
      orphans.push({
        pageMetaId: channel.id,
        facebook: channel.kind === 'facebook-page' ? channel : null,
        instagram: channel.kind === 'instagram' ? channel : null,
      })
      continue
    }
    const current = byPage.get(key) ?? {
      pageMetaId: key,
      facebook: null,
      instagram: null,
    }
    if (channel.kind === 'facebook-page') current.facebook = channel
    else current.instagram = channel
    byPage.set(key, current)
  }

  return [...byPage.values(), ...orphans]
}

export function networkMixLabel(channels: Channel[]): string {
  const hasFb = channels.some((channel) => channel.kind === 'facebook-page')
  const hasIg = channels.some((channel) => channel.kind === 'instagram')
  if (hasFb && hasIg) return 'Facebook + Instagram'
  if (hasIg) return 'Instagram'
  if (hasFb) return 'Facebook'
  return 'aucun réseau'
}

export function requiresMediaForChannels(channels: Channel[]): boolean {
  return channels.some((channel) => channel.kind === 'instagram')
}

export function isPublishable(channel: Channel): boolean {
  return channel.status !== 'disconnected'
}

export function daysUntil(iso: string | null): number | null {
  if (!iso) return null
  return Math.round((new Date(iso).getTime() - Date.now()) / 86_400_000)
}

export function formatFollowers(count: number): string {
  if (count < 1000) return String(count)
  return `${(count / 1000).toFixed(count < 10_000 ? 1 : 0).replace('.', ',')} k`
}
