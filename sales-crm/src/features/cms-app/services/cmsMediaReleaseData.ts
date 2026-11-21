import type { MediaRelease } from '@/features/cms-app/domain/mediaRelease'
import { DEFAULT_MEDIA_RELEASE } from '@/features/cms-app/domain/mediaRelease'

const STORAGE_KEY = 'cms-app-media-release'

export function loadMediaRelease(): MediaRelease {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return { ...DEFAULT_MEDIA_RELEASE }
    const parsed = JSON.parse(raw) as MediaRelease
    if (!parsed || typeof parsed !== 'object') {
      return { ...DEFAULT_MEDIA_RELEASE }
    }
    return {
      ...DEFAULT_MEDIA_RELEASE,
      ...parsed,
    }
  } catch {
    return { ...DEFAULT_MEDIA_RELEASE }
  }
}

export function saveMediaRelease(release: MediaRelease): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(release))
}
