import type { ClientStatus, CmsClient, CmsPage } from '@/features/cms-app/domain/cms'
import { CMS_PAGE_SIZE } from '@/features/cms-app/domain/cms'
import { mockClients } from '@/features/cms-app/services/cmsData'

type Result<T> = { data: T | null; error: Error | null }

export type ClientQuery = {
  search?: string
  status?: ClientStatus | 'all'
  page?: number
  pageSize?: number
}

function matches(client: CmsClient, search: string): boolean {
  const hay = `${client.displayName} ${client.email ?? ''} ${client.phone ?? ''} ${client.city} ${client.id}`.toLowerCase()
  return hay.includes(search)
}

/** Mirrors `adminListUsers`. */
export async function listClients(
  query: ClientQuery = {},
): Promise<Result<CmsPage<CmsClient>>> {
  try {
    const {
      search = '',
      status = 'all',
      page: rawPage = 1,
      pageSize: rawSize = CMS_PAGE_SIZE,
    } = query
    const pageSize = Math.min(100, Math.max(1, rawSize))
    const needle = search.trim().toLowerCase()

    const filtered = mockClients
      .filter((c) => (status === 'all' ? true : c.status === status))
      .filter((c) => (needle ? matches(c, needle) : true))
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))

    const total = filtered.length
    const totalPages = Math.max(1, Math.ceil(total / pageSize))
    const page = Math.min(Math.max(1, rawPage), totalPages)
    const start = (page - 1) * pageSize

    return {
      data: {
        items: filtered.slice(start, start + pageSize).map((c) => ({ ...c })),
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

export type ClientPatch = Partial<
  Pick<CmsClient, 'displayName' | 'city' | 'email' | 'phone'>
>

export async function updateClient(
  id: string,
  patch: ClientPatch,
): Promise<Result<CmsClient>> {
  try {
    const client = mockClients.find((c) => c.id === id)
    if (!client) throw new Error('Client introuvable')
    if (patch.displayName !== undefined && patch.displayName.trim() === '') {
      throw new Error('Le nom est obligatoire')
    }
    Object.assign(client, {
      ...patch,
      displayName: patch.displayName?.trim() ?? client.displayName,
      city: patch.city?.trim() ?? client.city,
      email: patch.email === undefined ? client.email : patch.email?.trim() || null,
      phone: patch.phone === undefined ? client.phone : patch.phone?.trim() || null,
    })
    return { data: { ...client }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function setClientStatus(
  id: string,
  status: ClientStatus,
): Promise<Result<CmsClient>> {
  try {
    const client = mockClients.find((c) => c.id === id)
    if (!client) throw new Error('Client introuvable')
    client.status = status
    return { data: { ...client }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
