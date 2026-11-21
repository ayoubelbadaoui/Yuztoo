export type MessageDirection = 'in' | 'out'

export type MessageStatus = 'sent' | 'delivered' | 'read' | 'failed'

export const messageStatusLabels: Record<MessageStatus, string> = {
  sent: 'Envoyé',
  delivered: 'Distribué',
  read: 'Lu',
  failed: 'Échec',
}

export type WaMessage = {
  id: string
  conversationId: string
  direction: MessageDirection
  /** Hors fenêtre de 24 h, seul un modèle approuvé peut partir. */
  kind: 'text' | 'template'
  body: string
  templateName: string | null
  /** Boutons de réponse rapide portés par le modèle. */
  buttons: string[]
  sentAt: string
  status: MessageStatus
  error: string | null
}

export type WaConversation = {
  id: string
  contactName: string
  phone: string
  company: string | null
  leadId: string | null
  assignedTo: string
  unread: number
  /** Dernier message reçu du contact : c'est lui qui ouvre la fenêtre. */
  lastInboundAt: string | null
  lastMessageAt: string
}

export const WINDOW_HOURS = 24

export function windowClosesAt(conversation: WaConversation): Date | null {
  if (!conversation.lastInboundAt) return null
  return new Date(
    new Date(conversation.lastInboundAt).getTime() +
      WINDOW_HOURS * 60 * 60 * 1000,
  )
}

/**
 * Règle Meta : passé 24 h sans message entrant, la conversation libre se ferme
 * et il faut repasser par un modèle approuvé. C'est la contrainte qui structure
 * tout l'écran.
 */
export function isWindowOpen(
  conversation: WaConversation,
  now = new Date(),
): boolean {
  const closes = windowClosesAt(conversation)
  return closes !== null && closes > now
}

export function remainingWindowLabel(
  conversation: WaConversation,
  now = new Date(),
): string {
  const closes = windowClosesAt(conversation)
  if (!closes) return 'Aucun message reçu'
  const minutes = Math.round((closes.getTime() - now.getTime()) / 60_000)
  if (minutes <= 0) return 'Fenêtre fermée'
  if (minutes < 60) return `Fenêtre ouverte ${minutes} min`
  return `Fenêtre ouverte ${Math.floor(minutes / 60)} h`
}

export function formatMessageTime(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(iso))
}

export function formatPhone(phone: string): string {
  return phone.replace(/(\+\d{2})(\d{1})(\d{2})(\d{2})(\d{2})(\d{2})/, '$1 $2 $3 $4 $5 $6')
}
