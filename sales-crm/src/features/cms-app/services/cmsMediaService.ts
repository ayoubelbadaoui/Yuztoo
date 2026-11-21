import type {
  MediaSlotId,
  MediaSlotState,
} from '@/features/cms-app/domain/mediaSlot'
import {
  formatMaxBytes,
  MEDIA_SLOT_CATALOG,
} from '@/features/cms-app/domain/mediaSlot'
import {
  clearMediaOverride,
  loadMediaOverrides,
  setMediaOverride,
} from '@/features/cms-app/services/cmsMediaData'

type Result<T> = { data: T | null; error: Error | null }

function toState(id: MediaSlotId): MediaSlotState {
  const def = MEDIA_SLOT_CATALOG.find((s) => s.id === id)
  if (!def) throw new Error(`Slot inconnu: ${id}`)
  const override = loadMediaOverrides()[id]
  return {
    ...def,
    imageDataUrl: override?.imageDataUrl ?? null,
    updatedAt: override?.updatedAt ?? null,
    isCustom: Boolean(override?.imageDataUrl),
  }
}

/** Catalog of design-safe app image slots. Later: Edge → Storage. */
export async function listMediaSlots(): Promise<Result<MediaSlotState[]>> {
  try {
    return {
      data: MEDIA_SLOT_CATALOG.map((slot) => toState(slot.id)),
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getMediaSlot(
  id: MediaSlotId,
): Promise<Result<MediaSlotState>> {
  try {
    return { data: toState(id), error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function setSlotImage(
  id: MediaSlotId,
  imageDataUrl: string,
  meta?: { mime?: string; byteLength?: number },
): Promise<Result<MediaSlotState>> {
  try {
    const def = MEDIA_SLOT_CATALOG.find((s) => s.id === id)
    if (!def) throw new Error('Slot introuvable')

    if (!imageDataUrl.startsWith('data:image/')) {
      throw new Error('Image invalide')
    }

    const mimeMatch = /^data:(image\/[a-zA-Z0-9.+-]+);/.exec(imageDataUrl)
    const mime = meta?.mime ?? mimeMatch?.[1]
    if (!mime || !def.allowedMime.includes(mime)) {
      throw new Error(
        `Format non autorisé. Utilisez PNG, JPEG ou WebP.`,
      )
    }

    const approxBytes =
      meta?.byteLength ??
      Math.ceil((imageDataUrl.length - (mimeMatch?.[0].length ?? 0)) * 0.75)
    if (approxBytes > def.maxBytes) {
      throw new Error(
        `Fichier trop lourd (max ${formatMaxBytes(def.maxBytes)}).`,
      )
    }

    setMediaOverride(id, imageDataUrl)
    return { data: toState(id), error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function resetSlot(
  id: MediaSlotId,
): Promise<Result<MediaSlotState>> {
  try {
    clearMediaOverride(id)
    return { data: toState(id), error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/**
 * Crop an image File to the slot aspect and export a data URL at
 * recommended pixel size (design-safe). Icon profile prefers WebP.
 */
export async function cropImageToSlot(
  file: File,
  slot: {
    id: MediaSlotId
    profile?: string
    aspectRatio: number
    recommendedWidth: number
    recommendedHeight: number
    maxBytes: number
    allowedMime: readonly string[]
  },
  crop: { sx: number; sy: number; sw: number; sh: number },
): Promise<Result<{ dataUrl: string; byteLength: number; mime: string }>> {
  try {
    if (!slot.allowedMime.includes(file.type)) {
      throw new Error('Format non autorisé. Utilisez PNG, JPEG ou WebP.')
    }
    // Source may be larger before crop; hard-cap at 4× slot max.
    if (file.size > slot.maxBytes * 4) {
      throw new Error(
        `Fichier source trop lourd (max ${formatMaxBytes(slot.maxBytes * 4)} avant recadrage).`,
      )
    }

    const bitmap = await createImageBitmap(file)
    const canvas = document.createElement('canvas')
    canvas.width = slot.recommendedWidth
    canvas.height = slot.recommendedHeight
    const ctx = canvas.getContext('2d')
    if (!ctx) throw new Error('Canvas indisponible')

    ctx.drawImage(
      bitmap,
      crop.sx,
      crop.sy,
      crop.sw,
      crop.sh,
      0,
      0,
      slot.recommendedWidth,
      slot.recommendedHeight,
    )
    bitmap.close()

    const preferWebp = slot.profile === 'icon'
    const candidates: Array<{ mime: string; quality?: number }> = preferWebp
      ? [
          { mime: 'image/webp', quality: 0.86 },
          { mime: 'image/png' },
          { mime: 'image/jpeg', quality: 0.88 },
        ]
      : file.type === 'image/png'
        ? [{ mime: 'image/png' }, { mime: 'image/webp', quality: 0.9 }]
        : [
            { mime: 'image/jpeg', quality: 0.92 },
            { mime: 'image/webp', quality: 0.9 },
            { mime: 'image/png' },
          ]

    let best: { dataUrl: string; byteLength: number; mime: string } | null =
      null
    for (const candidate of candidates) {
      if (!slot.allowedMime.includes(candidate.mime)) continue
      const dataUrl = canvas.toDataURL(candidate.mime, candidate.quality)
      if (!dataUrl.startsWith(`data:${candidate.mime}`)) continue
      const byteLength = Math.ceil((dataUrl.length - 22) * 0.75)
      if (byteLength > slot.maxBytes) continue
      best = { dataUrl, byteLength, mime: candidate.mime }
      break
    }

    if (!best) {
      throw new Error(
        `Résultat trop lourd après recadrage (max ${formatMaxBytes(slot.maxBytes)}). Réduisez l’image.`,
      )
    }

    return { data: best, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
