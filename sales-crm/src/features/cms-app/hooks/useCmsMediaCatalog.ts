import { useEffect, useState } from 'react'

import type { MediaSlotId, MediaSlotState } from '@/features/cms-app/domain/mediaSlot'
import {
  listMediaSlots,
  resetSlot,
  setSlotImage,
} from '@/features/cms-app/services/cmsMediaService'

export function useCmsMediaCatalog() {
  const [slots, setSlots] = useState<MediaSlotState[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [revision, setRevision] = useState(0)

  useEffect(() => {
    let cancelled = false
    void listMediaSlots().then(({ data, error: failure }) => {
      if (cancelled) return
      if (failure || !data) {
        setError(failure?.message ?? 'Chargement impossible')
      } else {
        setError(null)
        setSlots(data)
      }
      setIsLoading(false)
    })
    return () => {
      cancelled = true
    }
  }, [revision])

  const reload = () => setRevision((n) => n + 1)

  const saveImage = async (
    id: MediaSlotId,
    dataUrl: string,
    meta?: { mime?: string; byteLength?: number },
  ) => {
    const { error: failure } = await setSlotImage(id, dataUrl, meta)
    if (failure) return failure.message
    reload()
    return null
  }

  const reset = async (id: MediaSlotId) => {
    const { error: failure } = await resetSlot(id)
    if (failure) return failure.message
    reload()
    return null
  }

  return { slots, isLoading, error, reload, saveImage, reset }
}
