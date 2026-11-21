import { useState } from 'react'

type Props = {
  isOpen: boolean
  hoursLeft: number
  isSending: boolean
  onSend: (text: string) => void
}

export function ReplyComposer({
  isOpen,
  hoursLeft,
  isSending,
  onSend,
}: Props) {
  const [text, setText] = useState('')

  if (!isOpen) {
    return (
      <p className="border-t border-border p-3 text-[12px] text-muted-foreground">
        Fenêtre de réponse fermée. Meta n’autorise une réponse que dans les 24 h
        suivant le dernier message du contact.
      </p>
    )
  }

  const submit = () => {
    const value = text.trim()
    if (!value || isSending) return
    onSend(value)
    setText('')
  }

  return (
    <div className="flex flex-col gap-2 border-t border-border p-3">
      <textarea
        value={text}
        onChange={(event) => setText(event.target.value)}
        rows={2}
        maxLength={2000}
        placeholder="Votre réponse…"
        className="w-full resize-none rounded-lg border border-border bg-background px-3 py-2 text-[13px] outline-none focus:border-primary"
      />
      <div className="flex items-center justify-between">
        <span className="text-[11px] text-muted-foreground">
          {hoursLeft} h restantes pour répondre
        </span>
        <button
          type="button"
          onClick={submit}
          disabled={isSending || text.trim().length === 0}
          className="rounded-lg bg-primary px-3 py-1.5 text-[13px] font-medium text-primary-foreground disabled:opacity-50"
        >
          {isSending ? 'Envoi…' : 'Envoyer'}
        </button>
      </div>
    </div>
  )
}
