export const CMS_PARAM = 'cms'
export const CMS_PAGE_SIZE = 25
export const CMS_PAGE_SIZE_OPTIONS = [25, 50, 100] as const

export type CmsViewId =
  | 'dashboard'
  | 'stores'
  | 'clients'
  | 'images'
  | 'actu'

export type MerchantStatus = 'draft' | 'published' | 'unpublished' | 'deleted'

export type ClientStatus = 'active' | 'blocked' | 'deleted'

export type CmsMerchant = {
  id: string
  displayName: string
  city: string
  email: string | null
  phone: string | null
  status: MerchantStatus
  updatedAt: string
  salesCrmLeadId: string | null
}

export type CmsClient = {
  id: string
  displayName: string
  email: string | null
  phone: string | null
  city: string
  status: ClientStatus
  createdAt: string
  salesCrmLeadId: string | null
}

export type CmsOverview = {
  merchantsTotal: number
  merchantsPublished: number
  merchantsDeleted: number
  clientsTotal: number
  clientsBlocked: number
  clientsDeleted: number
}

export const merchantStatusLabels: Record<MerchantStatus, string> = {
  draft: 'Brouillon',
  published: 'Publiée',
  unpublished: 'Hors ligne',
  deleted: 'Supprimée',
}

export const clientStatusLabels: Record<ClientStatus, string> = {
  active: 'Actif',
  blocked: 'Bloqué',
  deleted: 'Supprimé',
}

export type CmsPage<T> = {
  items: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

export function openCmsAppWindow(): void {
  const url = new URL(window.location.href)
  url.search = ''
  url.searchParams.set(CMS_PARAM, '1')
  window.open(url.toString(), '_blank', 'noopener,noreferrer')
}
