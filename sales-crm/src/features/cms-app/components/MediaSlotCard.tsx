import type { MediaSlotState } from '@/features/cms-app/domain/mediaSlot'
import { formatSlotConstraints } from '@/features/cms-app/domain/mediaSlot'
import { MediaCropPreview } from '@/features/cms-app/components/MediaCropPreview'

type Props = {
  slot: MediaSlotState
  onEdit: (slot: MediaSlotState) => void
}

export function MediaSlotCard({ slot, onEdit }: Props) {
  return (
    <article className="flex flex-col gap-3 rounded-xl border border-border bg-card p-4">
      <div className="flex items-start justify-between gap-3">
        <MediaCropPreview
          imageUrl={slot.imageDataUrl}
          previewShape={slot.previewShape}
          objectFit={slot.objectFit}
          defaultPreview={slot.defaultPreview}
          isDefault={!slot.isCustom}
          label="Aperçu"
        />
        <div className="min-w-0 flex-1">
          <h3 className="text-[14px] font-semibold text-card-foreground">
            {slot.label}
          </h3>
          <p className="mt-1 text-[12px] text-muted-foreground">
            {slot.description}
          </p>
          <div className="mt-2 flex flex-wrap gap-1.5">
            <span className="rounded-md bg-muted px-1.5 py-0.5 text-[10px] font-semibold tabular-nums text-muted-foreground">
              {formatSlotConstraints(slot)}
            </span>
            <span
              className={`rounded-md px-1.5 py-0.5 text-[10px] font-semibold ${
                slot.isCustom
                  ? 'bg-primary/15 text-primary'
                  : 'bg-muted text-muted-foreground'
              }`}
            >
              {slot.isCustom ? 'Personnalisé' : 'Défaut'}
            </span>
            {!slot.flutterWired && (
              <span className="rounded-md bg-amber-500/15 px-1.5 py-0.5 text-[10px] font-semibold text-amber-700 dark:text-amber-400">
                Flutter non branché
              </span>
            )}
          </div>
        </div>
      </div>
      <button
        type="button"
        onClick={() => onEdit(slot)}
        className="h-9 rounded-lg border border-border text-[13px] font-medium text-foreground transition-colors hover:bg-muted"
      >
        Modifier l’image
      </button>
    </article>
  )
}
