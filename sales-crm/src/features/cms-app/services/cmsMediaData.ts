import type { MediaSlotId } from '@/features/cms-app/domain/mediaSlot'

const STORAGE_KEY = 'cms-app-media-overrides'

export type MediaOverride = {
  imageDataUrl: string
  updatedAt: string
}

type OverrideMap = Partial<Record<MediaSlotId, MediaOverride>>

/** Phase-1 persistence for demos — no Firebase / Storage. */
export function loadMediaOverrides(): OverrideMap {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return {}
    const parsed = JSON.parse(raw) as OverrideMap
    return parsed && typeof parsed === 'object' ? parsed : {}
  } catch {
    return {}
  }
}

export function saveMediaOverrides(map: OverrideMap): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(map))
}

export function clearMediaOverride(id: MediaSlotId): OverrideMap {
  const map = loadMediaOverrides()
  delete map[id]
  saveMediaOverrides(map)
  return map
}

export function setMediaOverride(
  id: MediaSlotId,
  imageDataUrl: string,
): MediaOverride {
  const map = loadMediaOverrides()
  const entry: MediaOverride = {
    imageDataUrl,
    updatedAt: new Date().toISOString(),
  }
  map[id] = entry
  saveMediaOverrides(map)
  return entry
}
