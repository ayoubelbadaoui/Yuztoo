import { FileText, Lock, Send, UserRound } from 'lucide-react'
import { useState } from 'react'

import { MessageBubble } from '@/features/whatsapp/components/MessageBubble'
import { TemplatePicker } from '@/features/whatsapp/components/TemplatePicker'
import type {
  WaConversation,
  WaMessage,
} from '@/features/whatsapp/domain/conversation'
import {
  formatPhone,
  isWindowOpen,
  remainingWindowLabel,
} from '@/features/whatsapp/domain/conversation'
import type { WaTemplate } from '@/features/whatsapp/domain/template'
import {
  sendTemplate,
  sendText,
} from '@/features/whatsapp/services/whatsappService'

type Props = {
  conversation: WaConversation
  messages: WaMessage[]
  templates: WaTemplate[]
  onSent: () => void
}

export function ChatThread({
  conversation,
  messages,
  templates,
  onSent,
}: Props) {
  const [body, setBody] = useState('')
  const [isPickerOpen, setIsPickerOpen] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const open = isWindowOpen(conversation)

  const submitText = async () => {
    const { error: failure } = await sendText(conversation.id, body)
    if (failure) {
      setError(failure.message)
      return
    }
    setBody('')
    setError(null)
    onSent()
  }

  const submitTemplate = async (templateId: string, values: string[]) => {
    const { error: failure } = await sendTemplate(
      conversation.id,
      templateId,
      values,
    )
    if (failure) {
      setError(failure.message)
      return
    }
    setError(null)
    setIsPickerOpen(false)
    onSent()
  }

  return (
    <section className="relative flex min-w-0 flex-1 flex-col overflow-hidden rounded-xl border border-border bg-card">
      <header className="flex shrink-0 items-center justify-between gap-3 border-b border-border p-3">
        <div className="min-w-0">
          <p className="truncate text-[14px] font-semibold text-card-foreground">
            {conversation.contactName}
          </p>
          <p className="truncate text-[12px] text-muted-foreground">
            {`${formatPhone(conversation.phone)}${conversation.company ? ` · ${conversation.company}` : ''}`}
          </p>
        </div>

        <div className="flex shrink-0 items-center gap-2">
          {conversation.leadId && (
            <span className="flex h-7 items-center gap-1 rounded-full bg-muted px-2 text-[11px] text-muted-foreground">
              <UserRound className="size-3" />
              {conversation.leadId}
            </span>
          )}
          <span
            className={`flex h-7 items-center rounded-full px-2.5 text-[11px] font-medium ${
              open
                ? 'bg-success/15 text-success'
                : 'bg-warning/15 text-warning'
            }`}
          >
            {remainingWindowLabel(conversation)}
          </span>
        </div>
      </header>

      <ul className="scrollbar-none flex min-h-0 flex-1 flex-col gap-2 overflow-y-auto p-4">
        {messages.map((message) => (
          <MessageBubble key={message.id} message={message} />
        ))}
      </ul>

      {!open && (
        <p className="flex shrink-0 items-start gap-2 border-t border-border bg-warning/10 px-4 py-2.5 text-[12px] text-warning">
          <Lock className="mt-px size-3.5 shrink-0" />
          Plus de 24 h sans message du contact : Meta n’accepte qu’un modèle
          approuvé. Le contact pourra répondre librement ensuite.
        </p>
      )}

      <div className="flex shrink-0 items-end gap-2 border-t border-border p-3">
        <textarea
          value={body}
          onChange={(event) => {
            setBody(event.target.value)
            setError(null)
          }}
          disabled={!open}
          rows={2}
          placeholder={
            open
              ? 'Votre message…'
              : 'Fenêtre fermée — passez par un modèle approuvé'
          }
          className="w-full resize-none rounded-lg border border-input bg-background p-2.5 text-[13px] text-foreground outline-none transition-colors placeholder:text-muted-foreground focus:border-ring focus:ring-1 focus:ring-ring disabled:opacity-60"
        />

        <button
          type="button"
          onClick={() => setIsPickerOpen(true)}
          title="Envoyer un modèle"
          className="flex h-9 shrink-0 items-center gap-1.5 rounded-lg border border-border px-2.5 text-[12px] text-foreground transition-colors hover:bg-muted"
        >
          <FileText className="size-4" />
          Modèle
        </button>

        <button
          type="button"
          disabled={!open || body.trim() === ''}
          onClick={() => void submitText()}
          className="flex h-9 shrink-0 items-center gap-1.5 rounded-lg bg-primary px-3 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-40"
        >
          <Send className="size-4" />
          Envoyer
        </button>
      </div>

      {error && (
        <p className="shrink-0 border-t border-border bg-destructive/10 px-4 py-2 text-[12px] text-destructive">
          {error}
        </p>
      )}

      {isPickerOpen && (
        <TemplatePicker
          templates={templates}
          onClose={() => setIsPickerOpen(false)}
          onSend={submitTemplate}
        />
      )}
    </section>
  )
}
