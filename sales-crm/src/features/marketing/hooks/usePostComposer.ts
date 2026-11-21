import { useMemo, useState } from 'react'

import { useAuth } from '@/features/auth/hooks/useAuth'
import type { AudienceFilter } from '@/features/marketing/domain/audience'
import { emptyAudience, selectChannels } from '@/features/marketing/domain/audience'
import type { Channel } from '@/features/marketing/domain/channel'
import type { PostFormat } from '@/features/marketing/domain/post'
import { captionLimits } from '@/features/marketing/domain/post'
import type { RecurrenceRule } from '@/features/marketing/domain/recurrence'
import { defaultRecurrence } from '@/features/marketing/domain/recurrence'
import { createPost } from '@/features/marketing/services/marketingService'
import { uploadMarketingMedia } from '@/features/marketing/services/mediaService'

export function usePostComposer(channels: Channel[], onDone: () => void) {
  const { session } = useAuth()
  const workspaceId = session?.activeWorkspaceId ?? null
  const [format, setFormat] = useState<PostFormat>('post')
  const [caption, setCaption] = useState('')
  const [mediaId, setMediaId] = useState<string | null>(null)
  const [mediaLabel, setMediaLabel] = useState<string | null>(null)
  const [mediaUrl, setMediaUrl] = useState<string | null>(null)
  const [linkUrl, setLinkUrl] = useState('')
  const [audience, setAudience] = useState<AudienceFilter>(emptyAudience)
  /** Comptes retirés à la main d'une sélection par filtre. */
  const [excluded, setExcluded] = useState<string[]>([])
  const [scheduledAt, setScheduledAt] = useState('')
  const [recurrence, setRecurrence] = useState<RecurrenceRule>(defaultRecurrence)
  const [isBusy, setIsBusy] = useState(false)
  const [isUploading, setIsUploading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const matched = useMemo(
    () => selectChannels(channels, audience),
    [channels, audience],
  )
  const selected = useMemo(
    () => matched.filter((channel) => !excluded.includes(channel.id)),
    [matched, excluded],
  )

  const limit = captionLimits[format]
  const remaining = limit - caption.length

  const toggleExcluded = (channelId: string) => {
    setExcluded((current) =>
      current.includes(channelId)
        ? current.filter((id) => id !== channelId)
        : [...current, channelId],
    )
  }

  const clearMedia = () => {
    setMediaId(null)
    setMediaLabel(null)
    setMediaUrl(null)
  }

  const uploadFile = async (file: File) => {
    if (!workspaceId) {
      setError('Aucun espace de travail actif')
      return
    }
    setIsUploading(true)
    setError(null)
    const { data, error: failure } = await uploadMarketingMedia({
      workspaceId,
      file,
    })
    setIsUploading(false)
    if (failure || !data) {
      setError(failure?.message ?? 'Upload impossible')
      return
    }
    setMediaId(data.id)
    setMediaLabel(data.originalName)
    setMediaUrl(data.publicUrl)
  }

  const submit = async (mode: 'now' | 'schedule') => {
    if (!workspaceId) {
      setError('Aucun espace de travail actif')
      return
    }
    setIsBusy(true)
    const { error: failure } = await createPost(workspaceId, {
      format,
      caption,
      mediaId,
      mediaLabel,
      linkUrl: linkUrl.trim() || null,
      channelIds: selected.map((channel) => channel.id),
      scheduledAt:
        mode === 'schedule' && scheduledAt
          ? new Date(scheduledAt).toISOString()
          : recurrence.freq !== 'once'
            ? new Date().toISOString()
            : null,
      author: session?.user.email ?? 'CRM',
      recurrence,
    })
    setIsBusy(false)

    if (failure) {
      setError(failure.message)
      return
    }
    onDone()
  }

  return {
    format,
    setFormat,
    caption,
    setCaption: (value: string) => {
      setCaption(value)
      setError(null)
    },
    mediaId,
    mediaLabel,
    mediaUrl,
    clearMedia,
    uploadFile,
    isUploading,
    linkUrl,
    setLinkUrl,
    audience,
    setAudience,
    excluded,
    toggleExcluded,
    scheduledAt,
    setScheduledAt,
    recurrence,
    setRecurrence,
    matched,
    selected,
    limit,
    remaining,
    isBusy,
    error,
    submit,
  }
}
