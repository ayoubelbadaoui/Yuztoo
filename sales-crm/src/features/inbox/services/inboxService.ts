import type {
  InboxMessage,
  MessageStatus,
} from '@/features/inbox/domain/message'
import { mockMessages } from '@/features/inbox/services/inboxData'
import { createLead } from '@/features/leads/services/leadService'

type Result<T> = { data: T | null; error: Error | null }

export type InboxFilter = 'all' | 'new' | 'handled' | 'archived'

export type InboxQuery = {
  filter?: InboxFilter
  search?: string
}

function matches(message: InboxMessage, filter: InboxFilter): boolean {
  if (filter === 'all') return message.status !== 'archived'
  if (filter === 'new') return message.status === 'new'
  return message.status === filter
}

function find(id: string): InboxMessage {
  const message = mockMessages.find((candidate) => candidate.id === id)
  if (!message) throw new Error(`Message ${id} introuvable`)
  return message
}

export async function getMessages(
  query: InboxQuery = {},
): Promise<Result<InboxMessage[]>> {
  try {
    const { filter = 'all', search = '' } = query
    const needle = search.trim().toLowerCase()

    const data = mockMessages
      .filter((message) => matches(message, filter))
      .filter((message) =>
        needle
          ? `${message.senderName} ${message.company ?? ''} ${message.subject} ${message.body} ${message.senderEmail}`
              .toLowerCase()
              .includes(needle)
          : true,
      )
      .sort((a, b) => b.receivedAt.localeCompare(a.receivedAt))

    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getMessageCounts(): Promise<
  Result<Record<InboxFilter, number>>
> {
  try {
    const count = (status: MessageStatus) =>
      mockMessages.filter((message) => message.status === status).length

    return {
      data: {
        all: mockMessages.filter((message) => message.status !== 'archived')
          .length,
        new: count('new'),
        handled: count('handled'),
        archived: count('archived'),
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/** Ouvrir un message le marque lu, sans le considérer comme traité. */
export async function markRead(id: string): Promise<Result<InboxMessage>> {
  try {
    const message = find(id)
    if (message.status === 'new') message.status = 'read'
    return { data: { ...message }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function setMessageStatus(
  id: string,
  status: MessageStatus,
): Promise<Result<InboxMessage>> {
  try {
    const message = find(id)
    message.status = status
    return { data: { ...message }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function replyToMessage(
  id: string,
  body: string,
  author = 'Sara M.',
): Promise<Result<InboxMessage>> {
  try {
    const message = find(id)
    if (body.trim().length < 2) throw new Error('La réponse est vide')

    message.replies.push({
      id: `RE-${message.id.slice(4)}-${message.replies.length + 1}`,
      author,
      body: body.trim(),
      sentAt: new Date().toISOString(),
    })
    message.status = 'handled'
    return { data: { ...message }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/**
 * Convertit une demande entrante en lead. La boîte de réception dépend des
 * leads, jamais l'inverse.
 */
export async function convertToLead(
  id: string,
): Promise<Result<InboxMessage>> {
  try {
    const message = find(id)
    if (message.leadId) throw new Error('Ce message a déjà un lead')

    const { data: lead, error } = await createLead({
      name: message.senderName,
      company: message.company ?? undefined,
      city: message.city ?? undefined,
      type: message.company ? 'merchant' : 'client',
    })
    if (error || !lead) throw error ?? new Error('Création du lead impossible')

    message.leadId = lead.id
    if (message.status === 'new') message.status = 'read'
    return { data: { ...message }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
