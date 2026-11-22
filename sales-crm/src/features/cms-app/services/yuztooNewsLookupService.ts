import type {
  NewsMerchantOption,
  NewsTestClient,
} from '@/features/cms-app/domain/yuztooNews'
import { mockClients, mockMerchants } from '@/features/cms-app/services/cmsData'
import { callEdgeFunction } from '@/lib/callEdgeFunction'

type Result<T> = { data: T | null; error: Error | null }

/** Offline UI only — default is live Edge → Firebase. */
function isMockMode(): boolean {
  return import.meta.env.VITE_CMS_ACTU_MOCK === '1'
}

function maskEmail(email: string | null): string | null {
  if (!email) return null
  const at = email.indexOf('@')
  if (at <= 0) return null
  return `${email.slice(0, Math.min(2, at))}***${email.slice(at)}`
}

/**
 * Finds ONE real Yuztoo client for the test preview. Firestore has no name
 * search, so the bridge matches exact email, phone or uid only.
 */
export async function findActuTestClient(
  search: string,
): Promise<Result<NewsTestClient[]>> {
  const needle = search.trim()
  if (needle.length < 3) return { data: [], error: null }

  if (isMockMode()) {
    const lower = needle.toLowerCase()
    const items = mockClients
      .filter((c) => c.status === 'active')
      .filter(
        (c) =>
          c.id === needle ||
          c.email?.toLowerCase() === lower ||
          c.phone?.replace(/\s+/g, '') === needle.replace(/\s+/g, ''),
      )
      .map((c) => ({
        id: c.id,
        displayName: c.displayName,
        contactHint: maskEmail(c.email),
        city: c.city,
      }))
    return { data: items, error: null }
  }

  const { data, error } = await callEdgeFunction<{ items?: NewsTestClient[] }>(
    'cms-yuztoo-news',
    { action: 'findClient', search: needle },
  )
  if (error) return { data: null, error }
  return { data: data?.items ?? [], error: null }
}

/** Shop name prefix search ("boul" → "Boulangerie…"), or one shop by id. */
export async function searchActuMerchants(query: {
  search?: string
  id?: string
}): Promise<Result<NewsMerchantOption[]>> {
  const needle = query.search?.trim() ?? ''
  if (!query.id && needle.length < 2) return { data: [], error: null }

  if (isMockMode()) {
    const lower = needle.toLowerCase()
    const items = mockMerchants
      .filter((m) => m.status !== 'deleted')
      .filter((m) =>
        query.id
          ? m.id === query.id
          : m.displayName.toLowerCase().startsWith(lower),
      )
      .slice(0, 10)
      .map((m) => ({
        id: m.id,
        name: m.displayName,
        city: m.city,
        logoUrl: null,
        status: m.status,
      }))
    return { data: items, error: null }
  }

  const { data, error } = await callEdgeFunction<{
    items?: NewsMerchantOption[]
  }>('cms-yuztoo-news', {
    action: 'searchMerchants',
    ...(query.id ? { id: query.id } : { search: needle }),
  })
  if (error) return { data: null, error }
  return { data: data?.items ?? [], error: null }
}
