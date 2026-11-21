import { useState } from 'react'

import { CmsAppShell } from '@/features/cms-app/containers/CmsAppShell'
import { ClientsPage } from '@/features/cms-app/containers/ClientsPage'
import { CmsDashboardPage } from '@/features/cms-app/containers/CmsDashboardPage'
import { CmsImagesPage } from '@/features/cms-app/containers/CmsImagesPage'
import { MerchantsPage } from '@/features/cms-app/containers/MerchantsPage'
import type { CmsViewId } from '@/features/cms-app/domain/cms'

export function CmsApp() {
  const [activeId, setActiveId] = useState<CmsViewId>('dashboard')

  return (
    <CmsAppShell activeId={activeId} onSelect={setActiveId}>
      {activeId === 'dashboard' ? (
        <CmsDashboardPage />
      ) : activeId === 'stores' ? (
        <MerchantsPage />
      ) : activeId === 'clients' ? (
        <ClientsPage />
      ) : (
        <CmsImagesPage />
      )}
    </CmsAppShell>
  )
}
