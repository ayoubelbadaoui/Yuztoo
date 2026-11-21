import type {
  CmsMerchant,
  CmsPage,
  MerchantStatus,
} from '@/features/cms-app/domain/cms'
import { CMS_PAGE_SIZE } from '@/features/cms-app/domain/cms'
import { mockMerchants } from '@/features/cms-app/services/cmsData'

type Result<T> = { data: T | null; error: Error | null }

export type MerchantQuery = {
  search?: string
  status?: MerchantStatus | 'all'
  page?: number
  pageSize?: number
}

function matches(merchant: CmsMerchant, search: string): boolean {
  const hay = `${merchant.displayName} ${merchant.city} ${merchant.email ?? ''} ${merchant.phone ?? ''} ${merchant.id}`.toLowerCase()
  return hay.includes(search)
}

/** Mirrors `adminListMerchants` — paginated. */
export async function listMerchants(
  query: MerchantQuery = {},
): Promise<Result<CmsPage<CmsMerchant>>> {
  try {
    const {
      search = '',
      status = 'all',
      page: rawPage = 1,
      pageSize: rawSize = CMS_PAGE_SIZE,
    } = query
    const pageSize = Math.min(100, Math.max(1, rawSize))
    const needle = search.trim().toLowerCase()

    const filtered = mockMerchants
      .filter((m) => (status === 'all' ? true : m.status === status))
      .filter((m) => (needle ? matches(m, needle) : true))
      .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))

    const total = filtered.length
    const totalPages = Math.max(1, Math.ceil(total / pageSize))
    const page = Math.min(Math.max(1, rawPage), totalPages)
    const start = (page - 1) * pageSize

    return {
      data: {
        items: filtered.slice(start, start + pageSize).map((m) => ({ ...m })),
        total,
        page,
        pageSize,
        totalPages,
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export type MerchantPatch = Partial<
  Pick<CmsMerchant, 'displayName' | 'city' | 'email' | 'phone'>
>

export async function updateMerchant(
  id: string,
  patch: MerchantPatch,
): Promise<Result<CmsMerchant>> {
  try {
    const merchant = mockMerchants.find((m) => m.id === id)
    if (!merchant) throw new Error('Boutique introuvable')
    if (patch.displayName !== undefined && patch.displayName.trim() === '') {
      throw new Error('Le nom est obligatoire')
    }
    Object.assign(merchant, {
      ...patch,
      displayName: patch.displayName?.trim() ?? merchant.displayName,
      city: patch.city?.trim() ?? merchant.city,
      email: patch.email === undefined ? merchant.email : patch.email?.trim() || null,
      phone: patch.phone === undefined ? merchant.phone : patch.phone?.trim() || null,
      updatedAt: new Date().toISOString(),
    })
    return { data: { ...merchant }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/** Mirrors `adminSetMerchantStatus` / soft delete / restore. */
export async function setMerchantStatus(
  id: string,
  status: MerchantStatus,
): Promise<Result<CmsMerchant>> {
  try {
    const merchant = mockMerchants.find((m) => m.id === id)
    if (!merchant) throw new Error('Boutique introuvable')
    merchant.status = status
    merchant.updatedAt = new Date().toISOString()
    return { data: { ...merchant }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
