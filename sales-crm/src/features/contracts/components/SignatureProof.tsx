import { ShieldCheck } from 'lucide-react'

import type { ContractSignature } from '@/features/contracts/domain/contract'
import { formatContractDateTime } from '@/features/contracts/domain/contract'

/** Bloc de preuve affiché une fois le contrat signé, côté CRM comme côté client. */
export function SignatureProof({
  signature,
}: {
  signature: ContractSignature
}) {
  return (
    <section className="flex flex-col gap-3 rounded-xl border border-success/30 bg-success/5 p-4">
      <div className="flex items-center gap-2">
        <ShieldCheck className="size-4 shrink-0 text-success" />
        <p className="text-[13px] font-medium text-success">
          Signé électroniquement
        </p>
      </div>

      <div className="flex flex-wrap items-end gap-4">
        <img
          src={signature.strokeDataUrl}
          alt={`Signature de ${signature.signerName}`}
          className="h-16 w-48 object-contain dark:invert"
        />
        <div className="flex flex-col gap-0.5">
          <p className="text-[13px] font-medium text-foreground">
            {signature.signerName}
          </p>
          <p className="text-[12px] text-muted-foreground">
            {signature.signerEmail}
          </p>
          <p className="text-[12px] text-muted-foreground">
            {formatContractDateTime(signature.signedAt)}
          </p>
        </div>
      </div>

      <dl className="flex flex-col gap-1 border-t border-success/20 pt-3 text-[11px] text-muted-foreground">
        <div className="flex gap-2">
          <dt className="shrink-0">Empreinte du document</dt>
          <dd className="truncate font-mono text-foreground">
            {signature.documentHash}
          </dd>
        </div>
        <div className="flex gap-2">
          <dt className="shrink-0">Appareil</dt>
          <dd className="truncate">{signature.userAgent}</dd>
        </div>
      </dl>
    </section>
  )
}
