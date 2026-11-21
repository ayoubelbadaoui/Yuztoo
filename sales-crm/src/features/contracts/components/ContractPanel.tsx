import { Info, Send, X } from 'lucide-react'
import { useEffect, useState } from 'react'

import { ContractDocument } from '@/features/contracts/components/ContractDocument'
import { ContractStatusBadge } from '@/features/contracts/components/ContractStatusBadge'
import { SignatureProof } from '@/features/contracts/components/SignatureProof'
import { SigningLinkButtons } from '@/features/contracts/components/SigningLinkButtons'
import type { Contract } from '@/features/contracts/domain/contract'
import { formatContractDate } from '@/features/contracts/domain/contract'
import { templateNotice } from '@/features/contracts/domain/contractTemplate'
import {
  declineContract,
  sendContract,
} from '@/features/contracts/services/contractService'

type Props = {
  contract: Contract
  onClose: () => void
  onChanged: () => void
}

export function ContractPanel({ contract, onClose, onChanged }: Props) {
  const [isBusy, setIsBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  const run = async (action: 'send' | 'decline') => {
    setIsBusy(true)
    const { error: failure } =
      action === 'send'
        ? await sendContract(contract.id)
        : await declineContract(contract.id)
    setIsBusy(false)

    if (failure) {
      setError(failure.message)
      return
    }
    onChanged()
  }

  const isSigned = contract.status === 'signed'
  const sendLabel =
    contract.status === 'draft'
      ? 'Envoyer à la signature'
      : 'Renvoyer un lien neuf'

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
        aria-label={`Contrat ${contract.id}`}
        className="pop-in relative flex h-full w-full max-w-lg flex-col border-l border-border bg-card shadow-2xl"
      >
        <header className="flex shrink-0 items-start justify-between gap-3 border-b border-border p-4">
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <h2 className="truncate text-[15px] font-semibold text-card-foreground">
                {contract.id}
              </h2>
              <ContractStatusBadge status={contract.status} />
            </div>
            <p className="truncate text-[12px] text-muted-foreground">
              {contract.status === 'sent'
                ? `Lien valable jusqu’au ${formatContractDate(contract.expiresAt)}`
                : `Établi le ${formatContractDate(contract.createdAt)}`}
            </p>
          </div>

          <div className="flex shrink-0 items-center gap-1">
            {!isSigned && <SigningLinkButtons contractId={contract.id} />}
            <button
              type="button"
              onClick={onClose}
              aria-label="Fermer"
              className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
            >
              <X className="size-4" />
            </button>
          </div>
        </header>

        <div className="scrollbar-none flex min-h-0 flex-1 flex-col gap-5 overflow-y-auto p-5">
          <p className="flex items-start gap-2 rounded-lg border border-border bg-muted/40 px-3 py-2 text-[11px] text-muted-foreground">
            <Info className="mt-px size-3.5 shrink-0" />
            {templateNotice}
          </p>

          <ContractDocument contract={contract} compact />

          {contract.signature && (
            <SignatureProof signature={contract.signature} />
          )}

          {error && (
            <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
              {error}
            </p>
          )}
        </div>

        <footer className="flex shrink-0 items-center justify-between gap-2 border-t border-border p-4">
          {isSigned ? (
            <p className="text-[12px] text-muted-foreground">
              Contrat signé : il n’est plus modifiable.
            </p>
          ) : (
            <button
              type="button"
              disabled={isBusy}
              onClick={() => void run('decline')}
              className="h-9 rounded-lg border border-destructive/40 px-3 text-[13px] text-destructive transition-colors hover:bg-destructive/10 disabled:opacity-40"
            >
              Marquer refusé
            </button>
          )}

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onClose}
              className="h-9 rounded-lg border border-border px-3 text-[13px] text-foreground transition-colors hover:bg-muted"
            >
              Fermer
            </button>
            {!isSigned && (
              <button
                type="button"
                disabled={isBusy}
                onClick={() => void run('send')}
                className="flex h-9 items-center gap-1.5 rounded-lg bg-primary px-3.5 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-40"
              >
                <Send className="size-4" />
                {sendLabel}
              </button>
            )}
          </div>
        </footer>
      </aside>
    </div>
  )
}
