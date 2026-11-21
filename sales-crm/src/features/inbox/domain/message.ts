export type MessageSource =
  | 'website-form'
  | 'website-demo'
  | 'website-callback'
  | 'email'

export const messageSourceLabels: Record<MessageSource, string> = {
  'website-form': 'Formulaire du site',
  'website-demo': 'Demande de démo',
  'website-callback': 'Rappel demandé',
  email: 'E-mail direct',
}

/**
 * « Lu » et « traité » sont deux choses différentes : ouvrir un message ne
 * veut pas dire qu'on a répondu. Le compteur de la navigation suit les
 * non-lus, la file de travail suit les non-traités.
 */
export type MessageStatus = 'new' | 'read' | 'handled' | 'archived'

export const messageStatusLabels: Record<MessageStatus, string> = {
  new: 'Non lu',
  read: 'Lu',
  handled: 'Traité',
  archived: 'Archivé',
}

export type MessageReply = {
  id: string
  author: string
  body: string
  sentAt: string
}

export type InboxMessage = {
  id: string
  source: MessageSource
  subject: string
  body: string
  senderName: string
  senderEmail: string
  senderPhone: string | null
  company: string | null
  city: string | null
  /** Page du site d'où part le formulaire, utile pour juger l'intention. */
  pageUrl: string | null
  receivedAt: string
  status: MessageStatus
  /** Renseigné une fois le message converti en lead. */
  leadId: string | null
  replies: MessageReply[]
}

export function isUnread(message: InboxMessage): boolean {
  return message.status === 'new'
}

export function formatTime(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(iso))
}

export function relativeTime(iso: string): string {
  const minutes = Math.round((Date.now() - new Date(iso).getTime()) / 60000)
  if (minutes < 60) return `il y a ${Math.max(1, minutes)} min`
  if (minutes < 60 * 24) return `il y a ${Math.round(minutes / 60)} h`
  const days = Math.round(minutes / (60 * 24))
  return days === 1 ? 'hier' : `il y a ${days} jours`
}

function startOfDay(date: Date): number {
  const copy = new Date(date)
  copy.setHours(0, 0, 0, 0)
  return copy.getTime()
}

export function dayLabel(iso: string): string {
  const day = startOfDay(new Date(iso))
  const today = startOfDay(new Date())
  const DAY = 24 * 60 * 60 * 1000

  if (day === today) return "Aujourd'hui"
  if (day === today - DAY) return 'Hier'
  return new Intl.DateTimeFormat('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  }).format(new Date(iso))
}

export type MessageGroup = {
  key: number
  label: string
  messages: InboxMessage[]
}

/** Regroupe par jour, du plus récent au plus ancien. */
export function groupByDay(messages: InboxMessage[]): MessageGroup[] {
  const groups = new Map<number, MessageGroup>()

  for (const message of messages) {
    const key = startOfDay(new Date(message.receivedAt))
    const group = groups.get(key)
    if (group) {
      group.messages.push(message)
    } else {
      groups.set(key, {
        key,
        label: dayLabel(message.receivedAt),
        messages: [message],
      })
    }
  }

  return [...groups.values()].sort((a, b) => b.key - a.key)
}
