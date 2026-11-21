import type { CmsClient } from '@/features/cms-app/domain/cms'
import { ClientStatusBadge } from '@/features/cms-app/components/CmsStatusBadge'

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(new Date(iso))
}

type Props = {
  clients: CmsClient[]
  onEdit: (client: CmsClient) => void
  onBlock: (client: CmsClient) => void
  onUnblock: (client: CmsClient) => void
  busyId: string | null
}

export function ClientsTable({
  clients,
  onEdit,
  onBlock,
  onUnblock,
  busyId,
}: Props) {
  if (clients.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-card p-10 text-center">
        <p className="text-[13px] text-muted-foreground">
          Aucun client ne correspond à cette recherche.
        </p>
      </div>
    )
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-card">
      <table className="w-full min-w-[780px] border-collapse">
        <thead>
          <tr className="border-b border-border">
            {['Client', 'Contact', 'Ville', 'Statut', 'Inscrit', 'Actions'].map(
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
          {clients.map((client) => {
            const busy = busyId === client.id
            return (
              <tr
                key={client.id}
                className="border-b border-border last:border-0 hover:bg-muted/40"
              >
                <td className="px-4 py-3">
                  <p className="text-[13px] font-medium text-card-foreground">
                    {client.displayName}
                  </p>
                  <p className="text-[11px] text-muted-foreground">
                    {client.id}
                  </p>
                </td>
                <td className="px-4 py-3 text-[12px] text-muted-foreground">
                  <p>{client.email ?? '—'}</p>
                  <p>{client.phone ?? '—'}</p>
                </td>
                <td className="px-4 py-3 text-[13px] text-card-foreground">
                  {client.city}
                </td>
                <td className="px-4 py-3">
                  <ClientStatusBadge status={client.status} />
                </td>
                <td className="px-4 py-3 text-[12px] tabular-nums text-muted-foreground">
                  {formatDate(client.createdAt)}
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap gap-1.5">
                    <button
                      type="button"
                      disabled={busy || client.status === 'deleted'}
                      onClick={() => onEdit(client)}
                      className="rounded-md border border-border px-2 py-1 text-[11px] font-medium text-foreground transition-colors hover:bg-muted disabled:opacity-40"
                    >
                      Éditer
                    </button>
                    {client.status === 'active' && (
                      <button
                        type="button"
                        disabled={busy}
                        onClick={() => onBlock(client)}
                        className="rounded-md border border-border px-2 py-1 text-[11px] font-medium text-destructive transition-colors hover:bg-destructive/10 disabled:opacity-40"
                      >
                        Bloquer
                      </button>
                    )}
                    {client.status === 'blocked' && (
                      <button
                        type="button"
                        disabled={busy}
                        onClick={() => onUnblock(client)}
                        className="rounded-md border border-border px-2 py-1 text-[11px] font-medium text-primary transition-colors hover:bg-primary/10 disabled:opacity-40"
                      >
                        Débloquer
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
