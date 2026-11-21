import type { CmsMerchant } from '@/features/cms-app/domain/cms'
import { MerchantStatusBadge } from '@/features/cms-app/components/CmsStatusBadge'

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(new Date(iso))
}

type Props = {
  merchants: CmsMerchant[]
  onEdit: (merchant: CmsMerchant) => void
  onPublish: (merchant: CmsMerchant) => void
  onUnpublish: (merchant: CmsMerchant) => void
  busyId: string | null
}

export function MerchantsTable({
  merchants,
  onEdit,
  onPublish,
  onUnpublish,
  busyId,
}: Props) {
  if (merchants.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-card p-10 text-center">
        <p className="text-[13px] text-muted-foreground">
          Aucune boutique ne correspond à cette recherche.
        </p>
      </div>
    )
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-card">
      <table className="w-full min-w-[780px] border-collapse">
        <thead>
          <tr className="border-b border-border">
            {['Boutique', 'Ville', 'Contact', 'Statut', 'Modifiée', 'Actions'].map(
              (label) => (
                <th
                  key={label}
                  className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-muted-foreground"
                >
                  {label}
                </th>
              ),
            )}
          </tr>
        </thead>
        <tbody>
          {merchants.map((merchant) => {
            const busy = busyId === merchant.id
            return (
              <tr
                key={merchant.id}
                className="border-b border-border last:border-0 hover:bg-muted/40"
              >
                <td className="px-4 py-3">
                  <p className="text-[13px] font-medium text-card-foreground">
                    {merchant.displayName}
                  </p>
                  <p className="text-[11px] text-muted-foreground">
                    {merchant.id}
                  </p>
                </td>
                <td className="px-4 py-3 text-[13px] text-card-foreground">
                  {merchant.city}
                </td>
                <td className="px-4 py-3 text-[12px] text-muted-foreground">
                  <p>{merchant.email ?? '—'}</p>
                  <p>{merchant.phone ?? '—'}</p>
                </td>
                <td className="px-4 py-3">
                  <MerchantStatusBadge status={merchant.status} />
                </td>
                <td className="px-4 py-3 text-[12px] tabular-nums text-muted-foreground">
                  {formatDate(merchant.updatedAt)}
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap gap-1.5">
                    <button
                      type="button"
                      disabled={busy || merchant.status === 'deleted'}
                      onClick={() => onEdit(merchant)}
                      className="rounded-md border border-border px-2 py-1 text-[11px] font-medium text-foreground transition-colors hover:bg-muted disabled:opacity-40"
                    >
                      Éditer
                    </button>
                    {merchant.status !== 'published' &&
                      merchant.status !== 'deleted' && (
                        <button
                          type="button"
                          disabled={busy}
                          onClick={() => onPublish(merchant)}
                          className="rounded-md border border-border px-2 py-1 text-[11px] font-medium text-primary transition-colors hover:bg-primary/10 disabled:opacity-40"
                        >
                          Publier
                        </button>
                      )}
                    {merchant.status === 'published' && (
                      <button
                        type="button"
                        disabled={busy}
                        onClick={() => onUnpublish(merchant)}
                        className="rounded-md border border-border px-2 py-1 text-[11px] font-medium text-muted-foreground transition-colors hover:bg-muted disabled:opacity-40"
                      >
                        Retirer
                      </button>
                    )}
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
