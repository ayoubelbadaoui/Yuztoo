import type { ElementType } from 'react'

type Props = {
  label: string
  value: string
  hint: string
  icon: ElementType
}

export function KpiCard({ label, value, hint, icon: Icon }: Props) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <div className="flex items-center justify-between">
        <span className="text-[12px] font-medium uppercase tracking-wide text-muted-foreground">
          {label}
        </span>
        <Icon className="size-4 text-primary" strokeWidth={1.5} />
      </div>
      <p className="mt-3 text-2xl font-semibold tracking-tight text-card-foreground">
        {value}
      </p>
      <p className="mt-1 text-[12px] text-muted-foreground">{hint}</p>
    </div>
  )
}
