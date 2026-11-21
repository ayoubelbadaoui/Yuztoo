import { Badge } from '@/components/ui/Badge'
import type { BadgeTone } from '@/components/ui/Badge'
import { formatEuro, modules, plans } from '@/features/quotes/domain/catalog'
import type { Quote, QuoteStatus } from '@/features/quotes/domain/quote'
import { formatQuoteDate, quoteStatusLabels } from '@/features/quotes/domain/quote'
import { ShareLinkButtons } from '@/features/quotes/components/ShareLinkButtons'
import { quoteAmount } from '@/features/quotes/services/quoteService'

const statusTones: Record<QuoteStatus, BadgeTone> = {
  draft: 'neutral',
  sent: 'warning',
  accepted: 'success',
  refused: 'danger',
}

type Props = {
  quotes: Quote[]
  onSelect: (quote: Quote) => void
}

export function QuotesTable({ quotes, onSelect }: Props) {
  if (quotes.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-card p-10 text-center">
        <p className="text-[13px] text-muted-foreground">
          Aucun devis pour ce filtre.
        </p>
      </div>
    )
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-card">
      <table className="w-full min-w-[760px] border-collapse">
        <thead>
          <tr className="border-b border-border text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
            <th className="px-4 py-2.5 text-left">Devis</th>
            <th className="w-36 px-4 py-2.5 text-left">Formule</th>
            <th className="w-44 px-4 py-2.5 text-left">Engagement</th>
            <th className="w-28 px-4 py-2.5 text-right">Total</th>
            <th className="w-28 px-4 py-2.5 text-left">Statut</th>
            <th className="hidden w-28 px-4 py-2.5 text-right md:table-cell">
              Mis à jour
            </th>
            <th className="w-20 px-4 py-2.5 text-right">Lien</th>
          </tr>
        </thead>

        <tbody>
          {quotes.map((quote) => (
            <tr
              key={quote.id}
              tabIndex={0}
              onClick={() => onSelect(quote)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') onSelect(quote)
              }}
              className="cursor-pointer border-b border-border transition-colors last:border-0 hover:bg-accent focus:bg-accent focus:outline-none"
            >
              <td className="px-4 py-2.5">
                <p className="text-[13px] font-medium text-card-foreground">
                  {quote.leadName}
                </p>
                <p className="truncate text-[12px] text-muted-foreground">
                  {quote.id} · {quote.company}
                </p>
              </td>

              <td className="px-4 py-2.5">
                <p className="text-[13px] text-card-foreground">
                  {plans[quote.planId].name}
                </p>
                <p className="truncate text-[11px] text-muted-foreground">
                  {quote.moduleIds.length === 0
                    ? 'Sans module'
                    : quote.moduleIds
                        .map((moduleId) => modules[moduleId].name)
                        .join(', ')}
                </p>
              </td>

              <td className="px-4 py-2.5 text-[12px] text-muted-foreground">
                {`${quote.engagementMonths} mois`}
                {quote.freeMonths > 0 && ` · ${quote.freeMonths} offert${quote.freeMonths > 1 ? 's' : ''}`}
                {quote.discountPercent > 0 && ` · −${quote.discountPercent} %`}
              </td>

              <td className="px-4 py-2.5 text-right text-[13px] font-medium tabular-nums text-card-foreground">
                {formatEuro(quoteAmount(quote))}
              </td>

              <td className="px-4 py-2.5">
                <Badge tone={statusTones[quote.status]}>
                  {quoteStatusLabels[quote.status]}
                </Badge>
              </td>

              <td className="hidden px-4 py-2.5 text-right text-[12px] text-muted-foreground md:table-cell">
                {formatQuoteDate(quote.updatedAt)}
              </td>

              <td className="px-4 py-2.5">
                <ShareLinkButtons quoteId={quote.id} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
