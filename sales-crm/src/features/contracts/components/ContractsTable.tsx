import { ContractStatusBadge } from '@/features/contracts/components/ContractStatusBadge'
import { SigningLinkButtons } from '@/features/contracts/components/SigningLinkButtons'
import type { Contract } from '@/features/contracts/domain/contract'
import { formatContractDate } from '@/features/contracts/domain/contract'
import { formatEuro } from '@/lib/money'

type Props = {
  contracts: Contract[]
  onSelect: (contract: Contract) => void
}

function signatureCell(contract: Contract): string {
  if (contract.signature) {
    return `${contract.signature.signerName} · ${formatContractDate(contract.signature.signedAt)}`
  }
  if (contract.status === 'sent') {
    return `Lien valable jusqu’au ${formatContractDate(contract.expiresAt)}`
  }
  return '—'
}

export function ContractsTable({ contracts, onSelect }: Props) {
  if (contracts.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-card p-10 text-center">
        <p className="text-[13px] text-muted-foreground">
          Aucun contrat pour ce filtre.
        </p>
      </div>
    )
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-card">
      <table className="w-full min-w-[780px] border-collapse">
        <thead>
          <tr className="border-b border-border text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
            <th className="px-4 py-2.5 text-left">Contrat</th>
            <th className="w-32 px-4 py-2.5 text-left">Formule</th>
            <th className="w-28 px-4 py-2.5 text-right">Mensuel</th>
            <th className="w-24 px-4 py-2.5 text-left">Durée</th>
            <th className="w-28 px-4 py-2.5 text-left">Statut</th>
            <th className="hidden px-4 py-2.5 text-left lg:table-cell">
              Signature
            </th>
            <th className="w-20 px-4 py-2.5 text-right">Lien</th>
          </tr>
        </thead>

        <tbody>
          {contracts.map((contract) => (
            <tr
              key={contract.id}
              tabIndex={0}
              onClick={() => onSelect(contract)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') onSelect(contract)
              }}
              className="cursor-pointer border-b border-border transition-colors last:border-0 hover:bg-accent focus:bg-accent focus:outline-none"
            >
              <td className="px-4 py-2.5">
                <p className="text-[13px] font-medium text-card-foreground">
                  {contract.leadName}
                </p>
                <p className="truncate text-[12px] text-muted-foreground">
                  {contract.id} · {contract.company}
                </p>
              </td>

              <td className="px-4 py-2.5 text-[13px] text-card-foreground">
                {contract.planName}
              </td>

              <td className="px-4 py-2.5 text-right text-[13px] font-medium tabular-nums text-card-foreground">
                {formatEuro(contract.monthlyAmount)}
              </td>

              <td className="px-4 py-2.5 text-[12px] text-muted-foreground">
                {`${contract.engagementMonths} mois`}
              </td>

              <td className="px-4 py-2.5">
                <ContractStatusBadge status={contract.status} />
              </td>

              <td className="hidden truncate px-4 py-2.5 text-[12px] text-muted-foreground lg:table-cell">
                {signatureCell(contract)}
              </td>

              <td className="px-4 py-2.5">
                {contract.status === 'signed' ? (
                  <span className="block text-right text-[12px] text-muted-foreground">
                    —
                  </span>
                ) : (
                  <SigningLinkButtons contractId={contract.id} />
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
