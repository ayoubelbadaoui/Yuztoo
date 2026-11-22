export type SocialPlatform = 'messenger' | 'instagram'

export type SocialMessageDirection = 'in' | 'out'

export type SocialMessageStatus =
  | 'queued'
  | 'sent'
  | 'delivered'
  | 'read'
  | 'failed'

export type SocialConversation = {
  id: string
  channelId: string
  channelName: string
  platform: SocialPlatform
  peerName: string
  unread: number
  lastMessageAt: string
  lastInboundAt: string | null
}

export type SocialMessage = {
  id: string
  direction: SocialMessageDirection
  body: string
  status: SocialMessageStatus
  sentAt: string
}

const WINDOW_MS = 24 * 60 * 60 * 1000

/**
 * Meta n'accepte une réponse que dans les 24 h suivant le dernier message du
 * contact ; on l'affiche pour éviter un envoi qui échouerait côté serveur.
 */
export function replyWindow(lastInboundAt: string | null): {
  isOpen: boolean
  hoursLeft: number
} {
  if (!lastInboundAt) return { isOpen: false, hoursLeft: 0 }
  const left = WINDOW_MS - (Date.now() - new Date(lastInboundAt).getTime())
  return { isOpen: left > 0, hoursLeft: Math.max(0, Math.floor(left / 3_600_000)) }
}

export function platformLabel(platform: SocialPlatform): string {
  return platform === 'instagram' ? 'Instagram' : 'Facebook'
}

export type PlatformFilter = 'all' | SocialPlatform

export const platformFilters: PlatformFilter[] = ['all', 'instagram', 'messenger']

export const platformFilterLabels: Record<PlatformFilter, string> = {
  all: 'Tous',
  instagram: 'Instagram',
  messenger: 'Facebook',
}

/** Conversation count + unread per tab, for the IG / FB split. */
export function countByPlatform(
  conversations: SocialConversation[],
): Record<PlatformFilter, { total: number; unread: number }> {
  const empty = () => ({ total: 0, unread: 0 })
  const counts = { all: empty(), instagram: empty(), messenger: empty() }
  for (const conversation of conversations) {
    for (const key of ['all', conversation.platform] as const) {
      counts[key].total += 1
      if (conversation.unread > 0) counts[key].unread += 1
    }
  }
  return counts
}
