import { useState } from 'react'

import { YuztooNewsEditPanel } from '@/features/cms-app/components/YuztooNewsEditPanel'
import { YuztooNewsTable } from '@/features/cms-app/components/YuztooNewsTable'
import { YuztooNewsToolbar } from '@/features/cms-app/components/YuztooNewsToolbar'
import type { YuztooNews } from '@/features/cms-app/domain/yuztooNews'
import { useYuztooNews } from '@/features/cms-app/hooks/useYuztooNews'

export function CmsActuPage() {
  const api = useYuztooNews()
  const [editing, setEditing] = useState<YuztooNews | null | undefined>(
    undefined,
  )
  const [busyId, setBusyId] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const panelOpen = editing !== undefined

  return (
    <div className="flex flex-col gap-4">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Actu Yuztoo
        </h1>
        <p className="max-w-2xl text-[13px] text-muted-foreground">
          Actu affichée en haut de l’onglet Alertes des clients. Texte seul,
          avec image et/ou bouton (boutique ou lien). Publication : test sur 1
          client → tous les clients.
        </p>
      </header>

      <YuztooNewsToolbar
        search={api.search}
        onSearch={api.setSearch}
        activeFilter={api.activeFilter}
        onActiveFilter={api.setActiveFilter}
        onCreate={() => setEditing(null)}
      />

      {(api.error || actionError) && (
        <p className="rounded-xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-[13px] text-destructive">
          {api.error ?? actionError}
        </p>
      )}

      {api.isLoading ? (
        <div className="h-64 animate-pulse rounded-xl bg-muted" />
      ) : (
        <YuztooNewsTable
          items={api.items}
          busyId={busyId}
          onEdit={(news) => setEditing(news)}
          onToggleActive={(news) => {
            setBusyId(news.id)
            setActionError(null)
            void api.setActive(news.id, !news.active).then((message) => {
              if (message) setActionError(message)
              setBusyId(null)
            })
          }}
          onDelete={(news) => {
            const ok = window.confirm(
              `Supprimer définitivement « ${news.title} » ?`,
            )
            if (!ok) return
            setBusyId(news.id)
            setActionError(null)
            void api.remove(news.id).then((message) => {
              if (message) setActionError(message)
              setBusyId(null)
            })
          }}
        />
      )}

      {panelOpen && (
        <YuztooNewsEditPanel
          key={editing?.id ?? 'new'}
          news={editing ?? null}
          onClose={() => setEditing(undefined)}
          onSave={api.upsert}
          onSelectTestAccount={api.selectTestAccount}
          onActivatePreview={api.activatePreview}
          onPublishLive={api.publishLive}
          onRevertToDraft={api.revertToDraft}
          onNewsUpdated={setEditing}
        />
      )}
    </div>
  )
}
