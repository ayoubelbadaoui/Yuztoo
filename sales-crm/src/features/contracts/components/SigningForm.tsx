import { useState } from 'react'

import { Field, controlClass } from '@/components/ui/Field'
import { SignaturePad } from '@/features/contracts/components/SignaturePad'
import type { Contract } from '@/features/contracts/domain/contract'
import { useSignaturePad } from '@/features/contracts/hooks/useSignaturePad'
import { signContract } from '@/features/contracts/services/contractService'

type Props = {
  token: string
  onSigned: (contract: Contract) => void
}

export function SigningForm({ token, onSigned }: Props) {
  const pad = useSignaturePad()
  const [signerName, setSignerName] = useState('')
  const [signerEmail, setSignerEmail] = useState('')
  const [hasRead, setHasRead] = useState(false)
  const [isBusy, setIsBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const submit = async () => {
    setIsBusy(true)
    const { data, error: failure } = await signContract(token, {
      signerName,
      signerEmail,
      strokeDataUrl: pad.toDataUrl(),
    })
    setIsBusy(false)

    if (failure || !data) {
      setError(failure?.message ?? 'La signature a échoué')
      return
    }
    onSigned(data)
  }

  const canSubmit = hasRead && !pad.isEmpty && signerName && signerEmail

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault()
        void submit()
      }}
      className="flex flex-col gap-4 rounded-2xl border border-border bg-card p-5"
    >
      <div>
        <h3 className="text-[15px] font-semibold text-card-foreground">
          Signature électronique
        </h3>
        <p className="mt-0.5 text-[12px] text-muted-foreground">
          Votre tracé, votre nom et l’horodatage sont conservés comme preuve de
          votre accord.
        </p>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        <Field label="Nom complet du signataire" htmlFor="signer-name">
          <input
            id="signer-name"
            value={signerName}
            onChange={(event) => {
              setSignerName(event.target.value)
              setError(null)
            }}
            placeholder="Prénom Nom"
            className={controlClass}
          />
        </Field>

        <Field label="Adresse e-mail" htmlFor="signer-email">
          <input
            id="signer-email"
            type="email"
            value={signerEmail}
            onChange={(event) => {
              setSignerEmail(event.target.value)
              setError(null)
            }}
            placeholder="vous@exemple.fr"
            className={controlClass}
          />
        </Field>
      </div>

      <SignaturePad
        canvasRef={pad.canvasRef}
        isEmpty={pad.isEmpty}
        onClear={pad.clear}
        handlers={pad.handlers}
      />

      <label className="flex items-start gap-2 text-[12px] text-muted-foreground">
        <input
          type="checkbox"
          checked={hasRead}
          onChange={(event) => setHasRead(event.target.checked)}
          className="mt-0.5 size-3.5 accent-[var(--primary)]"
        />
        J’ai lu et j’accepte les conditions du contrat, et je reconnais la
        valeur de ma signature électronique.
      </label>

      {error && (
        <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
          {error}
        </p>
      )}

      <button
        type="submit"
        disabled={!canSubmit || isBusy}
        className="h-10 rounded-lg bg-primary px-4 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-40"
      >
        {isBusy ? 'Signature en cours…' : 'Signer le contrat'}
      </button>
    </form>
  )
}
