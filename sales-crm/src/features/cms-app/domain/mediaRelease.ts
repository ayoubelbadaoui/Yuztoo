export type MediaReleaseStatus = 'draft' | 'preview' | 'live'

export type MediaTestAccountKind = 'client' | 'merchant'

export type MediaTestAccount = {
  id: string
  kind: MediaTestAccountKind
  displayName: string
  email: string | null
  city: string
}

export type MediaRelease = {
  status: MediaReleaseStatus
  testAccountId: string | null
  testAccountKind: MediaTestAccountKind | null
  testAccountLabel: string | null
  previewActivatedAt: string | null
  liveAt: string | null
  updatedAt: string
}

export const mediaReleaseStatusLabels: Record<MediaReleaseStatus, string> = {
  draft: 'Brouillon',
  preview: 'Aperçu test',
  live: 'En ligne (tous)',
}

export const DEFAULT_MEDIA_RELEASE: MediaRelease = {
  status: 'draft',
  testAccountId: null,
  testAccountKind: null,
  testAccountLabel: null,
  previewActivatedAt: null,
  liveAt: null,
  updatedAt: new Date(0).toISOString(),
}

/** Publish for everyone is blocked until preview ran with a test account. */
export function canPublishLive(release: MediaRelease): boolean {
  return (
    release.status === 'preview' &&
    Boolean(release.testAccountId) &&
    Boolean(release.previewActivatedAt)
  )
}

export function canActivatePreview(release: MediaRelease): boolean {
  return Boolean(release.testAccountId)
}
