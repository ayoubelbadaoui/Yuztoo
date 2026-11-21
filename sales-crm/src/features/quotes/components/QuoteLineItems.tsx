import { formatEuro, modules, plans } from '@/features/quotes/domain/catalog'
import type { QuoteTotals } from '@/features/quotes/domain/pricing'
import type { Quote } from '@/features/quotes/domain/quote'

type Line = {
  label: string
  detail: string
  value: string
  emphasis?: boolean
}

function buildLines(quote: Quote, totals: QuoteTotals): Line[] {
  const plan = plans[quote.planId]
  const lines: Line[] = [
    {
      label: `Formule ${plan.name}`,
      detail: 'Abonnement mensuel',
      value: `${formatEuro(plan.monthlyPrice)} /mois`,
    },
  ]

  quote.moduleIds.forEach((moduleId, index) => {
    const isIncluded = index < plan.includedModules
    lines.push({
      label: modules[moduleId].name,
      detail: isIncluded
        ? `Compris dans la formule ${plan.name}`
        : 'Module à la carte',
      value: isIncluded ? 'Inclus' : `${formatEuro(plan.extraModulePrice)} /mois`,
    })
  })

  if (quote.discountPercent > 0) {
    lines.push({
      label: `Remise commerciale ${quote.discountPercent} %`,
      detail: 'Appliquée sur l’abonnement mensuel',
      value: `– ${formatEuro(totals.discountAmount)} /mois`,
    })
  }

  lines.push({
    label: 'Abonnement mensuel',
    detail:
      quote.freeMonths > 0
        ? `${totals.billedMonths} mois facturés sur ${quote.engagementMonths}, ${quote.freeMonths} mois offert${quote.freeMonths > 1 ? 's' : ''}`
        : `${totals.billedMonths} mois d’engagement`,
    value: formatEuro(totals.recurringTotal),
    emphasis: true,
  })

  lines.push({
    label: `Plaques et porte-clés NFC (${quote.nfcQuantity})`,
    detail:
      totals.billedNfc > 0
        ? `${plan.includedNfc} compris, ${totals.billedNfc} à ${formatEuro(plan.extraNfcPrice)} la pièce`
        : `${plan.includedNfc} compris dans la formule`,
    value: totals.nfcOneOff > 0 ? formatEuro(totals.nfcOneOff) : 'Inclus',
    emphasis: true,
  })

  return lines
}

type Props = {
  quote: Quote
  totals: QuoteTotals
}

export function QuoteLineItems({ quote, totals }: Props) {
  return (
    <ul className="flex flex-col">
      {buildLines(quote, totals).map((line) => (
        <li
          key={line.label}
          className={`flex items-baseline justify-between gap-4 border-b border-border py-3 last:border-0 ${
            line.emphasis ? 'font-medium' : ''
          }`}
        >
          <div className="min-w-0">
            <p className="text-[13px] text-card-foreground">{line.label}</p>
            <p className="text-[12px] font-normal text-muted-foreground">
              {line.detail}
            </p>
          </div>
          <p className="shrink-0 text-[13px] tabular-nums text-card-foreground">
            {line.value}
          </p>
        </li>
      ))}
    </ul>
  )
}
