import type { YuztooNews } from '@/features/cms-app/domain/yuztooNews'
import { newsStatusLabel } from '@/features/cms-app/domain/yuztooNews'

type Props = {
  items: YuztooNews[]
  busyId: string | null
  onEdit: (news: YuztooNews) => void
  onToggleActive: (news: YuztooNews) => void
  onDelete: (news: YuztooNews) => void
}

function formatWhen(iso: string): string {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return '—'
  return d.toLocaleString('fr-FR', {
    dateStyle: 'short',
    timeStyle: 'short',
  })
}

export function YuztooNewsTable({
  items,
  busyId,
  onEdit,
  onToggleActive,
  onDelete,
}: Props) {
  if (items.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-10 text-center text-[13px] text-muted-foreground">
        Aucune actu. Créez-en une pour l’afficher dans Alertes (après pont Edge).
      </p>
    )
  }

  return (
    <div className="overflow-hidden rounded-xl border border-border">
      <table className="w-full border-collapse text-left text-[13px]">
        <thead className="bg-muted/50 text-[11px] uppercase tracking-wide text-muted-foreground">
          <tr>
            <th className="px-3 py-2.5 font-semibold">Titre</th>
            <th className="px-3 py-2.5 font-semibold">Publication</th>
            <th className="px-3 py-2.5 font-semibold">Statut</th>
            <th className="px-3 py-2.5 font-semibold">CTA</th>
            <th className="px-3 py-2.5 font-semibold" />
          </tr>
        </thead>
        <tbody>
          {items.map((news) => {
            const busy = busyId === news.id
            const status = newsStatusLabel(news)
            return (
              <tr
                key={news.id}
                className="border-t border-border hover:bg-muted/30"
              >
                <td className="px-3 py-3">
                  <p className="font-medium text-foreground">{news.title}</p>
                  <p className="mt-0.5 truncate text-[11px] text-muted-foreground">
                    {news.id}
                  </p>
                </td>
                <td className="px-3 py-3 tabular-nums text-muted-foreground">
                  {formatWhen(news.publish_on)}
                </td>
                <td className="px-3 py-3">
                  <span
                    className={`rounded-md px-1.5 py-0.5 text-[11px] font-semibold ${
                      status === 'En ligne (tous)' || status === 'En ligne'
                        ? 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400'
                        : status === 'Aperçu test'
                          ? 'bg-amber-500/15 text-amber-800 dark:text-amber-300'
                          : status === 'Programmée'
                            ? 'bg-primary/15 text-primary'
                            : 'bg-muted text-muted-foreground'
                    }`}
                  >
                    {status}
                  </span>
                </td>
                <td className="max-w-[140px] truncate px-3 py-3 text-muted-foreground">
                  {news.cta_merchant_id
                    ? `Boutique ${news.cta_merchant_id}`
                    : news.cta_url
                      ? news.cta_label || news.cta_url
                      : '—'}
                </td>
                <td className="px-3 py-3">
                  <div className="flex flex-wrap justify-end gap-1.5">
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => onEdit(news)}
                      className="h-8 rounded-lg border border-border px-2 text-[12px] font-medium hover:bg-muted disabled:opacity-40"
                    >
                      Modifier
                    </button>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => onToggleActive(news)}
                      className="h-8 rounded-lg border border-border px-2 text-[12px] font-medium hover:bg-muted disabled:opacity-40"
                    >
                      {news.active ? 'Désactiver' : 'Activer'}
                    </button>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => onDelete(news)}
                      className="h-8 rounded-lg border border-destructive/40 px-2 text-[12px] font-medium text-destructive hover:bg-destructive/10 disabled:opacity-40"
                    >
                      Supprimer
                    </button>
                  </div>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
