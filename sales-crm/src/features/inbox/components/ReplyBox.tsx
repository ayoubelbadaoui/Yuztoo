import { Send, Sparkles } from 'lucide-react'
import { useState } from 'react'

import type { InboxMessage } from '@/features/inbox/domain/message'
import { replyToMessage } from '@/features/inbox/services/inboxService'

type Props = {
  message: InboxMessage
  onSent: () => void
}

/** Brouillons prêts à l'emploi : l'essentiel est de répondre vite, pas joliment. */
function templateFor(message: InboxMessage): string {
  const first = message.senderName.split(' ')[0]
  if (message.source === 'website-demo') {
    return `Bonjour ${first},\n\nMerci pour votre demande de démonstration. Je vous propose un créneau de trente minutes cette semaine, en visio ou sur place.\n\nQuel jour vous conviendrait le mieux ?\n\nBien à vous,\nSara — Yuztoo`
  }
  if (message.source === 'website-callback') {
    return `Bonjour ${first},\n\nBien noté pour l'appel. Je vous téléphone cet après-midi sur le numéro que vous avez laissé.\n\nÀ très vite,\nSara — Yuztoo`
  }
  return `Bonjour ${first},\n\nMerci pour votre message, et bienvenue. Pour vous répondre précisément, pouvez-vous me dire combien de clients fidèles vous suivez aujourd'hui ?\n\nBien à vous,\nSara — Yuztoo`
}

export function ReplyBox({ message, onSent }: Props) {
  const [body, setBody] = useState('')
  const [isBusy, setIsBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const submit = async () => {
    setIsBusy(true)
    const { error: failure } = await replyToMessage(message.id, body)
    setIsBusy(false)

    if (failure) {
      setError(failure.message)
      return
    }
    setBody('')
    onSent()
  }

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault()
        void submit()
      }}
      className="flex shrink-0 flex-col gap-2 border-t border-border p-4"
    >
      <textarea
        value={body}
        onChange={(event) => {
          setBody(event.target.value)
          setError(null)
        }}
        rows={4}
        placeholder={`Répondre à ${message.senderName}…`}
        aria-label="Votre réponse"
        className="w-full resize-none rounded-lg border border-input bg-background p-2.5 text-[13px] leading-relaxed text-foreground outline-none transition-colors placeholder:text-muted-foreground focus:border-ring focus:ring-1 focus:ring-ring"
      />

      {error && (
        <p className="text-[12px] text-destructive">{error}</p>
      )}

      <div className="flex items-center justify-between gap-2">
        <button
          type="button"
          onClick={() => setBody(templateFor(message))}
          className="flex h-8 items-center gap-1.5 rounded-lg border border-border px-2.5 text-[12px] text-muted-foreground transition-colors hover:bg-muted"
        >
          <Sparkles className="size-3.5" />
          Brouillon type
        </button>

        <button
          type="submit"
          disabled={body.trim().length < 2 || isBusy}
          className="flex h-9 items-center gap-1.5 rounded-lg bg-primary px-3.5 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-40"
        >
          <Send className="size-4" />
          {isBusy ? 'Envoi…' : 'Envoyer et marquer traité'}
        </button>
      </div>
    </form>
  )
}
