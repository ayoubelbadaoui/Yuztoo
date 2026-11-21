import { Handshake, Target, TrendingUp, Users } from 'lucide-react'

import { KpiCard } from '@/features/dashboard/components/KpiCard'
import { PipelineSummaryCard } from '@/features/dashboard/components/PipelineSummaryCard'
import { RecentLeadsCard } from '@/features/dashboard/components/RecentLeadsCard'
import { useDashboardData } from '@/features/dashboard/hooks/useDashboardData'
import { formatAmount } from '@/features/leads/domain/lead'

export function DashboardPage() {
  const { data, error, isLoading } = useDashboardData()

  if (isLoading) {
    return (
      <div className="flex flex-col gap-4">
        <div className="h-8 w-56 animate-pulse rounded-md bg-muted" />
        <div className="grid gap-4 md:grid-cols-4">
          {[0, 1, 2, 3].map((index) => (
            <div
              key={index}
              className="h-28 animate-pulse rounded-xl bg-muted"
            />
          ))}
        </div>
      </div>
    )
  }

  if (error || !data) {
    return (
      <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
        Impossible de charger le tableau de bord.
      </div>
    )
  }

  const openAmount = data.summary
    .filter((row) => row.stage !== 'won')
    .reduce((total, row) => total + row.amount, 0)
  const wonCount =
    data.summary.find((row) => row.stage === 'won')?.count ?? 0
  const openCount = data.summary
    .filter((row) => row.stage !== 'won')
    .reduce((total, row) => total + row.count, 0)

  return (
    <div className="flex flex-col gap-6">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Tableau de bord
        </h1>
        <p className="text-[13px] text-muted-foreground">
          Données de démonstration — branchement Supabase à venir.
        </p>
      </header>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <KpiCard
          label="Leads ouverts"
          value={String(openCount)}
          hint="Toutes étapes hors gagnés"
          icon={Users}
        />
        <KpiCard
          label="Pipeline"
          value={formatAmount(openAmount)}
          hint="Montant potentiel en cours"
          icon={TrendingUp}
        />
        <KpiCard
          label="Signés ce mois"
          value={String(wonCount)}
          hint="Contrats gagnés"
          icon={Handshake}
        />
        <KpiCard
          label="Taux de conversion"
          value="24 %"
          hint="Nouveau → gagné"
          icon={Target}
        />
      </div>

      <div className="grid gap-4 xl:grid-cols-[2fr_1fr]">
        <RecentLeadsCard leads={data.leads} />
        <PipelineSummaryCard summary={data.summary} />
      </div>
    </div>
  )
}
