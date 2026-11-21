import { useEffect, useState } from 'react'

import { findNavItem } from '@/app/navigation'
import { AppShell } from '@/components/layout/AppShell'
import { PlaceholderPage } from '@/components/layout/PlaceholderPage'
import { LoginPage } from '@/features/auth/containers/LoginPage'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { DunningPage } from '@/features/billing/containers/DunningPage'
import { PaymentSchedulePage } from '@/features/billing/containers/PaymentSchedulePage'
import { SubscriptionsPage } from '@/features/billing/containers/SubscriptionsPage'
import { CalendarPage } from '@/features/calendar/containers/CalendarPage'
import { CmsApp } from '@/features/cms-app/containers/CmsApp'
import { CMS_PARAM } from '@/features/cms-app/domain/cms'
import { ContractsPage } from '@/features/contracts/containers/ContractsPage'
import { PublicContractPage } from '@/features/contracts/containers/PublicContractPage'
import { CONTRACT_PARAM } from '@/features/contracts/domain/signature'
import { DashboardPage } from '@/features/dashboard/containers/DashboardPage'
import { InboxPage } from '@/features/inbox/containers/InboxPage'
import { getMessageCounts } from '@/features/inbox/services/inboxService'
import { LeadsPage } from '@/features/leads/containers/LeadsPage'
import { ChannelsPage } from '@/features/marketing/containers/ChannelsPage'
import { ContentCalendarPage } from '@/features/marketing/containers/ContentCalendarPage'
import { MetaOAuthPage } from '@/features/marketing/containers/MetaOAuthPage'
import { PublicationsPage } from '@/features/marketing/containers/PublicationsPage'
import type { LeadSegment } from '@/features/leads/hooks/useLeadsTable'
import { PipelinePage } from '@/features/pipeline/containers/PipelinePage'
import { PublicQuotePage } from '@/features/quotes/containers/PublicQuotePage'
import { QuotesPage } from '@/features/quotes/containers/QuotesPage'
import { SocialInboxPage } from '@/features/social/containers/SocialInboxPage'
import { WhatsappPage } from '@/features/whatsapp/containers/WhatsappPage'
import { WhatsappTemplatesPage } from '@/features/whatsapp/containers/WhatsappTemplatesPage'
import { SHARE_PARAM } from '@/features/quotes/domain/share'

const leadSegments: Record<string, LeadSegment> = {
  leads: 'all',
  'leads-all': 'all',
  'leads-merchants': 'merchant',
  'leads-clients': 'client',
}

const descriptions: Record<string, string> = {
  settings: 'Étapes, sources, catalogue, équipe — à construire.',
}

function pageFromUrl(): string {
  const raw = new URLSearchParams(window.location.search).get('page')
  return raw && findNavItem(raw) ? raw : 'dashboard'
}

export default function App() {
  const [activeId, setActiveId] = useState(pageFromUrl)
  const [unread, setUnread] = useState(0)
  const {
    session,
    isLoading,
    error,
    setError,
    login,
    register,
    logout,
    switchWorkspace,
    isAuthenticated,
  } = useAuth()

  useEffect(() => {
    if (!isAuthenticated) return
    void getMessageCounts().then(({ data }) => setUnread(data?.new ?? 0))
  }, [activeId, isAuthenticated])

  useEffect(() => {
    const url = new URL(window.location.href)
    if (activeId === 'dashboard') url.searchParams.delete('page')
    else url.searchParams.set('page', activeId)
    window.history.replaceState({}, '', url)
  }, [activeId])

  const params = new URLSearchParams(window.location.search)
  const shareToken = params.get(SHARE_PARAM)
  if (shareToken) return <PublicQuotePage token={shareToken} />

  const signingToken = params.get(CONTRACT_PARAM)
  if (signingToken) return <PublicContractPage token={signingToken} />

  if (window.location.pathname === '/meta-oauth') {
    return <MetaOAuthPage />
  }

  const cmsMode = params.get(CMS_PARAM) === '1'

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-[13px] text-muted-foreground">
        Chargement de la session…
      </div>
    )
  }

  if (!isAuthenticated) {
    return (
      <LoginPage
        error={error}
        onClearError={() => setError(null)}
        onLogin={login}
        onRegister={register}
      />
    )
  }

  if (cmsMode) return <CmsApp />

  const activeMembership =
    session?.memberships.find(
      (m) => m.workspaceId === session.activeWorkspaceId,
    ) ?? session?.memberships[0]

  const handleSelect = (id: string) => {
    if (id === 'logout') {
      void logout()
      return
    }
    setActiveId(id)
  }

  const handleWorkspaceSelect = (name: string) => {
    const match = session?.memberships.find((m) => m.workspaceName === name)
    if (match) void switchWorkspace(match.workspaceId)
  }

  const segment = leadSegments[activeId]
  const title = findNavItem(activeId)?.title ?? 'Tableau de bord'
  const description =
    descriptions[activeId] ?? 'Écran de référence du shell Sales CRM.'

  return (
    <AppShell
      activeId={activeId}
      onSelect={handleSelect}
      badges={{ inbox: unread }}
      workspace={activeMembership?.workspaceName ?? 'Yuztoo Sales'}
      workspaces={session?.memberships.map((m) => m.workspaceName) ?? []}
      onWorkspaceSelect={handleWorkspaceSelect}
    >
      {activeId === 'dashboard' ? (
        <DashboardPage />
      ) : activeId === 'inbox' ? (
        <InboxPage />
      ) : activeId === 'pipeline' ? (
        <PipelinePage />
      ) : activeId === 'calendar' ? (
        <CalendarPage />
      ) : activeId === 'quotes' ? (
        <QuotesPage />
      ) : activeId === 'contracts' ? (
        <ContractsPage />
      ) : activeId === 'subscriptions' ? (
        <SubscriptionsPage />
      ) : activeId === 'dunning' ? (
        <DunningPage />
      ) : activeId === 'schedule' ? (
        <PaymentSchedulePage />
      ) : activeId === 'publications' ? (
        <PublicationsPage />
      ) : activeId === 'content-calendar' ? (
        <ContentCalendarPage />
      ) : activeId === 'channels' ? (
        <ChannelsPage />
      ) : activeId === 'social-inbox' ? (
        <SocialInboxPage />
      ) : activeId === 'whatsapp' ? (
        <WhatsappPage />
      ) : activeId === 'whatsapp-templates' ? (
        <WhatsappTemplatesPage />
      ) : segment ? (
        <LeadsPage key={activeId} initialSegment={segment} />
      ) : (
        <PlaceholderPage title={title} description={description} />
      )}
    </AppShell>
  )
}
