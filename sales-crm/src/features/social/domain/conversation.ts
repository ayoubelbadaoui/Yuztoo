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
  return platform === 'instagram' ? 'Instagram' : 'Messenger'
}
