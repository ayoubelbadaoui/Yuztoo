import type { MediaTestAccount } from '@/features/cms-app/domain/mediaRelease'
import type {
  YuztooNews,
  YuztooNewsInput,
} from '@/features/cms-app/domain/yuztooNews'
import {
  canActivateNewsPreview,
  canPublishNewsLive,
  normalizeReleaseStatus,
  YUZTOO_NEWS_BODY_MAX,
  YUZTOO_NEWS_CTA_LABEL_MAX,
  YUZTOO_NEWS_TITLE_MAX,
} from '@/features/cms-app/domain/yuztooNews'
import { listMediaTestAccounts } from '@/features/cms-app/services/cmsMediaReleaseService'
import {
  loadYuztooNews,
  saveYuztooNews,
} from '@/features/cms-app/services/yuztooNewsData'
import { callEdgeFunction } from '@/lib/callEdgeFunction'

type Result<T> = { data: T | null; error: Error | null }

/** Offline UI only — default is live Edge → Firebase. */
function useMock(): boolean {
  return import.meta.env.VITE_CMS_ACTU_MOCK === '1'
}

function nowIso(): string {
  return new Date().toISOString()
}

function newId(): string {
  return `news_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`
}

function emptyToNull(value: string | null | undefined): string | null {
  if (value == null) return null
  const trimmed = value.trim()
  return trimmed.length === 0 ? null : trimmed
}

function validateInput(input: YuztooNewsInput): YuztooNewsInput {
  const title = input.title.trim()
  const body = input.body.trim()
  if (!title) throw new Error('Le titre est obligatoire.')
  if (title.length > YUZTOO_NEWS_TITLE_MAX) {
    throw new Error(`Titre trop long (max ${YUZTOO_NEWS_TITLE_MAX}).`)
  }
  if (!body) throw new Error('Le texte est obligatoire.')
  if (body.length > YUZTOO_NEWS_BODY_MAX) {
    throw new Error(`Texte trop long (max ${YUZTOO_NEWS_BODY_MAX}).`)
  }
  const publishOn = input.publish_on.trim()
  if (!publishOn || Number.isNaN(new Date(publishOn).getTime())) {
    throw new Error('Date de publication invalide.')
  }

  const imageUrl = emptyToNull(input.image_url)
  if (imageUrl && !/^https?:\/\//i.test(imageUrl)) {
    throw new Error('image_url doit être une URL http(s).')
  }

  const ctaUrl = emptyToNull(input.cta_url)
  if (ctaUrl && !/^https?:\/\//i.test(ctaUrl)) {
    throw new Error('cta_url doit être une URL http(s).')
  }

  const ctaLabel = emptyToNull(input.cta_label)
  if (ctaLabel && ctaLabel.length > YUZTOO_NEWS_CTA_LABEL_MAX) {
    throw new Error(`Libellé CTA trop long (max ${YUZTOO_NEWS_CTA_LABEL_MAX}).`)
  }

  return {
    ...input,
    title,
    body,
    publish_on: new Date(publishOn).toISOString(),
    active: input.active !== false,
    image_url: imageUrl,
    cta_label: ctaLabel,
    cta_url: ctaUrl,
    cta_merchant_id: emptyToNull(input.cta_merchant_id),
  }
}

function asIso(raw: unknown): string | null {
  if (typeof raw === 'string' && raw.trim()) {
    const d = new Date(raw)
    return Number.isNaN(d.getTime()) ? null : d.toISOString()
  }
  return null
}

function mapNews(raw: Record<string, unknown>): YuztooNews {
  const id = typeof raw.id === 'string' ? raw.id : ''
  const title = typeof raw.title === 'string' ? raw.title : ''
  const body = typeof raw.body === 'string' ? raw.body : ''
  const publishOn =
    asIso(raw.publish_on) ?? new Date(0).toISOString()
  return {
    id,
    title,
    body,
    publish_on: publishOn,
    active: raw.active !== false,
    image_url: emptyToNull(
      typeof raw.image_url === 'string' ? raw.image_url : null,
    ),
    cta_label: emptyToNull(
      typeof raw.cta_label === 'string' ? raw.cta_label : null,
    ),
    cta_url: emptyToNull(typeof raw.cta_url === 'string' ? raw.cta_url : null),
    cta_merchant_id: emptyToNull(
      typeof raw.cta_merchant_id === 'string' ? raw.cta_merchant_id : null,
    ),
    release_status: normalizeReleaseStatus(
      typeof raw.release_status === 'string' ? raw.release_status : null,
    ),
    test_account_id: emptyToNull(
      typeof raw.test_account_id === 'string' ? raw.test_account_id : null,
    ),
    test_account_label: emptyToNull(
      typeof raw.test_account_label === 'string'
        ? raw.test_account_label
        : null,
    ),
    preview_activated_at: asIso(raw.preview_activated_at),
    live_at: asIso(raw.live_at),
    created_at: asIso(raw.created_at) ?? undefined,
    updated_at: asIso(raw.updated_at) ?? undefined,
  }
}

async function callNewsBridge<T>(
  action: string,
  body: Record<string, unknown> = {},
): Promise<Result<T>> {
  const { data, error } = await callEdgeFunction<T>('cms-yuztoo-news', {
    action,
    ...body,
  })
  if (error) return { data: null, error }
  return { data: data as T, error: null }
}

function findOrThrow(id: string): { items: YuztooNews[]; index: number } {
  const items = loadYuztooNews()
  const index = items.findIndex((n) => n.id === id)
  if (index < 0) throw new Error('Actu introuvable.')
  return { items, index }
}

/** Reuses Images test-account candidates (clients + boutiques). */
export async function listActuTestAccounts(
  search = '',
): Promise<Result<MediaTestAccount[]>> {
  return listMediaTestAccounts(search)
}

/** Shaped like `adminListYuztooNews` / bridge `list`. */
export async function listYuztooNews(opts?: {
  limit?: number
  includeInactive?: boolean
  search?: string
}): Promise<Result<{ items: YuztooNews[] }>> {
  if (useMock()) {
    try {
      const limit = Math.min(Math.max(opts?.limit ?? 50, 1), 100)
      const includeInactive = opts?.includeInactive === true
      const needle = (opts?.search ?? '').trim().toLowerCase()
      let items = loadYuztooNews()
      if (!includeInactive) items = items.filter((n) => n.active)
      if (needle) {
        items = items.filter((n) => {
          const hay = `${n.title} ${n.body} ${n.id}`.toLowerCase()
          return hay.includes(needle)
        })
      }
      items = [...items].sort(
        (a, b) =>
          new Date(b.publish_on).getTime() - new Date(a.publish_on).getTime(),
      )
      return { data: { items: items.slice(0, limit) }, error: null }
    } catch (error) {
      return { data: null, error: error as Error }
    }
  }

  const { data, error } = await callNewsBridge<{
    items?: Record<string, unknown>[]
  }>('list', {
    limit: opts?.limit ?? 50,
    includeInactive: opts?.includeInactive !== false,
  })
  if (error || !data) return { data: null, error: error ?? new Error('Erreur') }

  let items = (data.items ?? []).map((row) => mapNews(row))
  const needle = (opts?.search ?? '').trim().toLowerCase()
  if (needle) {
    items = items.filter((n) => {
      const hay = `${n.title} ${n.body} ${n.id}`.toLowerCase()
      return hay.includes(needle)
    })
  }
  return { data: { items }, error: null }
}

/**
 * Create / update content. New items always start as **draft**.
 * Content edits while live demote to draft (must re-preview).
 */
export async function upsertYuztooNews(
  input: YuztooNewsInput,
): Promise<Result<YuztooNews>> {
  try {
    const valid = validateInput(input)
    if (useMock()) {
      const items = loadYuztooNews()
      const existingId =
        typeof valid.id === 'string' && valid.id.trim() ? valid.id.trim() : null
      const now = nowIso()
      if (existingId) {
        const index = items.findIndex((n) => n.id === existingId)
        if (index < 0) throw new Error('Actu introuvable.')
        const prev = items[index]
        const wasLive = prev.release_status === 'live'
        const next: YuztooNews = {
          ...prev,
          title: valid.title,
          body: valid.body,
          publish_on: valid.publish_on,
          active: valid.active,
          image_url: valid.image_url ?? null,
          cta_label: valid.cta_label ?? null,
          cta_url: valid.cta_url ?? null,
          cta_merchant_id: valid.cta_merchant_id ?? null,
          release_status: wasLive ? 'draft' : prev.release_status,
          preview_activated_at: wasLive ? null : prev.preview_activated_at,
          live_at: wasLive ? null : prev.live_at,
          updated_at: now,
        }
        items[index] = next
        saveYuztooNews(items)
        return { data: next, error: null }
      }
      const created: YuztooNews = {
        id: newId(),
        title: valid.title,
        body: valid.body,
        publish_on: valid.publish_on,
        active: valid.active,
        image_url: valid.image_url ?? null,
        cta_label: valid.cta_label ?? null,
        cta_url: valid.cta_url ?? null,
        cta_merchant_id: valid.cta_merchant_id ?? null,
        release_status: 'draft',
        test_account_id: null,
        test_account_label: null,
        preview_activated_at: null,
        live_at: null,
        created_at: now,
        updated_at: now,
      }
      items.unshift(created)
      saveYuztooNews(items)
      return { data: created, error: null }
    }

    const { data, error } = await callNewsBridge<Record<string, unknown>>(
      'upsert',
      {
        id: valid.id ?? null,
        title: valid.title,
        body: valid.body,
        publish_on: valid.publish_on,
        active: valid.active,
        image_url: valid.image_url,
        cta_label: valid.cta_label,
        cta_url: valid.cta_url,
        cta_merchant_id: valid.cta_merchant_id,
      },
    )
    if (error || !data) {
      return { data: null, error: error ?? new Error('Erreur') }
    }
    return { data: mapNews(data), error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function setYuztooNewsTestAccount(
  id: string,
  account: MediaTestAccount | null,
): Promise<Result<YuztooNews>> {
  if (useMock()) {
    try {
      const { items, index } = findOrThrow(id)
      const prev = items[index]
      if (prev.release_status === 'live') {
        throw new Error(
          'Impossible de changer le compte test pendant que l’actu est en ligne. Repassez en brouillon.',
        )
      }
      const next: YuztooNews = {
        ...prev,
        test_account_id: account?.id ?? null,
        test_account_label: account
          ? `${account.displayName} (${account.kind === 'client' ? 'client' : 'boutique'})`
          : null,
        release_status:
          prev.release_status === 'preview' ? 'draft' : prev.release_status,
        preview_activated_at:
          prev.release_status === 'preview' ? null : prev.preview_activated_at,
        updated_at: nowIso(),
      }
      items[index] = next
      saveYuztooNews(items)
      return { data: next, error: null }
    } catch (error) {
      return { data: null, error: error as Error }
    }
  }

  // Selecting a test account while draft/preview: setRelease draft with account
  // fields, or preview if already previewing — store via setRelease draft.
  const { data, error } = await callNewsBridge<Record<string, unknown>>(
    'setRelease',
    {
      id,
      release_status: 'draft',
      test_account_id: account?.id ?? null,
      test_account_label: account
        ? `${account.displayName} (${account.kind === 'client' ? 'client' : 'boutique'})`
        : null,
    },
  )
  if (error || !data) {
    return { data: null, error: error ?? new Error('Erreur') }
  }
  return { data: mapNews(data), error: null }
}

export async function activateYuztooNewsPreview(
  id: string,
): Promise<Result<YuztooNews>> {
  if (useMock()) {
    try {
      const { items, index } = findOrThrow(id)
      const prev = items[index]
      if (!canActivateNewsPreview(prev)) {
        throw new Error('Sélectionnez un compte test avant d’activer l’aperçu.')
      }
      if (prev.release_status === 'live') {
        throw new Error(
          'L’actu est déjà en ligne. Repassez en brouillon pour un nouvel aperçu.',
        )
      }
      const next: YuztooNews = {
        ...prev,
        release_status: 'preview',
        preview_activated_at: nowIso(),
        live_at: null,
        active: true,
        updated_at: nowIso(),
      }
      items[index] = next
      saveYuztooNews(items)
      return { data: next, error: null }
    } catch (error) {
      return { data: null, error: error as Error }
    }
  }

  const { data, error } = await callNewsBridge<Record<string, unknown>>(
    'setRelease',
    { id, release_status: 'preview' },
  )
  if (error || !data) {
    return { data: null, error: error ?? new Error('Erreur') }
  }
  return { data: mapNews(data), error: null }
}

export async function publishYuztooNewsLive(
  id: string,
): Promise<Result<YuztooNews>> {
  if (useMock()) {
    try {
      const { items, index } = findOrThrow(id)
      const prev = items[index]
      if (!canPublishNewsLive(prev)) {
        throw new Error(
          'Publication bloquée : activez d’abord l’aperçu sur un compte test.',
        )
      }
      const next: YuztooNews = {
        ...prev,
        release_status: 'live',
        live_at: nowIso(),
        active: true,
        updated_at: nowIso(),
      }
      items[index] = next
      saveYuztooNews(items)
      return { data: next, error: null }
    } catch (error) {
      return { data: null, error: error as Error }
    }
  }

  const { data, error } = await callNewsBridge<Record<string, unknown>>(
    'setRelease',
    { id, release_status: 'live' },
  )
  if (error || !data) {
    return { data: null, error: error ?? new Error('Erreur') }
  }
  return { data: mapNews(data), error: null }
}

export async function revertYuztooNewsToDraft(
  id: string,
): Promise<Result<YuztooNews>> {
  if (useMock()) {
    try {
      const { items, index } = findOrThrow(id)
      const prev = items[index]
      const next: YuztooNews = {
        ...prev,
        release_status: 'draft',
        preview_activated_at: null,
        live_at: null,
        updated_at: nowIso(),
      }
      items[index] = next
      saveYuztooNews(items)
      return { data: next, error: null }
    } catch (error) {
      return { data: null, error: error as Error }
    }
  }

  const { data, error } = await callNewsBridge<Record<string, unknown>>(
    'setRelease',
    { id, release_status: 'draft' },
  )
  if (error || !data) {
    return { data: null, error: error ?? new Error('Erreur') }
  }
  return { data: mapNews(data), error: null }
}

export async function setYuztooNewsActive(
  id: string,
  active: boolean,
): Promise<Result<YuztooNews>> {
  if (useMock()) {
    try {
      const { items, index } = findOrThrow(id)
      const next: YuztooNews = {
        ...items[index],
        active,
        updated_at: nowIso(),
      }
      items[index] = next
      saveYuztooNews(items)
      return { data: next, error: null }
    } catch (error) {
      return { data: null, error: error as Error }
    }
  }

  const { data, error } = await callNewsBridge<Record<string, unknown>>(
    'setActive',
    { id, active },
  )
  if (error || !data) {
    return { data: null, error: error ?? new Error('Erreur') }
  }
  return { data: mapNews(data), error: null }
}

export async function deleteYuztooNews(
  id: string,
): Promise<Result<{ id: string }>> {
  if (useMock()) {
    try {
      const items = loadYuztooNews()
      const next = items.filter((n) => n.id !== id)
      if (next.length === items.length) throw new Error('Actu introuvable.')
      saveYuztooNews(next)
      return { data: { id }, error: null }
    } catch (error) {
      return { data: null, error: error as Error }
    }
  }

  const { data, error } = await callNewsBridge<{ id: string; deleted: boolean }>(
    'delete',
    { id },
  )
  if (error || !data) {
    return { data: null, error: error ?? new Error('Erreur') }
  }
  return { data: { id: data.id }, error: null }
}
