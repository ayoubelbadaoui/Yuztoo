import { Plus, ShieldCheck } from 'lucide-react'
import { useEffect, useState } from 'react'

import { Badge } from '@/components/ui/Badge'
import type { BadgeTone } from '@/components/ui/Badge'
import type { WaNumber } from '@/features/whatsapp/domain/number'
import {
  qualityLabels,
  tierLabel,
  usageRatio,
} from '@/features/whatsapp/domain/number'
import type { TemplateStatus } from '@/features/whatsapp/domain/template'
import {
  templateCategoryLabels,
  templateStatusLabels,
  variableCount,
} from '@/features/whatsapp/domain/template'
import { useTemplates } from '@/features/whatsapp/hooks/useWhatsapp'
import { getNumbers } from '@/features/whatsapp/services/whatsappService'
import { formatPhone } from '@/features/whatsapp/domain/conversation'

const tones: Record<TemplateStatus, BadgeTone> = {
  approved: 'success',
  pending: 'warning',
  rejected: 'danger',
  paused: 'neutral',
}

function NumberCard({ number }: { number: WaNumber }) {
  const ratio = usageRatio(number)

  return (
    <article className="flex flex-col gap-2 rounded-xl border border-border bg-card p-4">
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0">
          <p className="truncate text-[13px] font-medium text-card-foreground">
            {number.displayName}
          </p>
          <p className="truncate text-[12px] text-muted-foreground">
            {formatPhone(number.phone)}
          </p>
        </div>
        <Badge tone={number.quality === 'high' ? 'success' : 'warning'}>
          {qualityLabels[number.quality]}
        </Badge>
      </div>

      <div className="flex flex-col gap-1">
        <div className="flex items-baseline justify-between text-[12px]">
          <span className="text-muted-foreground">Palier d’envoi</span>
          <span className="tabular-nums text-foreground">
            {`${number.used24h} / ${tierLabel(number.tier)}`}
          </span>
        </div>
        <div className="h-1.5 overflow-hidden rounded-full bg-muted">
          <div
            className={`h-full rounded-full ${ratio > 0.8 ? 'bg-warning' : 'bg-primary'}`}
            style={{ width: `${Math.round(ratio * 100)}%` }}
          />
        </div>
      </div>
    </article>
  )
}

export function WhatsappTemplatesPage() {
  const { templates, isLoading } = useTemplates()
  const [numbers, setNumbers] = useState<WaNumber[]>([])

  useEffect(() => {
    void getNumbers().then(({ data }) => setNumbers(data ?? []))
  }, [])

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold tracking-tight text-foreground">
            Modèles WhatsApp
          </h1>
          <p className="text-[13px] text-muted-foreground">
            Messages approuvés par Meta, seuls autorisés hors fenêtre de 24 h.
          </p>
        </div>

        <button
          type="button"
          className="flex h-9 items-center gap-1.5 rounded-lg bg-primary px-3 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90"
        >
          <Plus className="size-4" />
          Soumettre un modèle
        </button>
      </header>

      <section className="flex flex-col gap-2">
        <h2 className="text-[12px] font-semibold uppercase tracking-wide text-muted-foreground">
          Numéros déclarés
        </h2>
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {numbers.map((number) => (
            <NumberCard key={number.id} number={number} />
          ))}
        </div>
      </section>

      <p className="flex items-start gap-2 rounded-xl border border-border bg-card px-4 py-3 text-[12px] text-muted-foreground">
        <ShieldCheck className="mt-px size-3.5 shrink-0 text-primary" />
        Le jeton permanent du compte WhatsApp Business vit côté serveur, et les
        messages entrants arrivent par webhook signé : le navigateur n’appelle
        jamais l’API Graph directement.
      </p>

      {isLoading ? (
        <div className="flex flex-col gap-2">
          {[0, 1, 2].map((index) => (
            <div key={index} className="h-16 animate-pulse rounded-lg bg-muted" />
          ))}
        </div>
      ) : (
        <div className="overflow-x-auto rounded-xl border border-border bg-card">
          <table className="w-full min-w-[760px] border-collapse">
            <thead>
              <tr className="border-b border-border text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
                <th className="px-4 py-2.5 text-left">Modèle</th>
                <th className="w-32 px-4 py-2.5 text-left">Catégorie</th>
                <th className="w-20 px-4 py-2.5 text-left">Langue</th>
                <th className="w-24 px-4 py-2.5 text-right">Variables</th>
                <th className="w-28 px-4 py-2.5 text-right">Envois 30 j</th>
                <th className="w-28 px-4 py-2.5 text-left">Statut</th>
              </tr>
            </thead>

            <tbody>
              {templates.map((template) => (
                <tr
                  key={template.id}
                  className="border-b border-border last:border-0"
                >
                  <td className="max-w-0 px-4 py-2.5">
                    <p className="truncate font-mono text-[12px] text-card-foreground">
                      {template.name}
                    </p>
                    <p className="truncate text-[12px] text-muted-foreground">
                      {template.body}
                    </p>
                    {template.reviewNote && (
                      <p className="mt-0.5 text-[11px] text-destructive">
                        {template.reviewNote}
                      </p>
                    )}
                  </td>

                  <td className="px-4 py-2.5 text-[13px] text-card-foreground">
                    {templateCategoryLabels[template.category]}
                  </td>

                  <td className="px-4 py-2.5 text-[12px] uppercase text-muted-foreground">
                    {template.language}
                  </td>

                  <td className="px-4 py-2.5 text-right text-[13px] tabular-nums text-muted-foreground">
                    {variableCount(template.body)}
                  </td>

                  <td className="px-4 py-2.5 text-right text-[13px] tabular-nums text-card-foreground">
                    {new Intl.NumberFormat('fr-FR').format(template.sent30d)}
                  </td>

                  <td className="px-4 py-2.5">
                    <Badge tone={tones[template.status]}>
                      {templateStatusLabels[template.status]}
                    </Badge>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
