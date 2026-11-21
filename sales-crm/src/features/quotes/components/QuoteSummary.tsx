import type { PlanId } from '@/features/quotes/domain/catalog'
import { formatEuro, plans } from '@/features/quotes/domain/catalog'
import type { QuoteTotals } from '@/features/quotes/domain/pricing'

type Props = {
  planId: PlanId
  totals: QuoteTotals
  engagementMonths: number
  freeMonths: number
  discountPercent: number
}

type LineProps = { label: string; value: string; muted?: boolean }

function Line({ label, value, muted = false }: LineProps) {
  return (
    <div className="flex items-baseline justify-between gap-3">
      <span className={`text-[12px] ${muted ? 'text-muted-foreground' : 'text-foreground'}`}>
        {label}
      </span>
      <span
        className={`shrink-0 text-[12px] tabular-nums ${
          muted ? 'text-muted-foreground' : 'text-foreground'
        }`}
      >
        {value}
      </span>
    </div>
  )
}

export function QuoteSummary({
  planId,
  totals,
  engagementMonths,
  freeMonths,
  discountPercent,
}: Props) {
  const plan = plans[planId]

  return (
    <div className="flex flex-col gap-2 rounded-lg border border-border bg-muted/40 p-3">
      <Line
        label={`Formule ${plan.name}`}
        value={`${formatEuro(totals.planMonthly)} /mois`}
      />

      <Line
        label={
          totals.billedModules > 0
            ? `${totals.billedModules} module${totals.billedModules > 1 ? 's' : ''} facturé${totals.billedModules > 1 ? 's' : ''}`
            : 'Modules compris dans la formule'
        }
        value={
          totals.modulesMonthly > 0
            ? `${formatEuro(totals.modulesMonthly)} /mois`
            : 'Inclus'
        }
        muted={totals.modulesMonthly === 0}
      />

      {discountPercent > 0 && (
        <Line
          label={`Remise ${discountPercent} %`}
          value={`– ${formatEuro(totals.discountAmount)} /mois`}
          muted
        />
      )}

      <div className="border-t border-border pt-2">
        <Line
          label="Abonnement mensuel"
          value={`${formatEuro(totals.monthlyTotal)} /mois`}
        />
      </div>

      <Line
        label={
          freeMonths > 0
            ? `${totals.billedMonths} mois facturés sur ${engagementMonths} (${freeMonths} offert${freeMonths > 1 ? 's' : ''})`
            : `${totals.billedMonths} mois facturés`
        }
        value={formatEuro(totals.recurringTotal)}
        muted
      />

      <Line
        label={
          totals.billedNfc > 0
            ? `${totals.billedNfc} NFC supplémentaire${totals.billedNfc > 1 ? 's' : ''}`
            : `NFC compris (${plan.includedNfc})`
        }
        value={totals.nfcOneOff > 0 ? formatEuro(totals.nfcOneOff) : 'Inclus'}
        muted
      />

      <div className="flex items-baseline justify-between gap-3 border-t border-border pt-2">
        <span className="text-[13px] font-semibold text-foreground">
          Total du devis
        </span>
        <span className="text-[15px] font-semibold tabular-nums text-foreground">
          {formatEuro(totals.grandTotal)}
        </span>
      </div>
    </div>
  )
}
