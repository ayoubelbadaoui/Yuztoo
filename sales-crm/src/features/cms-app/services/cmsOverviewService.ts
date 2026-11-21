import type { CmsOverview } from '@/features/cms-app/domain/cms'
import { mockClients, mockMerchants } from '@/features/cms-app/services/cmsData'

type Result<T> = { data: T | null; error: Error | null }

/**
 * Mirrors `adminGetOverview`. Later: Edge → Firebase callable.
 */
export async function getCmsOverview(): Promise<Result<CmsOverview>> {
  try {
    return {
      data: {
        merchantsTotal: mockMerchants.filter((m) => m.status !== 'deleted')
          .length,
        merchantsPublished: mockMerchants.filter((m) => m.status === 'published')
          .length,
        merchantsDeleted: mockMerchants.filter((m) => m.status === 'deleted')
          .length,
        clientsTotal: mockClients.filter((c) => c.status !== 'deleted').length,
        clientsBlocked: mockClients.filter((c) => c.status === 'blocked')
          .length,
        clientsDeleted: mockClients.filter((c) => c.status === 'deleted')
          .length,
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
