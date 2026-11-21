import { Check } from 'lucide-react'

import type { PlanId } from '@/features/quotes/domain/catalog'
import { formatEuro, planOrder, plans } from '@/features/quotes/domain/catalog'

type Props = {
  value: PlanId
  onChange: (planId: PlanId) => void
}

export function PlanPicker({ value, onChange }: Props) {
  return (
    <div className="grid grid-cols-2 gap-2">
      {planOrder.map((planId) => {
        const plan = plans[planId]
        const isActive = planId === value

        return (
          <button
            key={planId}
            type="button"
            onClick={() => onChange(planId)}
            aria-pressed={isActive}
            className={`flex flex-col gap-2 rounded-lg border p-3 text-left transition-colors ${
              isActive
                ? 'border-primary bg-primary/5'
                : 'border-border hover:border-primary/40'
            }`}
          >
            <div className="flex items-baseline justify-between gap-2">
              <span className="text-[13px] font-semibold text-foreground">
                {plan.name}
              </span>
              <span className="text-[13px] font-medium tabular-nums text-foreground">
                {formatEuro(plan.monthlyPrice)}
                <span className="text-[11px] text-muted-foreground"> /mois</span>
              </span>
            </div>

            <ul className="flex flex-col gap-1">
              {plan.highlights.map((highlight) => (
                <li
                  key={highlight}
                  className="flex items-start gap-1.5 text-[11px] leading-tight text-muted-foreground"
                >
                  <Check className="mt-px size-3 shrink-0 text-primary" />
                  {highlight}
                </li>
              ))}
            </ul>
          </button>
        )
      })}
    </div>
  )
}
