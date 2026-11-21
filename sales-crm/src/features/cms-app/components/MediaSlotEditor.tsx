import { X } from 'lucide-react'
import { useEffect, useMemo, useRef, useState } from 'react'

import type { MediaSlotState } from '@/features/cms-app/domain/mediaSlot'
import {
  formatAspectLabel,
  formatSlotConstraints,
} from '@/features/cms-app/domain/mediaSlot'
import { MediaCropPreview } from '@/features/cms-app/components/MediaCropPreview'
import {
  computeCropWindow,
  coverPreviewStyle,
  type NaturalSize,
} from '@/features/cms-app/components/mediaCropMath'
import { cropImageToSlot } from '@/features/cms-app/services/cmsMediaService'

type Props = {
  slot: MediaSlotState
  onClose: () => void
  onSave: (
    id: MediaSlotState['id'],
    dataUrl: string,
    meta: { mime: string; byteLength: number },
  ) => Promise<string | null>
  onReset: (id: MediaSlotState['id']) => Promise<string | null>
}

/** Aspect-locked pan crop: zoom + offset within source image. */
export function MediaSlotEditor({ slot, onClose, onSave, onReset }: Props) {
  const fileRef = useRef<HTMLInputElement>(null)
  const [sourceUrl, setSourceUrl] = useState<string | null>(null)
  const [sourceFile, setSourceFile] = useState<File | null>(null)
  const [natural, setNatural] = useState<NaturalSize | null>(null)
  const [zoom, setZoom] = useState(1)
  const [offsetX, setOffsetX] = useState(0.5)
  const [offsetY, setOffsetY] = useState(0.5)
  const [draftUrl, setDraftUrl] = useState<string | null>(slot.imageDataUrl)
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  useEffect(() => {
    return () => {
      if (sourceUrl) URL.revokeObjectURL(sourceUrl)
    }
  }, [sourceUrl])

  const cropWindow = useMemo(() => {
    if (!natural) return null
    return computeCropWindow(
      natural,
      slot.aspectRatio,
      zoom,
      offsetX,
      offsetY,
    )
  }, [natural, zoom, offsetX, offsetY, slot.aspectRatio])

  const onPickFile = (file: File | undefined) => {
    if (!file) return
    setError(null)
    if (!(slot.allowedMime as readonly string[]).includes(file.type)) {
      setError('Format non autorisé. Utilisez PNG, JPEG ou WebP.')
      return
    }
    if (file.size > slot.maxBytes * 4) {
      setError(
        `Fichier source trop lourd (max ${Math.round((slot.maxBytes * 4) / 1000)} Ko avant recadrage).`,
      )
      return
    }
    if (sourceUrl) URL.revokeObjectURL(sourceUrl)
    const url = URL.createObjectURL(file)
    setSourceFile(file)
    setSourceUrl(url)
    setZoom(1)
    setOffsetX(0.5)
    setOffsetY(0.5)
    const img = new Image()
    img.onload = () => setNatural({ w: img.naturalWidth, h: img.naturalHeight })
    img.src = url
  }

  const applyCrop = async () => {
    if (!sourceFile || !cropWindow) {
      setError('Choisissez une image à recadrer.')
      return
    }
    setIsSaving(true)
    setError(null)
    const { data, error: failure } = await cropImageToSlot(
      sourceFile,
      slot,
      cropWindow,
    )
    setIsSaving(false)
    if (failure || !data) {
      setError(failure?.message ?? 'Recadrage impossible')
      return
    }
    setDraftUrl(data.dataUrl)
    const message = await onSave(slot.id, data.dataUrl, {
      mime: data.mime,
      byteLength: data.byteLength,
    })
    if (message) {
      setError(message)
      return
    }
    onClose()
  }

  const handleReset = async () => {
    setIsSaving(true)
    setError(null)
    const message = await onReset(slot.id)
    setIsSaving(false)
    if (message) {
      setError(message)
      return
    }
    onClose()
  }

  return (
    <div className="fixed inset-0 z-40 flex justify-end">
      <button
        type="button"
        aria-label="Fermer le panneau"
        onClick={onClose}
        className="absolute inset-0 bg-foreground/20"
      />
      <aside
        role="dialog"
        aria-modal="true"
        aria-label={`Modifier ${slot.label}`}
        className="pop-in relative flex h-full w-full max-w-md flex-col border-l border-border bg-card shadow-2xl"
      >
        <header className="flex shrink-0 items-start justify-between gap-3 border-b border-border p-4">
          <div className="min-w-0">
            <h2 className="truncate text-[15px] font-semibold text-card-foreground">
              {slot.label}
            </h2>
            <p className="text-[12px] text-muted-foreground">
              {formatSlotConstraints(slot)}
              {slot.profile === 'icon' ? ' · WebP préféré' : ''}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Fermer"
            className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent"
          >
            <X className="size-4" />
          </button>
        </header>

        <div className="scrollbar-none flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto p-4">
          {!slot.flutterWired && (
            <p className="rounded-lg border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-[12px] text-amber-800 dark:text-amber-300">
              L’app Flutter n’utilise pas encore ce slot à distance — le
              catalogue prépare le cadrage. Le logo bundle reste actif jusqu’au
              branchement.
            </p>
          )}

          <MediaCropPreview
            imageUrl={draftUrl}
            previewShape={slot.previewShape}
            objectFit={slot.objectFit}
            defaultPreview={slot.defaultPreview}
            isDefault={!draftUrl}
            label="Cadre app"
          />

          <p className="text-[12px] text-muted-foreground">
            {slot.isCustom
              ? 'Image personnalisée (aperçu ci-dessus).'
              : `Défaut actuel : ${slot.defaultNote}`}
          </p>

          <input
            ref={fileRef}
            type="file"
            accept={slot.allowedMime.join(',')}
            className="hidden"
            onChange={(event) => onPickFile(event.target.files?.[0])}
          />
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="h-9 rounded-lg border border-border text-[13px] font-medium transition-colors hover:bg-muted"
          >
            Choisir une image
          </button>

          {sourceUrl && natural && (
            <div className="flex flex-col gap-3 rounded-xl border border-border bg-muted/40 p-3">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
                Recadrage verrouillé {formatAspectLabel(slot.aspectRatio)}
              </p>
              <div
                className="relative mx-auto w-full max-w-[280px] overflow-hidden rounded-lg border border-border bg-background"
                style={{ aspectRatio: String(slot.aspectRatio) }}
              >
                <img
                  src={sourceUrl}
                  alt=""
                  className="pointer-events-none absolute max-w-none"
                  style={coverPreviewStyle(
                    natural,
                    slot.aspectRatio,
                    zoom,
                    offsetX,
                    offsetY,
                  )}
                />
              </div>
              <label className="flex flex-col gap-1 text-[12px] text-muted-foreground">
                Zoom
                <input
                  type="range"
                  min={1}
                  max={3}
                  step={0.05}
                  value={zoom}
                  onChange={(event) => setZoom(Number(event.target.value))}
                />
              </label>
              <label className="flex flex-col gap-1 text-[12px] text-muted-foreground">
                Position horizontale
                <input
                  type="range"
                  min={0}
                  max={1}
                  step={0.01}
                  value={offsetX}
                  onChange={(event) => setOffsetX(Number(event.target.value))}
                />
              </label>
              <label className="flex flex-col gap-1 text-[12px] text-muted-foreground">
                Position verticale
                <input
                  type="range"
                  min={0}
                  max={1}
                  step={0.01}
                  value={offsetY}
                  onChange={(event) => setOffsetY(Number(event.target.value))}
                />
              </label>
            </div>
          )}

          {error && (
            <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
              {error}
            </p>
          )}
        </div>

        <footer className="flex shrink-0 flex-col gap-2 border-t border-border p-4">
          {slot.isCustom && (
            <button
              type="button"
              disabled={isSaving}
              onClick={() => void handleReset()}
              className="h-9 rounded-lg border border-border text-[13px] font-medium text-muted-foreground transition-colors hover:bg-muted disabled:opacity-50"
            >
              Réinitialiser le défaut
            </button>
          )}
          <div className="flex gap-2">
            <button
              type="button"
              onClick={onClose}
              className="h-9 flex-1 rounded-lg border border-border text-[13px] font-medium transition-colors hover:bg-muted"
            >
              Annuler
            </button>
            <button
              type="button"
              disabled={isSaving || !sourceFile}
              onClick={() => void applyCrop()}
              className="h-9 flex-1 rounded-lg bg-primary text-[13px] font-medium text-primary-foreground disabled:opacity-50"
            >
              {isSaving ? 'Enregistrement…' : 'Enregistrer'}
            </button>
          </div>
        </footer>
      </aside>
    </div>
  )
}
