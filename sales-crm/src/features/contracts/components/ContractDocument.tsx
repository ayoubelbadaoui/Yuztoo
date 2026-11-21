import type { Contract } from '@/features/contracts/domain/contract'
import { formatContractDate } from '@/features/contracts/domain/contract'
import { buildArticles } from '@/features/contracts/domain/contractTemplate'
import { formatEuro } from '@/lib/money'

type Props = {
  contract: Contract
  /** Resserre la mise en page pour l'aperçu dans le CRM. */
  compact?: boolean
}

export function ContractDocument({ contract, compact = false }: Props) {
  const client = contract.company === '—' ? contract.leadName : contract.company
  const articles = buildArticles(contract)

  const facts = [
    { label: 'Formule', value: contract.planName },
    { label: 'Abonnement', value: `${formatEuro(contract.monthlyAmount)} /mois` },
    { label: 'Engagement', value: `${contract.engagementMonths} mois` },
    { label: 'Établi le', value: formatContractDate(contract.createdAt) },
  ]

  return (
    <article className="flex flex-col gap-5">
      <header className="flex flex-col gap-1">
        <p className="text-[12px] uppercase tracking-wide text-primary">
          Contrat d’abonnement
        </p>
        <h2
          className={`font-semibold tracking-tight text-foreground ${compact ? 'text-[17px]' : 'text-2xl'}`}
        >
          {client}
        </h2>
        <p className="text-[12px] text-muted-foreground">
          {`${contract.id} · entre Yuztoo SAS et ${contract.leadName} · suivi par ${contract.owner}`}
        </p>
      </header>

      <dl className="grid grid-cols-2 gap-3 rounded-xl border border-border bg-muted/40 p-4">
        {facts.map((fact) => (
          <div key={fact.label} className="flex flex-col gap-0.5">
            <dt className="text-[11px] uppercase tracking-wide text-muted-foreground">
              {fact.label}
            </dt>
            <dd className="text-[13px] font-medium text-foreground">
              {fact.value}
            </dd>
          </div>
        ))}
      </dl>

      <ol className="flex flex-col gap-4">
        {articles.map((article) => (
          <li key={article.number} className="flex flex-col gap-1">
            <h3 className="text-[13px] font-semibold text-foreground">
              {`Article ${article.number} — ${article.title}`}
            </h3>
            <p className="text-[13px] leading-relaxed text-muted-foreground">
              {article.body}
            </p>
          </li>
        ))}
      </ol>
    </article>
  )
}
