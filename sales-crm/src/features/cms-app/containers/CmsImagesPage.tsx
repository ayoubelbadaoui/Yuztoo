import { useMemo, useState } from 'react'

import { MediaReleasePanel } from '@/features/cms-app/components/MediaReleasePanel'
import { MediaSlotCard } from '@/features/cms-app/components/MediaSlotCard'
import { MediaSlotEditor } from '@/features/cms-app/components/MediaSlotEditor'
import type { MediaSlotGroup, MediaSlotState } from '@/features/cms-app/domain/mediaSlot'
import { mediaGroupLabels } from '@/features/cms-app/domain/mediaSlot'
import { useCmsMediaCatalog } from '@/features/cms-app/hooks/useCmsMediaCatalog'
import { useCmsMediaRelease } from '@/features/cms-app/hooks/useCmsMediaRelease'

const groupOrder: MediaSlotGroup[] = [
  'branding',
  'onboarding',
  'categories',
  'empty',
]

export function CmsImagesPage() {
  const { slots, isLoading, error, saveImage, reset } = useCmsMediaCatalog()
  const releaseApi = useCmsMediaRelease()
  const [selected, setSelected] = useState<MediaSlotState | null>(null)

  const grouped = useMemo(() => {
    return groupOrder.map((group) => ({
      group,
      label: mediaGroupLabels[group],
      items: slots.filter((slot) => slot.group === group),
    }))
  }, [slots])

  const saveWithGate = async (
    id: MediaSlotState['id'],
    dataUrl: string,
    meta: { mime: string; byteLength: number },
  ) => {
    const message = await saveImage(id, dataUrl, meta)
    if (message) return message
    if (releaseApi.release?.status === 'live') {
      await releaseApi.demoteIfLive()
    }
    return null
  }

  const resetWithGate = async (id: MediaSlotState['id']) => {
    const message = await reset(id)
    if (message) return message
    if (releaseApi.release?.status === 'live') {
      await releaseApi.demoteIfLive()
    }
    return null
  }

  return (
    <div className="flex flex-col gap-5">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Images app
        </h1>
        <p className="max-w-2xl text-[13px] text-muted-foreground">
          Catalogue fixe : logo et illustrations (onboarding / états vides).
          Recadrage verrouillé au ratio. Publication : compte test obligatoire
          avant mise en ligne pour tous.
        </p>
      </header>

      <MediaReleasePanel
        release={releaseApi.release}
        accounts={releaseApi.accounts}
        search={releaseApi.search}
        onSearch={releaseApi.setSearch}
        isLoading={releaseApi.isLoading}
        isBusy={releaseApi.isBusy}
        error={releaseApi.error}
        onSelectAccount={releaseApi.selectAccount}
        onActivatePreview={releaseApi.activatePreview}
        onStopPreview={releaseApi.stopPreview}
        onPublishLive={releaseApi.publishLive}
        onRevertToDraft={releaseApi.revertToDraft}
      />

      <div className="rounded-xl border border-border bg-muted/40 px-4 py-3 text-[12px] text-muted-foreground">
        Flutter lit Firebase (`app_config/app_media_*` + Storage). Ce panneau
        CMS est encore en localStorage — la publication réelle passe par les
        callables Admin (`adminUpsertAppMediaSlot` / `adminSetAppMediaRelease`)
        jusqu’au pont Edge.
      </div>

      {error && (
        <p className="rounded-xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-[13px] text-destructive">
          {error}
        </p>
      )}

      {isLoading ? (
        <div className="grid gap-3 sm:grid-cols-2">
          {[0, 1, 2, 3].map((i) => (
            <div key={i} className="h-40 animate-pulse rounded-xl bg-muted" />
          ))}
        </div>
      ) : (
        grouped.map(({ group, label, items }) =>
          items.length === 0 ? null : (
            <section key={group} className="flex flex-col gap-3">
              <h2 className="text-[12px] font-semibold uppercase tracking-wide text-muted-foreground">
                {label}
              </h2>
              <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
                {items.map((slot) => (
                  <MediaSlotCard
                    key={slot.id}
                    slot={slot}
                    onEdit={setSelected}
                  />
                ))}
              </div>
            </section>
          ),
        )
      )}

      {selected && (
        <MediaSlotEditor
          key={selected.id}
          slot={selected}
          onClose={() => setSelected(null)}
          onSave={saveWithGate}
          onReset={resetWithGate}
        />
      )}
    </div>
  )
}
