import { X } from 'lucide-react'
import { useState } from 'react'

import { controlClass } from '@/components/ui/Field'
import type { WaTemplate } from '@/features/whatsapp/domain/template'
import {
  isSendable,
  renderTemplate,
  templateCategoryLabels,
  variableCount,
} from '@/features/whatsapp/domain/template'

type Props = {
  templates: WaTemplate[]
  onClose: () => void
  onSend: (templateId: string, values: string[]) => Promise<void>
}

/** Choix du modèle puis saisie des variables, avec aperçu du rendu final. */
export function TemplatePicker({ templates, onClose, onSend }: Props) {
  const sendable = templates.filter(isSendable)
  const [selectedId, setSelectedId] = useState(sendable[0]?.id ?? '')
  const [values, setValues] = useState<string[]>([])
  const [isBusy, setIsBusy] = useState(false)

  const template = sendable.find((candidate) => candidate.id === selectedId)
  const count = template ? variableCount(template.body) : 0

  return (
    <div className="absolute inset-x-0 bottom-0 z-20 flex max-h-[26rem] flex-col rounded-t-xl border-t border-border bg-card shadow-2xl">
      <header className="flex shrink-0 items-center justify-between gap-2 border-b border-border px-3 py-2">
        <p className="text-[13px] font-medium text-card-foreground">
          Envoyer un modèle approuvé
        </p>
        <button
          type="button"
          onClick={onClose}
          aria-label="Fermer"
          className="rounded-md p-1 text-muted-foreground transition-colors hover:bg-muted"
        >
          <X className="size-4" />
        </button>
      </header>

      <div className="scrollbar-none flex min-h-0 flex-1 gap-3 overflow-y-auto p-3">
        <ul className="flex w-48 shrink-0 flex-col gap-0.5">
          {sendable.map((candidate) => (
            <li key={candidate.id}>
              <button
                type="button"
                onClick={() => {
                  setSelectedId(candidate.id)
                  setValues([])
                }}
                className={`w-full rounded-md px-2 py-1.5 text-left transition-colors ${
                  candidate.id === selectedId ? 'bg-accent' : 'hover:bg-muted'
                }`}
              >
                <span className="block truncate text-[12px] text-foreground">
                  {candidate.name}
                </span>
                <span className="block text-[11px] text-muted-foreground">
                  {templateCategoryLabels[candidate.category]}
                </span>
              </button>
            </li>
          ))}
        </ul>

        {template && (
          <div className="flex min-w-0 flex-1 flex-col gap-2">
            {Array.from({ length: count }, (_, index) => (
              <label key={index} className="flex flex-col gap-1">
                <span className="text-[11px] text-muted-foreground">
                  {`Variable {{${index + 1}}}`}
                </span>
                <input
                  value={values[index] ?? ''}
                  onChange={(event) => {
                    const next = [...values]
                    next[index] = event.target.value
                    setValues(next)
                  }}
                  className={controlClass}
                />
              </label>
            ))}

            <div className="rounded-lg border border-border bg-muted/40 p-2.5">
              <p className="text-[11px] text-muted-foreground">Aperçu</p>
              <p className="mt-1 whitespace-pre-line text-[12px] leading-relaxed text-foreground">
                {renderTemplate(template.body, values)}
              </p>
            </div>
          </div>
        )}
      </div>

      <footer className="flex shrink-0 justify-end border-t border-border p-3">
        <button
          type="button"
          disabled={!template || isBusy}
          onClick={async () => {
            if (!template) return
            setIsBusy(true)
            await onSend(template.id, values)
            setIsBusy(false)
          }}
          className="h-9 rounded-lg bg-primary px-3.5 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-40"
        >
          {isBusy ? 'Envoi…' : 'Envoyer le modèle'}
        </button>
      </footer>
    </div>
  )
}
