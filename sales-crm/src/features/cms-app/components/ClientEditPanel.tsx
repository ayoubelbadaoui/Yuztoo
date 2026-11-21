import { X } from 'lucide-react'
import { useEffect, useState } from 'react'

import { Field, controlClass } from '@/components/ui/Field'
import type { CmsClient } from '@/features/cms-app/domain/cms'
import type { ClientPatch } from '@/features/cms-app/services/clientService'
import { ClientStatusBadge } from '@/features/cms-app/components/CmsStatusBadge'

type Props = {
  client: CmsClient
  onClose: () => void
  onSave: (id: string, patch: ClientPatch) => Promise<string | null>
}

export function ClientEditPanel({ client, onClose, onSave }: Props) {
  const [displayName, setDisplayName] = useState(client.displayName)
  const [city, setCity] = useState(client.city)
  const [email, setEmail] = useState(client.email ?? '')
  const [phone, setPhone] = useState(client.phone ?? '')
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  const submit = async () => {
    setIsSaving(true)
    setError(null)
    const message = await onSave(client.id, {
      displayName,
      city,
      email,
      phone,
    })
    setIsSaving(false)
    if (message) {
      setError(message)
      return
    }
    onClose()
  }

  return (
    <div className="fixed inset-0 z-40 flex justify-end">
      <button
        type="button"
        aria-label="Fermer le panneau"
        onClick={onClose}
        className="absolute inset-0 bg-foreground/20"
      />

      <aside
        role="dialog"
        aria-modal="true"
        aria-label={`Modifier ${client.displayName}`}
        className="pop-in relative flex h-full w-full max-w-sm flex-col border-l border-border bg-card shadow-2xl"
      >
        <header className="flex shrink-0 items-start justify-between gap-3 border-b border-border p-4">
          <div className="min-w-0">
            <h2 className="truncate text-[15px] font-semibold text-card-foreground">
              Modifier le client
            </h2>
            <p className="truncate text-[12px] text-muted-foreground">
              {client.id}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Fermer"
            className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          >
            <X className="size-4" />
          </button>
        </header>

        <form
          onSubmit={(event) => {
            event.preventDefault()
            void submit()
          }}
          className="flex min-h-0 flex-1 flex-col"
        >
          <div className="scrollbar-none flex min-h-0 flex-1 flex-col gap-3.5 overflow-y-auto p-4">
            <div className="flex items-center gap-2">
              <ClientStatusBadge status={client.status} />
              {client.salesCrmLeadId && (
                <span className="text-[11px] text-muted-foreground">
                  Lead {client.salesCrmLeadId}
                </span>
              )}
            </div>

            <Field label="Nom" htmlFor="cms-client-name">
              <input
                id="cms-client-name"
                className={controlClass}
                value={displayName}
                onChange={(event) => setDisplayName(event.target.value)}
                required
              />
            </Field>
            <Field label="Ville" htmlFor="cms-client-city">
              <input
                id="cms-client-city"
                className={controlClass}
                value={city}
                onChange={(event) => setCity(event.target.value)}
              />
            </Field>
            <Field label="E-mail" htmlFor="cms-client-email">
              <input
                id="cms-client-email"
                type="email"
                className={controlClass}
                value={email}
                onChange={(event) => setEmail(event.target.value)}
              />
            </Field>
            <Field label="Téléphone" htmlFor="cms-client-phone">
              <input
                id="cms-client-phone"
                className={controlClass}
                value={phone}
                onChange={(event) => setPhone(event.target.value)}
              />
            </Field>

            {error && (
              <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
                {error}
              </p>
            )}
          </div>

          <footer className="flex shrink-0 gap-2 border-t border-border p-4">
            <button
              type="button"
              onClick={onClose}
              className="h-9 flex-1 rounded-lg border border-border text-[13px] font-medium text-foreground transition-colors hover:bg-muted"
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={isSaving}
              className="h-9 flex-1 rounded-lg bg-primary text-[13px] font-medium text-primary-foreground transition-opacity disabled:opacity-50"
            >
              {isSaving ? 'Enregistrement…' : 'Enregistrer'}
            </button>
          </footer>
        </form>
      </aside>
    </div>
  )
}
