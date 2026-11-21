import type {
  MediaRelease,
  MediaTestAccount,
} from '@/features/cms-app/domain/mediaRelease'
import {
  canActivatePreview,
  canPublishLive,
} from '@/features/cms-app/domain/mediaRelease'
import { mockClients, mockMerchants } from '@/features/cms-app/services/cmsData'
import {
  loadMediaRelease,
  saveMediaRelease,
} from '@/features/cms-app/services/cmsMediaReleaseData'

type Result<T> = { data: T | null; error: Error | null }

function nowIso(): string {
  return new Date().toISOString()
}

function persist(next: Omit<MediaRelease, 'updatedAt'>): MediaRelease {
  const release: MediaRelease = { ...next, updatedAt: nowIso() }
  saveMediaRelease(release)
  return release
}

/** Current publication gate for Images app. Later: Firestore `app_media_release`. */
export async function getMediaRelease(): Promise<Result<MediaRelease>> {
  try {
    return { data: loadMediaRelease(), error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/** Candidates for the mandatory test account (active clients + non-deleted merchants). */
export async function listMediaTestAccounts(
  search = '',
): Promise<Result<MediaTestAccount[]>> {
  try {
    const needle = search.trim().toLowerCase()
    const clients: MediaTestAccount[] = mockClients
      .filter((c) => c.status === 'active')
      .map((c) => ({
        id: c.id,
        kind: 'client' as const,
        displayName: c.displayName,
        email: c.email,
        city: c.city,
      }))
    const merchants: MediaTestAccount[] = mockMerchants
      .filter((m) => m.status !== 'deleted')
      .map((m) => ({
        id: m.id,
        kind: 'merchant' as const,
        displayName: m.displayName,
        email: m.email,
        city: m.city,
      }))

    const all = [...clients, ...merchants].filter((account) => {
      if (!needle) return true
      const hay = `${account.displayName} ${account.email ?? ''} ${account.id} ${account.city}`.toLowerCase()
      return hay.includes(needle)
    })

    all.sort((a, b) => a.displayName.localeCompare(b.displayName, 'fr'))
    return { data: all, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function setMediaTestAccount(
  account: MediaTestAccount | null,
): Promise<Result<MediaRelease>> {
  try {
    const current = loadMediaRelease()
    if (current.status === 'live') {
      throw new Error(
        'Impossible de changer le compte test pendant que les images sont en ligne. Repassez en brouillon d’abord.',
      )
    }
    return {
      data: persist({
        ...current,
        testAccountId: account?.id ?? null,
        testAccountKind: account?.kind ?? null,
        testAccountLabel: account
          ? `${account.displayName} (${account.kind === 'client' ? 'client' : 'boutique'})`
          : null,
        // Changing account invalidates an active preview window.
        status: current.status === 'preview' ? 'draft' : current.status,
        previewActivatedAt:
          current.status === 'preview' ? null : current.previewActivatedAt,
        liveAt: current.liveAt,
      }),
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function activateMediaPreview(): Promise<Result<MediaRelease>> {
  try {
    const current = loadMediaRelease()
    if (!canActivatePreview(current)) {
      throw new Error(
        'Sélectionnez un compte test avant d’activer l’aperçu.',
      )
    }
    if (current.status === 'live') {
      throw new Error(
        'Les images sont déjà en ligne. Repassez en brouillon pour un nouvel aperçu.',
      )
    }
    return {
      data: persist({
        ...current,
        status: 'preview',
        previewActivatedAt: nowIso(),
        liveAt: null,
      }),
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function stopMediaPreview(): Promise<Result<MediaRelease>> {
  try {
    const current = loadMediaRelease()
    return {
      data: persist({
        ...current,
        status: 'draft',
        previewActivatedAt: null,
        liveAt: null,
      }),
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/**
 * Publish for all users. Hard gate: must be in preview with a test account.
 * Flutter will eventually honor this document; CMS enforces the workflow now.
 */
export async function publishMediaLive(): Promise<Result<MediaRelease>> {
  try {
    const current = loadMediaRelease()
    if (!canPublishLive(current)) {
      throw new Error(
        'Publication bloquée : activez d’abord l’aperçu sur un compte test.',
      )
    }
    return {
      data: persist({
        ...current,
        status: 'live',
        liveAt: nowIso(),
      }),
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function revertMediaToDraft(): Promise<Result<MediaRelease>> {
  try {
    const current = loadMediaRelease()
    return {
      data: persist({
        ...current,
        status: 'draft',
        previewActivatedAt: null,
        liveAt: null,
      }),
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/** After editing slots while live, force re-preview before another full publish. */
export async function demoteLiveMediaToDraft(): Promise<Result<MediaRelease>> {
  try {
    const current = loadMediaRelease()
    if (current.status !== 'live') {
      return { data: current, error: null }
    }
    return {
      data: persist({
        ...current,
        status: 'draft',
        previewActivatedAt: null,
        liveAt: null,
      }),
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
