import type {
  WaConversation,
  WaMessage,
} from '@/features/whatsapp/domain/conversation'
import { isWindowOpen } from '@/features/whatsapp/domain/conversation'
import type { WaNumber } from '@/features/whatsapp/domain/number'
import type { WaTemplate } from '@/features/whatsapp/domain/template'
import { isSendable, renderTemplate } from '@/features/whatsapp/domain/template'
import {
  mockConversations,
  mockMessages,
  mockNumbers,
  mockTemplates,
} from '@/features/whatsapp/services/whatsappData'

type Result<T> = { data: T | null; error: Error | null }

export type ConversationFilter = 'all' | 'unread' | 'window-open' | 'window-closed'

let sequence = 0

function findConversation(id: string): WaConversation {
  const conversation = mockConversations.find(
    (candidate) => candidate.id === id,
  )
  if (!conversation) throw new Error(`Conversation ${id} introuvable`)
  return conversation
}

function matches(
  conversation: WaConversation,
  filter: ConversationFilter,
): boolean {
  if (filter === 'unread') return conversation.unread > 0
  if (filter === 'window-open') return isWindowOpen(conversation)
  if (filter === 'window-closed') return !isWindowOpen(conversation)
  return true
}

export async function getConversations(
  filter: ConversationFilter = 'all',
  search = '',
): Promise<Result<WaConversation[]>> {
  try {
    const needle = search.trim().toLowerCase()
    const data = mockConversations
      .filter((conversation) => matches(conversation, filter))
      .filter((conversation) =>
        needle
          ? `${conversation.contactName} ${conversation.company ?? ''} ${conversation.phone}`
              .toLowerCase()
              .includes(needle)
          : true,
      )
      .sort((a, b) => b.lastMessageAt.localeCompare(a.lastMessageAt))
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getConversationCounts(): Promise<
  Result<Record<ConversationFilter, number>>
> {
  try {
    return {
      data: {
        all: mockConversations.length,
        unread: mockConversations.filter(
          (conversation) => conversation.unread > 0,
        ).length,
        'window-open': mockConversations.filter((conversation) =>
          isWindowOpen(conversation),
        ).length,
        'window-closed': mockConversations.filter(
          (conversation) => !isWindowOpen(conversation),
        ).length,
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getMessages(
  conversationId: string,
): Promise<Result<WaMessage[]>> {
  try {
    const data = mockMessages
      .filter((message) => message.conversationId === conversationId)
      .sort((a, b) => a.sentAt.localeCompare(b.sentAt))
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function markConversationRead(
  id: string,
): Promise<Result<WaConversation>> {
  try {
    const conversation = findConversation(id)
    conversation.unread = 0
    return { data: { ...conversation }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

function append(message: WaMessage) {
  mockMessages.push(message)
  const conversation = findConversation(message.conversationId)
  conversation.lastMessageAt = message.sentAt
}

/**
 * Message libre. Refusé hors fenêtre de 24 h : c'est la règle Meta, la
 * vérifier ici évite un rejet de l'API et un message perdu côté client.
 */
export async function sendText(
  conversationId: string,
  body: string,
): Promise<Result<WaMessage>> {
  try {
    const conversation = findConversation(conversationId)
    if (body.trim().length < 1) throw new Error('Le message est vide')
    if (!isWindowOpen(conversation)) {
      throw new Error(
        'Fenêtre de 24 h fermée : seul un modèle approuvé peut être envoyé',
      )
    }

    const message: WaMessage = {
      id: `MS-N${(sequence += 1)}`,
      conversationId,
      direction: 'out',
      kind: 'text',
      body: body.trim(),
      templateName: null,
      buttons: [],
      sentAt: new Date().toISOString(),
      status: 'sent',
      error: null,
    }
    append(message)
    return { data: message, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function sendTemplate(
  conversationId: string,
  templateId: string,
  values: string[],
): Promise<Result<WaMessage>> {
  try {
    findConversation(conversationId)
    const template = mockTemplates.find(
      (candidate) => candidate.id === templateId,
    )
    if (!template) throw new Error('Modèle introuvable')
    if (!isSendable(template)) {
      throw new Error('Ce modèle n’est pas approuvé par Meta')
    }

    const body = renderTemplate(template.body, values)
    if (/\{\{\d+\}\}/.test(body)) {
      throw new Error('Renseignez toutes les variables du modèle')
    }

    const message: WaMessage = {
      id: `MS-N${(sequence += 1)}`,
      conversationId,
      direction: 'out',
      kind: 'template',
      body,
      templateName: template.name,
      buttons: template.buttons,
      sentAt: new Date().toISOString(),
      status: 'sent',
      error: null,
    }
    append(message)
    return { data: message, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getTemplates(): Promise<Result<WaTemplate[]>> {
  try {
    return { data: [...mockTemplates], error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getNumbers(): Promise<Result<WaNumber[]>> {
  try {
    return { data: [...mockNumbers], error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
