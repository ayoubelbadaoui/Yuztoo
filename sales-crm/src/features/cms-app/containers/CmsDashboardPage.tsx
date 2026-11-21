import { Store, Trash2, UserRound, Users } from 'lucide-react'

import { useCmsDashboard } from '@/features/cms-app/hooks/useCmsDashboard'

function Kpi({
  label,
  value,
  hint,
  icon: Icon,
}: {
  label: string
  value: number | null
  hint: string
  icon: typeof Store
}) {
  return (
    <article className="rounded-xl border border-border bg-card p-4">
      <div className="flex items-start justify-between gap-2">
        <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
          {label}
        </p>
        <span className="flex size-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
          <Icon className="size-4" strokeWidth={1.5} />
        </span>
      </div>
      <p className="mt-3 text-2xl font-semibold tabular-nums text-card-foreground">
        {value === null ? '—' : new Intl.NumberFormat('fr-FR').format(value)}
      </p>
      <p className="mt-1 text-[12px] text-muted-foreground">{hint}</p>
    </article>
  )
}

export function CmsDashboardPage() {
  const { overview, isLoading, error } = useCmsDashboard()

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Tableau de bord
        </h1>
        <p className="text-[13px] text-muted-foreground">
          Chiffres produit — boutiques et comptes (mock jusqu’au pont Firebase).
        </p>
      </header>

      {error && (
        <p className="rounded-xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-[13px] text-destructive">
          {error}
        </p>
      )}

      {isLoading ? (
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {[0, 1, 2, 3, 4, 5].map((i) => (
            <div key={i} className="h-28 animate-pulse rounded-xl bg-muted" />
          ))}
        </div>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          <Kpi
            label="Boutiques"
            value={overview?.merchantsTotal ?? null}
            hint="Hors suppressions soft"
            icon={Store}
          />
          <Kpi
            label="Publiées"
            value={overview?.merchantsPublished ?? null}
            hint="Vitrines en ligne"
            icon={Store}
          />
          <Kpi
            label="Boutiques supprimées"
            value={overview?.merchantsDeleted ?? null}
            hint="Soft delete"
            icon={Trash2}
          />
          <Kpi
            label="Clients"
            value={overview?.clientsTotal ?? null}
            hint="Comptes actifs ou bloqués"
            icon={Users}
          />
          <Kpi
            label="Bloqués"
            value={overview?.clientsBlocked ?? null}
            hint="Accès produit coupé"
            icon={UserRound}
          />
          <Kpi
            label="Clients supprimés"
            value={overview?.clientsDeleted ?? null}
            hint="Soft delete"
            icon={Trash2}
          />
        </div>
      )}

      <div className="grid gap-3 md:grid-cols-2">
        {['Croissance boutiques', 'Inscriptions clients'].map((title) => (
          <div
            key={title}
            className="relative rounded-xl border border-border bg-card p-4"
          >
            <span className="absolute right-3 top-3 rounded-md bg-primary/15 px-1.5 text-[10px] font-semibold text-primary">
              V2
            </span>
            <p className="text-[13px] font-medium text-card-foreground">
              {title}
            </p>
            <p className="mt-1 text-[12px] text-muted-foreground">
              Graphiques détaillés — prochainement.
            </p>
            <div className="mt-4 flex h-16 items-end gap-1.5 opacity-40">
              {[40, 65, 48, 80, 55, 90, 70].map((h, i) => (
                <div
                  key={i}
                  className="flex-1 rounded-t bg-primary"
                  style={{ height: `${h}%` }}
                />
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
